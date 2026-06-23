# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # Delete OneLake Shortcuts — Cross-Workspace Lakehouse
# 
# Deletes OneLake shortcuts from a **target Lakehouse** that were previously created
# to point at tables in a source Lakehouse in a different Fabric workspace.
# 
# ### How it works
# 1. Resolves the target Lakehouse ID from its name via the Fabric REST API
# 2. Lists all existing shortcuts in the target Lakehouse at the specified path
# 3. Filters the shortcut list using TABLE_FILTER and TABLE_EXCLUDE
# 4. Deletes matching shortcuts and reports results
# 
# ### Safety
# - Only deletes shortcuts — never deletes actual tables or data
# - Idempotent: if a shortcut doesn't exist, it logs a skip rather than erroring
# - Set TABLE_FILTER to a specific list to limit scope before running

# CELL ********************

# --- Configuration ---
TARGET_WORKSPACE_ID   = "45bf33a4-63af-4924-b012-8d37e8b2d795"   # GUID of the workspace containing the Lakehouse with shortcuts
TARGET_LAKEHOUSE_NAME = "dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8"   # Name of the Lakehouse from which shortcuts will be deleted

# Path prefix where shortcuts were created — must match what was used in Create_OneLake_Shortcuts
# Examples: "Tables/dbo" (if created under dbo schema) or "Tables" (if created at root)
SHORTCUT_PATH_PREFIX  = "Tables"

# Optional: comma-separated list of shortcut names to delete, or '*' to delete all at the path
# Example: "custtrans,vendtrans,inventtrans"
TABLE_FILTER          = "*"

# Optional: comma-separated list of shortcut names to exclude from deletion
# Example: "stagingmetadata,_eventlog"
TABLE_EXCLUDE         = ""

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# --- Imports ---
import requests
import json
import logging
import sys
import urllib.parse

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger()

FABRIC_API_BASE = "https://api.fabric.microsoft.com/v1"


def get_token():
    """Get a Fabric API bearer token via notebookutils."""
    return notebookutils.credentials.getToken("https://api.fabric.microsoft.com/")


def fabric_get(path, token):
    """GET request to Fabric REST API with pagination support."""
    headers = {"Authorization": f"Bearer {token}"}
    results = []
    base_url = f"{FABRIC_API_BASE}{path}"
    extra_params = {}
    while True:
        response = requests.get(base_url, headers=headers, params=extra_params)
        response.raise_for_status()
        data = response.json()
        results.extend(data.get("value", data.get("data", [])))
        continuation = data.get("continuationToken")
        if not continuation:
            break
        extra_params = {"continuationToken": continuation}
    return results


def fabric_delete(path, token):
    """DELETE request to Fabric REST API."""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.delete(f"{FABRIC_API_BASE}{path}", headers=headers)
    return response


def get_lakehouse_id(workspace_id, lakehouse_name, token):
    """Resolve a Lakehouse name to its item ID."""
    items = fabric_get(f"/workspaces/{workspace_id}/items?type=Lakehouse", token)
    for item in items:
        if item.get("displayName", "").lower() == lakehouse_name.lower():
            return item["id"]
    raise ValueError(f"Lakehouse '{lakehouse_name}' not found in workspace {workspace_id}")


def list_shortcuts(workspace_id, lakehouse_id, path_prefix, token):
    """List all shortcuts in a Lakehouse at the specified path."""
    encoded_path = urllib.parse.quote(path_prefix, safe="")
    return fabric_get(
        f"/workspaces/{workspace_id}/items/{lakehouse_id}/shortcuts?path={encoded_path}",
        token
    )


def delete_shortcut(workspace_id, lakehouse_id, path_prefix, shortcut_name, token):
    """
    Delete a shortcut from a Lakehouse.
    Returns: 'deleted', 'not_found', or 'error'
    """
    encoded_path = urllib.parse.quote(path_prefix, safe="")
    encoded_name = urllib.parse.quote(shortcut_name, safe="")
    response = fabric_delete(
        f"/workspaces/{workspace_id}/items/{lakehouse_id}/shortcuts/{encoded_path}/{encoded_name}",
        token
    )
    if response.status_code in (200, 204):
        return "deleted"
    elif response.status_code == 404:
        return "not_found"
    else:
        logger.error(f"  API error {response.status_code}: {response.text}")
        return "error"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# --- Main Execution ---
def main():
    logger.info("🔑 Step 1: Acquiring Fabric API token...")
    token = get_token()

    logger.info("🔍 Step 2: Resolving Lakehouse ID...")
    target_lh_id = get_lakehouse_id(TARGET_WORKSPACE_ID, TARGET_LAKEHOUSE_NAME, token)
    logger.info(f"  Target Lakehouse '{TARGET_LAKEHOUSE_NAME}' → {target_lh_id}")

    logger.info(f"📋 Step 3: Listing existing shortcuts at '{SHORTCUT_PATH_PREFIX}'...")
    all_shortcuts = list_shortcuts(TARGET_WORKSPACE_ID, target_lh_id, SHORTCUT_PATH_PREFIX, token)
    logger.info(f"  {len(all_shortcuts)} shortcuts found.")

    if not all_shortcuts:
        logger.info("  Nothing to delete.")
        return

    # Apply include filter
    if TABLE_FILTER.strip() == "*":
        shortcuts = all_shortcuts
    else:
        filter_set = {t.strip().lower() for t in TABLE_FILTER.split(",")}
        shortcuts = [s for s in all_shortcuts if s["name"].lower() in filter_set]

    # Apply exclusion filter
    if TABLE_EXCLUDE.strip():
        exclude_set = {t.strip().lower() for t in TABLE_EXCLUDE.split(",")}
        shortcuts = [s for s in shortcuts if s["name"].lower() not in exclude_set]
        logger.info(f"  {len(shortcuts)} shortcuts remaining after exclusions.")

    logger.info(f"  {len(shortcuts)} shortcuts selected for deletion.")

    logger.info("🗑️ Step 4: Deleting shortcuts...")
    results = {"deleted": [], "not_found": [], "error": []}

    for shortcut in shortcuts:
        name = shortcut["name"]
        status = delete_shortcut(
            TARGET_WORKSPACE_ID, target_lh_id,
            SHORTCUT_PATH_PREFIX, name, token
        )
        results[status].append(name)
        if status == "deleted":
            logger.info(f"  ✅ Deleted: {name}")
        elif status == "not_found":
            logger.info(f"  ⏭️  Not found, skipped: {name}")
        else:
            logger.error(f"  ❌ Failed: {name}")

    logger.info("")
    logger.info("🎉 Deletion complete.")
    logger.info(f"  ✅ Deleted  : {len(results['deleted'])}")
    logger.info(f"  ⏭️  Skipped  : {len(results['not_found'])}")
    logger.info(f"  ❌ Failed   : {len(results['error'])}")

    if results["error"]:
        logger.error(f"  Failed shortcuts: {', '.join(results['error'])}")


main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
