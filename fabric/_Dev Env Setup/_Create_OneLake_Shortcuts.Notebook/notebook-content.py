# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # Create OneLake Shortcuts — Cross-Workspace Lakehouse
# 
# Automatically creates OneLake shortcuts in a **target Lakehouse** pointing to tables
# in a **source Lakehouse** in a different Fabric workspace.
# 
# ### How it works
# 1. Resolves source and target Lakehouse IDs from their names via the Fabric REST API
# 2. Lists all Delta tables in the source Lakehouse
# 3. Creates a OneLake shortcut in the target Lakehouse for each table
# 4. Skips tables that already have a shortcut (idempotent — safe to re-run)
# 
# ### Why shortcuts instead of 3-part names
# Fabric Warehouse views use 3-part names (`lakehouse.schema.table`) that only resolve
# within the same workspace. Shortcuts make the source Lakehouse tables appear local
# to the target workspace, so views resolve correctly across workspaces.

# CELL ********************

# --- Configuration ---
SOURCE_WORKSPACE_ID   = "45bf33a4-63af-4924-b012-8d37e8b2d795"   # GUID of the workspace containing the source Lakehouse
SOURCE_LAKEHOUSE_NAME = "dataverse_stiuat_cds2_workspace_unqb7d4a6439257f0118ee5002248282"   # Name of the source Lakehouse (e.g. 'dataverse_stiuat_cds2_workspace_...')

TARGET_WORKSPACE_ID   = "45bf33a4-63af-4924-b012-8d37e8b2d795"   # GUID of the workspace containing the target Lakehouse
TARGET_LAKEHOUSE_NAME = "dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8"   # Name of the target Lakehouse (where shortcuts will be created)

# Optional: comma-separated list of table names to include, or '*' for all tables
# Example: "custtrans,vendtrans,inventtrans"
TABLE_FILTER          = "*"

# Optional: comma-separated list of table names to exclude (applied after TABLE_FILTER)
# Example: "stagingmetadata,_eventlog,derived_table_map"
TABLE_EXCLUDE         = "bot,businessunit,incident,msdyn_copilotevent,msdyn_copilotknowledgeinteraction,msdyn_evaluation,msdyn_evaluationcategory,msdyn_evaluationcriteria,msdyn_evaluationcriteriaversion,msdyn_evaluationentityconfig,msdyn_evaluationextension,msdyn_evaluationglobalconfig,msdyn_evaluationlocalizedcontent,msdyn_evaluationplan,msdyn_evaluationplanrun,msdyn_evaluationquestion,msdyn_leadagentresult,msdyn_ocliveworkitem,organization,privilege,queue,role,roleprivileges,systemuser,systemuserroles,team,teammembership"

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
        # Collect items from 'value' or 'data' key depending on endpoint
        results.extend(data.get("value", data.get("data", [])))
        # Follow continuationToken if present — let requests handle URL encoding
        continuation = data.get("continuationToken")
        if not continuation:
            break
        extra_params = {"continuationToken": continuation}
    return results


def fabric_post(path, token, payload):
    """POST request to Fabric REST API."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    response = requests.post(
        f"{FABRIC_API_BASE}{path}",
        headers=headers,
        data=json.dumps(payload)
    )
    return response


def get_lakehouse_id(workspace_id, lakehouse_name, token):
    """Resolve a Lakehouse name to its item ID."""
    items = fabric_get(f"/workspaces/{workspace_id}/items?type=Lakehouse", token)
    for item in items:
        if item.get("displayName", "").lower() == lakehouse_name.lower():
            return item["id"]
    raise ValueError(f"Lakehouse '{lakehouse_name}' not found in workspace {workspace_id}")


def list_lakehouse_tables(workspace_id, lakehouse_id, token):
    """List all Delta tables in a Lakehouse."""
    return fabric_get(f"/workspaces/{workspace_id}/lakehouses/{lakehouse_id}/tables", token)


def create_shortcut(target_workspace_id, target_lakehouse_id,
                    source_workspace_id, source_lakehouse_id,
                    table_name, token):
    """
    Create a OneLake shortcut in the target Lakehouse pointing to a table
    in the source Lakehouse.
    Returns: 'created', 'exists', or 'error'
    """
    payload = {
        "path": "Tables",
        "name": table_name,
        "target": {
            "type": "OneLake",
            "oneLake": {
                "workspaceId": source_workspace_id,
                "itemId": source_lakehouse_id,
                "path": f"Tables/{table_name}"
            }
        }
    }
    response = fabric_post(
        f"/workspaces/{target_workspace_id}/items/{target_lakehouse_id}/shortcuts",
        token,
        payload
    )
    if response.status_code == 201:
        return "created"
    elif response.status_code == 409:
        return "exists"  # Shortcut already present — safe to skip
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

    logger.info("🔍 Step 2: Resolving Lakehouse IDs...")
    source_lh_id = get_lakehouse_id(SOURCE_WORKSPACE_ID, SOURCE_LAKEHOUSE_NAME, token)
    logger.info(f"  Source Lakehouse '{SOURCE_LAKEHOUSE_NAME}' → {source_lh_id}")

    target_lh_id = get_lakehouse_id(TARGET_WORKSPACE_ID, TARGET_LAKEHOUSE_NAME, token)
    logger.info(f"  Target Lakehouse '{TARGET_LAKEHOUSE_NAME}' → {target_lh_id}")

    logger.info("📋 Step 3: Listing tables in source Lakehouse...")
    all_tables = list_lakehouse_tables(SOURCE_WORKSPACE_ID, source_lh_id, token)

    # Apply table filter
    if TABLE_FILTER.strip() == "*":
        tables = all_tables
    else:
        filter_set = {t.strip().lower() for t in TABLE_FILTER.split(",")}
        tables = [t for t in all_tables if t["name"].lower() in filter_set]

    # Apply exclusion filter
    if TABLE_EXCLUDE.strip():
        exclude_set = {t.strip().lower() for t in TABLE_EXCLUDE.split(",")}
        tables = [t for t in tables if t["name"].lower() not in exclude_set]
        logger.info(f"  {len(tables)} tables remaining after exclusions.")

    logger.info(f"  {len(all_tables)} tables found, {len(tables)} selected for shortcut creation.")

    logger.info("🔗 Step 4: Creating OneLake shortcuts in target Lakehouse...")
    results = {"created": [], "exists": [], "error": []}

    for table in tables:
        table_name = table["name"]
        status = create_shortcut(
            TARGET_WORKSPACE_ID, target_lh_id,
            SOURCE_WORKSPACE_ID, source_lh_id,
            table_name, token
        )
        results[status].append(table_name)
        if status == "created":
            logger.info(f"  ✅ Created shortcut: {table_name}")
        elif status == "exists":
            logger.info(f"  ⏭️  Already exists, skipped: {table_name}")
        else:
            logger.error(f"  ❌ Failed: {table_name}")

    logger.info("")
    logger.info("🎉 Shortcut creation complete.")
    logger.info(f"  ✅ Created : {len(results['created'])}")
    logger.info(f"  ⏭️  Skipped : {len(results['exists'])}")
    logger.info(f"  ❌ Failed  : {len(results['error'])}")

    if results["error"]:
        logger.error(f"  Failed tables: {', '.join(results['error'])}")


main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
