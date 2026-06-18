# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "jupyter",
# META     "jupyter_kernel_name": "python3.11"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "70459bf8-2d31-42b6-947f-9eea8f2e6c8c",
# META       "default_lakehouse_name": "dataverse_jjunoenvfre",
# META       "default_lakehouse_workspace_id": "cca1475b-c4fe-417f-844a-f3e8a061e55d",
# META       "known_lakehouses": [
# META         {
# META           "id": "70459bf8-2d31-42b6-947f-9eea8f2e6c8c"
# META         }
# META       ]
# META     },
# META     "warehouse": {
# META       "known_warehouses": []
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Notebook does following 
# 
# - 🏗️ Step 1: Create case-insensitive Data Warehouse.
# - 🔹 Step 2: Connect to Synapse Serverless Database and get table list and schema information.
# - 🔁 Step 3: Get parent and child tables information from local file.
# - 🛠️ Step 4: Connect to Fabric Link lakehouse get table metadata and generate view ddl statements.
# - 🏃‍♂️ Step 5: Connect to Fabric case in-senstive data warehouse and create views.
# - 🚀 Step 6: Connect to Synaspe serverless virtual datawarehouse and collect views and dependencies.
# - 🚀 Step 7: Connect to Fabric datawarehouse and deploy create views


# CELL ********************

# --- Configuration Constants ---
LH_WORKSPACE_ID     = "2b09b481-244a-470e-9797-6743fd25ca05"  # workspace containing the Fabric Link Lakehouse
WH_WORKSPACE_ID     = "2b09b481-244a-470e-9797-6743fd25ca05"  # workspace containing the Fabric Warehouse (set if different from LH_WORKSPACE_ID)
FABRIC_LH_DATABASE  = "dataverse_stiuat_cds2_workspace_unqb7d4a6439257f0118ee5002248282"
FABRIC_WH_DATABASE  = "dev_WH_Raw"

#Optional parameters to connect to your Synapse Serveress to get table and schema info
DRIVER              = "{ODBC Driver 18 for SQL Server}"
SYNAPSE_SERVER      = None # update to example value "d365analyticsfabricsynapse-ondemand.sql.azuresynapse.net"  
SYNAPSE_EDL_DATABASE= None #update to example value "analytics.sandbox.operations.dynamics.com" 
SYNAPSE_EDL_SCHEMA  = None  #"dbo" 
SYNAPSE_EDL_CONST_COLUMN_NAME = None #="_SysRowId" 


#Optional parameters to connect to your Synapse Serveress Datawarehouse to get views and dependencies
SYNAPSE_DW_DATABASE = None # example value "Dynamics365_DW"
SYNAPSE_DW_SCHEMA   = None # example value "dbo"
SYNAPSE_DW_VIEWS    = None # example value "CustomerDim,SalesFact,SupplierDim"
FABRIC_WH_SCHEMA    = None # example value "edw"

#Fixed parameter - No need to change
GITHUB_RAW_BASE_URL = "https://github.com/microsoft/Dynamics-365-FastTrack-Implementation-Assets/tree/master/Administration/Analytics/DataverseLink/FabricLink_SQLAnalyticsEndpoint/DVFabricLinkUtil"
#GITHUB_RAW_BASE_URL = "https://raw.githubusercontent.com/microsoft/Dynamics-365-FastTrack-Implementation-Assets/refs/heads/master/Analytics/DataverseLink/FabricLink_SQLAnalyticsEndpoint/DVFabricLinkUtil/"

DERIVED_TABLE_MAP_PATH = "./builtin/resources/derived_table_map.json"
LH_DDL_TEMPLATE_PATH = "./builtin/resources/get_lh_ddl_as_view.sql"
VIEW_DEPENDENCY_TEMPLATE_PATH = "./builtin/resources/get_view_dependency.sql"
REQUIRED_FILES = [
    ("derived_table_map.json", DERIVED_TABLE_MAP_PATH),
    ("get_lh_ddl_as_view.sql", LH_DDL_TEMPLATE_PATH),
    ("get_view_dependency.sql", VIEW_DEPENDENCY_TEMPLATE_PATH)]

