# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # Create OneLake Shortcuts + Target Views — Source Warehouse → Target Lakehouse → Target Warehouse (Cross-Workspace)
# 
# Two independently toggleable stages:
# 
# **Stage A — Shortcuts** (`CREATE_SHORTCUTS`). Creates OneLake **shortcuts** in a **target
# Lakehouse** that point to specific tables in a **source Fabric Warehouse** in a *different*
# workspace. Zero-copy: the warehouse tables appear live (read-only) in the target workspace.
# 
# **Stage B — Views** (`CREATE_TARGET_VIEWS`). Creates `CREATE OR ALTER VIEW` objects in a
# **target Warehouse** (same workspace as the target Lakehouse) that `SELECT` from the shortcut
# tables via 3-part naming.
# 
# ### Run modes (set the two toggles)
# | `CREATE_SHORTCUTS` | `CREATE_TARGET_VIEWS` | Result |
# |--------------------|-----------------------|--------|
# | `True` | `True` | Shortcuts **and** views (full pipeline) |
# | `True` | `False` | Shortcuts only |
# | `False` | `True` | **Views only** — assumes the shortcuts already exist in the target Lakehouse |
# | `False` | `False` | Nothing to do (error) |
# 
# ### Parameters
# | Parameter | Meaning |
# |-----------|---------|
# | `TABLES` | **Required.** Comma-separated table list. Unqualified names use `SOURCE_SCHEMA`; qualify with `schema.table` to override. |
# | `SOURCE_WORKSPACE` / `SOURCE_WAREHOUSE` | Source workspace (name/GUID) + Warehouse name. Required only when `CREATE_SHORTCUTS = True`. |
# | `TARGET_WORKSPACE` | Target workspace **name or GUID** (contains the target Lakehouse + Warehouse). |
# | `TARGET_LAKEHOUSE` | Target **Lakehouse** name (shortcut location + view source). |
# | `TARGET_WAREHOUSE` | Target **Warehouse** name (where views are created). Required when `CREATE_TARGET_VIEWS = True`. |
# 
# ### Notes
# - Warehouse tables are schema-organized in OneLake (`Tables/dbo/<table>`).
# - Shortcuts are **read-only** symbolic links — no data is copied.
# - Stage B uses the verified Fabric Warehouse pyodbc pattern (token via `notebookutils`, ODBC
#   Driver 18, no password). Target Lakehouse + Warehouse must be in the **same workspace** for
#   3-part view references to resolve.


# PARAMETERS CELL ********************

# --- Configuration (parameters) ---
# This cell is tagged "parameters" so a Fabric pipeline can override these values.

TABLES            = "tbl_DIM_Date,tbl_DIM_Date_ORIG"
#TABLES            = "mtbl_EDW_RouteType,ARTIKEL,Cust_TDSGyroDet,KLANTEN,legacy_tbl_DIM_CPC,legacy_tbl_DIM_Product,legacy_tbl_DIM_Product_Other,legacy_tbl_DIM_Salesman_Heirarchy,legacy_tbl_Dim_StandardCost,legacy_tbl_Fact_Sales,legacy_tbl_Fact_Sales_April152026_BACKUP,legacy_tbl_RESULTSSLSBYYR,mtbl_EDW_BIDataSet_Opportunity,tbl_CPCIndustry,tbl_crm_Activity_CY,tbl_CRM_SAMPLE,tbl_custtrans,tbl_dlyorder,tbl_Fact_Call_Reports,tbl_inventory,tbl_legacy_budget_data,tbl_Mo_Dim_Date,tbl_NewProductLine2025_Temp,tbl_OFFD,tbl_OFFERTE,tbl_OPMGRFLD,tbl_Opportunity_Header,tbl_OpportunityList,tbl_Reconciliation_Adjustments,tbl_RESULTSSLSBYYR_BVBA,tbl_RESULTSSLSBYYR_BVBA_OPEN,tbl_RESULTSSLSBYYR_BVBA_Thru2025,tbl_RESULTSSLSBYYR_TEDA,tbl_RESULTSSLSBYYR_TEDA_Thru2025,tbl_SampleDashboardData,vw_crm_Activity,vw_crm_Sample_Activity,vw_OpMgr,vw_OpMgrFld,vw_OpportunityList,XREF_Customer_ID,XREF_Product_ID,XREF_Salesman_ID"    # REQUIRED: comma-separated, e.g. "custtable, salestable, dbo.inventtable"
SOURCE_WORKSPACE  = "2b09b481-244a-470e-9797-6743fd25ca05"    # source workspace NAME or GUID (contains the source Warehouse)
SOURCE_WAREHOUSE  = "WH_Curated"    # source Fabric Warehouse name
TARGET_WORKSPACE  = "45bf33a4-63af-4924-b012-8d37e8b2d795"    # target workspace NAME or GUID (contains the target Lakehouse + Warehouse)
TARGET_LAKEHOUSE  = "LH_staging_for_prod_Curated_data"    # target Lakehouse name (shortcuts are created here)

# --- Stage toggles ---
CREATE_SHORTCUTS    = False    # Stage A: create the OneLake shortcuts. Set False for views-only.
CREATE_TARGET_VIEWS = True    # Stage B: create the target Warehouse views. Set False for shortcuts-only.

# --- Stage B: target Warehouse views ---
TARGET_WAREHOUSE        = "WH_Curated"       # target Warehouse name (views created here); required if CREATE_TARGET_VIEWS
TARGET_WAREHOUSE_SERVER = ""       # optional: SQL endpoint FQDN; auto-resolved from the warehouse if left blank
VIEW_SCHEMA             = "dbo"    # schema the views are created in (target Warehouse)
VIEW_PREFIX             = ""    # view name = VIEW_PREFIX + table name

# --- Optional advanced settings ---
SOURCE_SCHEMA                = "dbo"     # default schema for unqualified names in TABLES
TARGET_LAKEHOUSE_HAS_SCHEMAS = False     # True if the target Lakehouse is schema-enabled
TARGET_SCHEMA                = "dbo"     # target Lakehouse schema (used only when TARGET_LAKEHOUSE_HAS_SCHEMAS = True)
CONFLICT_POLICY              = "CreateOrOverwrite"   # Abort | GenerateUniqueName | CreateOrOverwrite

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# --- Imports & helpers ---
import requests
import json
import logging
import re
import sys

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger()

FABRIC_API_BASE = "https://api.fabric.microsoft.com/v1"
_GUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")


def get_token():
    """Fabric REST API bearer token."""
    return notebookutils.credentials.getToken("https://api.fabric.microsoft.com/")


def fabric_get(path, token):
    """GET to Fabric REST API with continuationToken pagination. Returns the value list."""
    headers = {"Authorization": f"Bearer {token}"}
    results = []
    url = f"{FABRIC_API_BASE}{path}"
    params = {}
    while True:
        resp = requests.get(url, headers=headers, params=params)
        resp.raise_for_status()
        data = resp.json()
        results.extend(data.get("value", data.get("data", [])))
        token_next = data.get("continuationToken")
        if not token_next:
            break
        params = {"continuationToken": token_next}
    return results


def fabric_get_item(path, token):
    """GET a single Fabric REST object (no value list)."""
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{FABRIC_API_BASE}{path}", headers=headers)
    resp.raise_for_status()
    return resp.json()


def fabric_post(path, token, payload):
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    return requests.post(f"{FABRIC_API_BASE}{path}", headers=headers, data=json.dumps(payload))


def is_guid(value):
    return bool(_GUID_RE.match(value.strip()))


def resolve_workspace_id(name_or_guid, token):
    """Return a workspace GUID. Accepts a GUID (passthrough) or a workspace display name."""
    val = name_or_guid.strip()
    if is_guid(val):
        return val
    for ws in fabric_get("/workspaces", token):
        if ws.get("displayName", "").lower() == val.lower():
            return ws["id"]
    raise ValueError(f"Workspace not found by name: '{name_or_guid}'")


def resolve_item_id(workspace_id, item_name, item_type, token):
    """Resolve a Warehouse/Lakehouse name to its item ID within a workspace."""
    items = fabric_get(f"/workspaces/{workspace_id}/items?type={item_type}", token)
    for it in items:
        if it.get("displayName", "").lower() == item_name.lower():
            return it["id"]
    raise ValueError(f"{item_type} '{item_name}' not found in workspace {workspace_id}")


def resolve_warehouse_server(workspace_id, warehouse_id, token):
    """Return the SQL endpoint FQDN (connectionString) of a Fabric Warehouse."""
    data = fabric_get_item(f"/workspaces/{workspace_id}/warehouses/{warehouse_id}", token)
    return data.get("properties", {}).get("connectionString")


def parse_tables(tables_csv, default_schema):
    """Parse the CSV table list into [(schema, table), ...]. Supports 'schema.table'."""
    parsed = []
    for raw in tables_csv.split(","):
        entry = raw.strip().strip("[]")
        if not entry:
            continue
        if "." in entry:
            schema, table = entry.split(".", 1)
            parsed.append((schema.strip().strip("[]"), table.strip().strip("[]")))
        else:
            parsed.append((default_schema, entry))
    return parsed