WAREHOUSE_VIEW_DDL_PARAMETERS = {
            "source_schema": "dbo",
            "target_schema": "dbo",
            "only_fno_tables": 1,
            "tables_to_include":"*",
            "tables_to_exclude": "*",
            "filter_deleted_rows": 1,
            "join_derived_tables": 1,
            "change_collation": 1,
            "translate_enums": 1,
            "schema_map": '[]',
            "derived_table_map": '[]'
        }
   



# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# --- Imports ---
import requests
import json
import logging
import time
import struct
import urllib.parse
import pandas as pd
from IPython.display import display, JSON
from sqlalchemy import create_engine, text, event
from requests.exceptions import HTTPError
import sys
import os
import re

synapse_edl_engine = None
synapse_dw_engine = None

def download_file_if_not_exists(url, local_path):
    """Download a file from GitHub if it doesn't exist locally."""
    if not notebookutils.fs.exists(local_path):
        notebookutils.fs.mkdirs(os.path.dirname(local_path))
        logger.info(f"⬇️ Downloading {local_path} ...")
        response = requests.get(url)
        response.raise_for_status()  # Fail if not 200 OK
        notebookutils.fs.put(local_path, response.content.decode('utf-8'))  # <-- decode bytes to string
    else:
        logger.info(f"📄 File already exists locally: {local_path}")

def is_not_none_and_empty(s):
    return s is not None and s != ''


# --- Database Connections ---
def create_synapse_engine(server, database):
    connection_string = f"DRIVER={DRIVER};SERVER={server};DATABASE={database};Encrypt=yes;TrustServerCertificate=no;"
    odbc_conn_str = f"mssql+pyodbc:///?odbc_connect={urllib.parse.quote_plus(connection_string)}"
    engine = create_engine(odbc_conn_str)
    return engine

synapse_edl_engine = create_synapse_engine(SYNAPSE_SERVER, SYNAPSE_EDL_DATABASE)
synapse_dw_engine = create_synapse_engine(SYNAPSE_SERVER, SYNAPSE_DW_DATABASE)

@event.listens_for(synapse_edl_engine, "do_connect")
@event.listens_for(synapse_dw_engine, "do_connect")
def inject_access_token(dialect, conn_rec, cargs, cparams):
    token = notebookutils.credentials.getToken("https://database.windows.net/")
    token_bytes = token.encode("utf-16-le")
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
    cparams["attrs_before"] = {1256: token_struct}

# --- Utility Functions ---
def load_builtin_file(path):
    """Load a built-in SQL or JSON file."""
    return notebookutils.fs.head(path)

def connect_to_fabric_artifact(artifact_name, workspace_id):
    return notebookutils.data.connect_to_artifact(artifact_name, workspace_id)

# --- Warehouse Management ---
def warehouse_exists(workspace_id, warehouse_name):
    try:
        connect_to_fabric_artifact(warehouse_name, workspace_id)
        return True
    except Exception as e:
        if "ArtifactNotFoundException" in str(type(e)):
            logger.info(f"🔍 Warehouse not found:{warehouse_name}")
            return False
        raise

def create_case_insensitive_warehouse(workspace_id, warehouse_name, retries=5, delay=10):
    if warehouse_exists(workspace_id, warehouse_name):
        logger.info(f"✅ Warehouse '{warehouse_name}' already exists.")
        return True

    logger.info(f"🏗️ Creating new warehouse:{warehouse_name}")
    token = notebookutils.credentials.getToken("https://api.fabric.microsoft.com/")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {
        "type": "Warehouse",
        "displayName": warehouse_name,
        "description": "New warehouse with case-insensitive collation",
        "creationPayload": {"defaultCollation": "Latin1_General_100_CI_AS_KS_WS_SC_UTF8"}
    }

    response = requests.post(
        f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/items",
        headers=headers, data=json.dumps(payload)
    )
    logger.info(f"📨 Warehouse creation response: {response.text}", )

    for attempt in range(retries):
        time.sleep(delay)
        if warehouse_exists(workspace_id, warehouse_name):
            logger.info("✅ Warehouse is ready.")
            return True
        logger.info(f"🔄 Retry {attempt + 1}/{retries}: Warehouse not yet available.")

    logger.error("❌ Failed to create warehouse after retries.")
    return False

# --- Schema Retrieval ---
def fetch_tables_and_schema_map(engine):
    """Fetch table list and schema mapping."""
    table_list_query = f"""
        SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), TABLE_NAME), ',') AS tablelist
        FROM (
            SELECT DISTINCT LOWER(TABLE_NAME) as TABLE_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '{SYNAPSE_EDL_SCHEMA}' 
              AND TABLE_NAME IN (
                  SELECT DISTINCT TABLE_NAME 
                  FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = '{SYNAPSE_EDL_SCHEMA}' 
                    AND COLUMN_NAME = '{SYNAPSE_EDL_CONST_COLUMN_NAME}'
              )
        ) AS tbl
    """
    schema_map_query = f"""
        SELECT TABLE_NAME as tablename, COLUMN_NAME as columnname,
            DATA_TYPE + 
            CASE 
                WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
                WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN '(max)'
                WHEN DATA_TYPE = 'decimal' THEN '(' + CAST(NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(NUMERIC_SCALE AS VARCHAR(10)) + ')'
                ELSE '' 
            END AS datatype
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{SYNAPSE_EDL_SCHEMA}'
          AND TABLE_NAME IN (
              SELECT DISTINCT TABLE_NAME 
              FROM INFORMATION_SCHEMA.COLUMNS
              WHERE TABLE_SCHEMA = '{SYNAPSE_EDL_SCHEMA}' AND COLUMN_NAME = '{SYNAPSE_EDL_CONST_COLUMN_NAME}'
          )
    """
    with engine.connect() as conn:
        table_list = conn.execute(text(table_list_query)).scalar()
    schema_map_df = pd.read_sql(schema_map_query, engine)
    schema_map_json = schema_map_df.to_json(orient="records")

    return table_list, schema_map_json

# --- DDL and View Creation ---
def generate_lh_view_ddl(lakehouse_name, params):
    """Generate view DDL based on Lakehouse tables."""
    conn = connect_to_fabric_artifact(lakehouse_name, LH_WORKSPACE_ID)

    variables_script = f"""
        DECLARE 
            @source_database_name VARCHAR(200) = '{lakehouse_name}',
            @source_table_schema NVARCHAR(10) = '{params["source_schema"]}',
            @target_table_schema NVARCHAR(10) = '{params["target_schema"]}',
            @TablesToInclude_FnOOnly INT = {params["only_fno_tables"]},
            @TablesToIncluce NVARCHAR(MAX) = '{params["tables_to_include"]}',
            @TablesToExcluce NVARCHAR(MAX) = '{params["tables_to_exclude"]}',
            @filter_deleted_rows INT = {params["filter_deleted_rows"]},
            @join_derived_tables INT = {params["join_derived_tables"]},
            @change_column_collation INT = {params["change_collation"]},
            @translate_enums INT = {params["translate_enums"]},
            @schema_map VARCHAR(MAX) = {params["schema_map"]},
            @tableinheritance NVARCHAR(MAX) = LOWER('{params["derived_table_map"]}');
    """
    sql_template = load_builtin_file(LH_DDL_TEMPLATE_PATH)
    
    sqlquery = f"{variables_script} {sql_template}"

    logger.debug(f"Debug: generate_lh_view_ddl query {sqlquery}")
    df = conn.query(f"{sqlquery}")
    ddl_statement = df.iloc[0, 0]
    logger.debug(f"Debug: generate_lh_view_ddl statement {sqlquery}")

    return ddl_statement

def execute_ddl_on_warehouse(warehouse_name, ddl_query):
    """Execute DDL in warehouse."""
    conn = connect_to_fabric_artifact(warehouse_name, WH_WORKSPACE_ID)
    conn.query(ddl_query)

# --- View Dependency Management ---
def fetch_view_dependencies(engine, root_entities, old_db, new_db, old_schema, new_schema):
    sql_template = load_builtin_file(VIEW_DEPENDENCY_TEMPLATE_PATH)
    sql_script = f"""
        SET NOCOUNT ON;
        DROP TABLE IF EXISTS #myEntitiestree;
        DECLARE @entities NVARCHAR(MAX) = '{root_entities}';
        DECLARE @old_schema VARCHAR(10) = '{old_schema}';
        DECLARE @new_schema VARCHAR(10) = '{new_schema}';
        {sql_template}
    """
    with engine.connect() as conn:
        result = conn.execute(text(sql_script))
        df = pd.DataFrame(result.fetchall(), columns=result.keys())
    df["definition"] = df["definition"].str.replace(old_db, new_db, case=False, regex=False)
    return df.to_json(orient="records")