def create_shortcut(target_ws_id, target_lh_id, source_ws_id, source_wh_id,
                    schema, table, target_path, conflict_policy, token):
    """Create a OneLake shortcut in the target Lakehouse pointing to a source Warehouse table.
    Returns 'created', 'exists', or 'error'."""
    payload = {
        "path": target_path,
        "name": table,
        "target": {
            "type": "OneLake",
            "oneLake": {
                "workspaceId": source_ws_id,
                "itemId": source_wh_id,
                "path": f"Tables/{schema}/{table}",
            },
        },
    }
    url = f"/workspaces/{target_ws_id}/items/{target_lh_id}/shortcuts"
    if conflict_policy and conflict_policy.strip() and conflict_policy.strip() != "Abort":
        url += f"?shortcutConflictPolicy={conflict_policy.strip()}"
    resp = fabric_post(url, token, payload)
    if resp.status_code in (200, 201):
        return "created"
    if resp.status_code == 409:
        return "exists"
    logger.error(f"  API error {resp.status_code}: {resp.text}")
    return "error"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ## Stage B — target Warehouse view helpers
# These functions open a pyodbc connection to the target Warehouse and emit one `CREATE OR ALTER VIEW` per table. Skipped entirely when `CREATE_TARGET_VIEWS = False`.

# CELL ********************

# --- Stage B helpers: target Warehouse view creation (pyodbc) ---
# Verified Fabric Warehouse connection pattern: notebookutils token + ODBC Driver 18,
# no password/service principal required.

def connect_warehouse(server, database):
    """Open an autocommit pyodbc connection to a Fabric Warehouse using the notebook token."""
    import pyodbc
    import struct

    token_str = notebookutils.credentials.getToken("https://database.windows.net/")
    token_bytes = bytes(token_str, "UTF-8")
    token_struct = struct.pack("=i", len(token_bytes) * 2) + b"".join(
        bytes([b, 0]) for b in token_bytes
    )
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};",
        attrs_before={1256: token_struct},
    )
    conn.autocommit = True
    return conn


def create_target_views(tables, lakehouse_name, lakehouse_sql_schema,
                        view_schema, view_prefix, conn):
    """Create CREATE OR ALTER VIEWs in the target Warehouse over the Lakehouse shortcut tables.
    `tables` is a list of (schema, table) tuples; the shortcut table name is what is exposed in
    the Lakehouse SQL endpoint. Returns dict of result lists."""
    cursor = conn.cursor()
    results = {"created": [], "error": []}
    for _src_schema, table in tables:
        view_name = f"{view_prefix}{table}"
        ddl = (
            f"CREATE OR ALTER VIEW [{view_schema}].[{view_name}] AS\n"
            f"SELECT * FROM [{lakehouse_name}].[{lakehouse_sql_schema}].[{table}];"
        )
        try:
            cursor.execute(ddl)
            results["created"].append(f"{view_schema}.{view_name}")
            logger.info(f"  [VIEW OK] {view_schema}.{view_name} -> "
                        f"[{lakehouse_name}].[{lakehouse_sql_schema}].[{table}]")
        except Exception as ex:
            results["error"].append(f"{view_schema}.{view_name}")
            logger.error(f"  [VIEW FAIL] {view_schema}.{view_name}: {ex}")
    cursor.close()
    return results

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# --- Main execution ---
def main():
    if not CREATE_SHORTCUTS and not CREATE_TARGET_VIEWS:
        raise ValueError("Nothing to do: set CREATE_SHORTCUTS and/or CREATE_TARGET_VIEWS to True.")

    # Validate required parameters (conditional on which stages run)
    required = {"TABLES": TABLES, "TARGET_WORKSPACE": TARGET_WORKSPACE, "TARGET_LAKEHOUSE": TARGET_LAKEHOUSE}
    if CREATE_SHORTCUTS:
        required["SOURCE_WORKSPACE"] = SOURCE_WORKSPACE
        required["SOURCE_WAREHOUSE"] = SOURCE_WAREHOUSE
    if CREATE_TARGET_VIEWS:
        required["TARGET_WAREHOUSE"] = TARGET_WAREHOUSE
    missing = [k for k, v in required.items() if not str(v).strip()]
    if missing:
        raise ValueError(f"Missing required parameter(s): {', '.join(missing)}")

    table_list = parse_tables(TABLES, SOURCE_SCHEMA)
    if not table_list:
        raise ValueError("TABLES did not contain any table names.")

    logger.info("Step 1: Acquiring Fabric API token...")
    token = get_token()

    logger.info("Step 2: Resolving target workspace...")
    tgt_ws_id = resolve_workspace_id(TARGET_WORKSPACE, token)
    logger.info(f"  Target workspace : {TARGET_WORKSPACE} -> {tgt_ws_id}")

    # ---------- Stage A: shortcuts ----------
    if CREATE_SHORTCUTS:
        src_ws_id = resolve_workspace_id(SOURCE_WORKSPACE, token)
        src_wh_id = resolve_item_id(src_ws_id, SOURCE_WAREHOUSE, "Warehouse", token)
        tgt_lh_id = resolve_item_id(tgt_ws_id, TARGET_LAKEHOUSE, "Lakehouse", token)
        logger.info(f"  Source workspace : {SOURCE_WORKSPACE} -> {src_ws_id}")
        logger.info(f"  Source warehouse : {SOURCE_WAREHOUSE} -> {src_wh_id}")
        logger.info(f"  Target lakehouse : {TARGET_LAKEHOUSE} -> {tgt_lh_id}")

        target_path = f"Tables/{TARGET_SCHEMA}" if TARGET_LAKEHOUSE_HAS_SCHEMAS else "Tables"

        logger.info(f"Stage A: Creating {len(table_list)} shortcut(s) in target Lakehouse...")
        sc = {"created": [], "exists": [], "error": []}
        ok_tables = []  # shortcuts that exist/created -> eligible for views
        for schema, table in table_list:
            status = create_shortcut(
                tgt_ws_id, tgt_lh_id, src_ws_id, src_wh_id,
                schema, table, target_path, CONFLICT_POLICY, token,
            )
            sc[status].append(f"{schema}.{table}")
            if status in ("created", "exists"):
                ok_tables.append((schema, table))
            if status == "created":
                logger.info(f"  [CREATED] {schema}.{table}  (source Tables/{schema}/{table})")
            elif status == "exists":
                logger.info(f"  [EXISTS ] {schema}.{table}  (skipped)")
            else:
                logger.error(f"  [FAILED ] {schema}.{table}")

        logger.info("")
        logger.info("Stage A complete.")
        logger.info(f"  Created : {len(sc['created'])}")
        logger.info(f"  Skipped : {len(sc['exists'])}")
        logger.info(f"  Failed  : {len(sc['error'])}")
        if sc["error"]:
            logger.error(f"  Failed shortcuts: {', '.join(sc['error'])}")
    else:
        # Views-only mode: assume the shortcuts already exist in the target Lakehouse.
        logger.info("Stage A skipped (CREATE_SHORTCUTS = False) - views-only mode.")
        ok_tables = table_list

    # ---------- Stage B: target Warehouse views ----------
    if not CREATE_TARGET_VIEWS:
        logger.info("Stage B skipped (CREATE_TARGET_VIEWS = False).")
        return
    if not ok_tables:
        logger.info("Stage B skipped: no tables available to build views over.")
        return

    logger.info("")
    logger.info("Stage B: Creating views in target Warehouse...")
    tgt_wh_id = resolve_item_id(tgt_ws_id, TARGET_WAREHOUSE, "Warehouse", token)
    server = TARGET_WAREHOUSE_SERVER.strip() or resolve_warehouse_server(tgt_ws_id, tgt_wh_id, token)
    if not server:
        raise ValueError("Could not resolve the target Warehouse SQL endpoint (connectionString). "
                         "Set TARGET_WAREHOUSE_SERVER manually.")
    logger.info(f"  Target warehouse : {TARGET_WAREHOUSE} -> {tgt_wh_id}")
    logger.info(f"  SQL endpoint     : {server}")

    lakehouse_sql_schema = TARGET_SCHEMA if TARGET_LAKEHOUSE_HAS_SCHEMAS else "dbo"
    conn = connect_warehouse(server, TARGET_WAREHOUSE)
    try:
        vr = create_target_views(
            ok_tables, TARGET_LAKEHOUSE, lakehouse_sql_schema,
            VIEW_SCHEMA, VIEW_PREFIX, conn,
        )
    finally:
        conn.close()

    logger.info("")
    logger.info("Stage B complete.")
    logger.info(f"  Views created : {len(vr['created'])}")
    logger.info(f"  Views failed  : {len(vr['error'])}")
    if vr["error"]:
        logger.error(f"  Failed views: {', '.join(vr['error'])}")
    if vr["created"]:
        sample = vr["created"][0]
        logger.info("")
        logger.info(f"Query a target view, e.g.:  SELECT * FROM [{sample.split('.')[0]}].[{sample.split('.')[1]}];")


main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