def deploy_views(warehouse_name, schema, views_json):
    execute_ddl_on_warehouse(warehouse_name, f"IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = '{schema}') BEGIN EXEC('CREATE SCHEMA {schema}'); END;")
    views = json.loads(views_json)
    for view in sorted(views, key=lambda x: x["depth"], reverse=True):
        if view.get("definition"):
            try:
                entityname = view["entityName"]
                execute_ddl_on_warehouse(warehouse_name, view["definition"])
                logger.info(f"✅ Deployed view: {entityname}")
            except Exception as e:
                logger.error(f"❌ Failed to deploy view {entityname}: {e}")

for handler in logging.root.handlers[:]:  # Clear existing handlers
    logging.root.removeHandler(handler)

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)]  # Explicitly use stdout
)

logger = logging.getLogger()  

# --- Main Execution ---
def main():
    
    logger.info("🏗️ Step 1: Download template files if does not exists.")
    # --- Download if not exists ---
    for filename, local_path in REQUIRED_FILES:
        file_url = f"{GITHUB_RAW_BASE_URL}/{filename}"
        download_file_if_not_exists(file_url, local_path)
        
    logger.info("🏗️ Step 2/7: Ensure case-insensitive warehouse exists.")
    
    if create_case_insensitive_warehouse(WH_WORKSPACE_ID, FABRIC_WH_DATABASE):

        logger.info("🔹 Step 3/7: Fetch tables and schema map from Synapse.")
        tables_to_include = '*'
        schema_map = '[]'
        if is_not_none_and_empty(SYNAPSE_SERVER) and is_not_none_and_empty(SYNAPSE_EDL_DATABASE) :
          
            tables_to_include, schema_map = fetch_tables_and_schema_map(synapse_edl_engine)
        else:
            logger.info("🔹 Step 3/7: Skipped")

        logger.info("🔁 Step 4/7: Load derived table map.")
        derived_table_map = load_builtin_file(DERIVED_TABLE_MAP_PATH)

        logger.info(f"🛠️ Step 5/7: Generating view DDLfrom {FABRIC_LH_DATABASE}...")
        
        # Create a copy of the parameters and update the dynamic fields
        params = WAREHOUSE_VIEW_DDL_PARAMETERS.copy()
        params["schema_map"] = f"'{schema_map}'"
        params["derived_table_map"] = derived_table_map
        params["tables_to_include"] = tables_to_include


        views_ddl = generate_lh_view_ddl(FABRIC_LH_DATABASE, params)
      
      
        logger.info(f"🛠️ Step 5/7: Executing views DDL on Fabric DW {FABRIC_WH_DATABASE}.")

        view_ddls = views_ddl.split(';')
        view_count = len(view_ddls)
        logger.info(f"{view_count} views to deploy.")
        # Loop through each item
        counter= 1
        for view_ddl in view_ddls:
            match = re.search(r"CREATE\s+OR\s+ALTER\s+VIEW\s+([\w\.]+)", view_ddl, re.IGNORECASE)
            if match:
                view_name = match.group(1)
                logger.info(f"{view_count}/{counter} CREATE OR ALTER VIEW {view_name}")
                execute_ddl_on_warehouse(FABRIC_WH_DATABASE, view_ddl)
                counter += 1

        if is_not_none_and_empty(SYNAPSE_SERVER) and is_not_none_and_empty(SYNAPSE_DW_DATABASE) :
 
            logger.info("🚀 Step 6/7: Fetch view dependencies.")
            views_json = fetch_view_dependencies(
                synapse_dw_engine, SYNAPSE_DW_VIEWS,
                SYNAPSE_EDL_DATABASE, FABRIC_WH_DATABASE,
                SYNAPSE_DW_SCHEMA, FABRIC_WH_SCHEMA
            )

            logger.info("🚀 Step 7/7: Deploy views to warehouse.")
            deploy_views(FABRIC_WH_DATABASE, FABRIC_WH_SCHEMA, views_json)
        else:
            logger.info("🔹 Step 6 and 7: Skipped")

        logger.info("🎉 Deployment complete.")
    else:
        logger.error("❌ Warehouse setup failed.")
    

if __name__ == "__main__":
    main()


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }
