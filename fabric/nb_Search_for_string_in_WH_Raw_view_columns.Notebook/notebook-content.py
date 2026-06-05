# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

# %% ── CELL 1 ── CONFIGURATION ───────────────────────────────

SEARCH_VALUE   = "Melt Blending"

TABLE_FILTER   = None   # e.g. "%CUST%" — None for all tables
COLUMN_FILTER  = None   # e.g. "%NAME%" — None for all columns
BATCH_SIZE     = 50     # Columns per batch query; reduce if timeouts occur

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# %% ── CELL 2 ── CONNECTION ──────────────────────────────────
#
#  Uses the Fabric notebook token (notebookutils.credentials)
#  so no password or service principal is needed.
#  The token is scoped to the Azure SQL / Fabric SQL endpoint
#  resource ("https://database.windows.net/").
#
#  Update WAREHOUSE_SERVER and WAREHOUSE_DB to match your
#  Fabric Warehouse SQL endpoint.  Find the server name on the
#  Warehouse settings page → SQL connection string.
# ─────────────────────────────────────────────────────────────

import pyodbc
import struct
import pandas as pd

# Configure your warehouse endpoint:
#WAREHOUSE_SERVER = "2b09b481-244a-470e-9797-6743fd25ca05.datawarehouse.fabric.microsoft.com"
#WAREHOUSE_DB     = "WH_Raw"

WAREHOUSE_SERVER = "efrhfadk6eru3b7hpy4j3xs2eu-qg2ask2keqhepf4xm5b72jokau.datawarehouse.fabric.microsoft.com"
WAREHOUSE_DB = "WH_Raw"

# Defensive: ensure server string does not have leading/trailing whitespace
WAREHOUSE_SERVER = WAREHOUSE_SERVER.strip()
WAREHOUSE_DB = WAREHOUSE_DB.strip()

# Defensive retry mechanism for transient connectivity issues
import time
MAX_RETRIES = 3
RETRY_WAIT_SEC = 10
conn = None
attempt = 0
while attempt < MAX_RETRIES:
    try:
        _token_str    = notebookutils.credentials.getToken("https://database.windows.net/")
        _token_bytes  = bytes(_token_str, "UTF-8")
        _token_struct = struct.pack("=i", len(_token_bytes) * 2) + b"".join(
            bytes([b, 0]) for b in _token_bytes
        )

        conn = pyodbc.connect(
            f"DRIVER={{ODBC Driver 18 for SQL Server}};"
            f"SERVER={WAREHOUSE_SERVER};"
            f"DATABASE={WAREHOUSE_DB};"
            "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;",
            attrs_before={1256: _token_struct}   # 1256 = SQL_COPT_SS_ACCESS_TOKEN
        )
        print(f"Connected to {WAREHOUSE_DB} on {WAREHOUSE_SERVER}.")
        break
    except pyodbc.OperationalError as err:
        attempt += 1
        print(f"ODBC OperationalError (attempt {attempt}): {err}")
        if attempt >= MAX_RETRIES:
            print("\nFailed to connect after multiple attempts. Possible causes: network connectivity issues, incorrect server name, database is paused or scaling, or firewall blocks access. Please verify your Warehouse SQL endpoint and ensure it is accessible.")
            raise
        print(f"Retrying in {RETRY_WAIT_SEC} seconds...")
        time.sleep(RETRY_WAIT_SEC)

# If connection fails entirely, exception is raised and halts the notebook.

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# %% ── CELL 3 ── COLUMN INVENTORY ───────────────────────────
#
#  Plain SELECT against sys catalog views — no DML, no
#  distributed-mode restriction.
# ─────────────────────────────────────────────────────────────

_filter_clauses = []
_params         = []

if TABLE_FILTER:
    _filter_clauses.append("AND t.name LIKE ?")
    _params.append(TABLE_FILTER)
if COLUMN_FILTER:
    _filter_clauses.append("AND c.name LIKE ?")
    _params.append(COLUMN_FILTER)

_schema_sql = """
SELECT
     s.name  AS TableSchema
    ,t.name  AS TableName
    ,c.name  AS ColumnName
FROM sys.columns c
JOIN sys.views  t  ON  t.object_id     = c.object_id
JOIN sys.schemas s  ON  s.schema_id     = t.schema_id
JOIN sys.types   tp ON  tp.user_type_id = c.user_type_id
WHERE tp.name IN ('char', 'varchar', 'nchar', 'nvarchar')
  {filters}
ORDER BY s.name, t.name, c.name
""".format(filters="\n  ".join(_filter_clauses))

columns_df = pd.read_sql(_schema_sql, conn, params=_params)
print(f"Found {len(columns_df):,} string column(s) to search.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# %% ── CELL 4 ── BATCHED SEARCH ──────────────────────────────
#
#  Processes BATCH_SIZE columns per query to bound query size.
#  Each batch builds a UNION ALL SELECT against real data tables
#  only — no catalog views, no distributed-mode restriction.
#  HAVING COUNT(*) > 0 filters zero-match groups before results
#  are returned, keeping the result set clean.
# ─────────────────────────────────────────────────────────────

_results = []
_total   = len(columns_df)
_safe_val = SEARCH_VALUE.replace("'", "''")

for _batch_start in range(0, _total, BATCH_SIZE):
    _batch = columns_df.iloc[_batch_start : _batch_start + BATCH_SIZE]

    _selects = []
    for _, _row in _batch.iterrows():
        _selects.append(
            f"SELECT"
            f" '{_row.TableSchema}.{_row.TableName}' AS TableName"
            f", '{_row.ColumnName}' AS ColumnName"
            f", LEFT(CAST([{_row.ColumnName}] AS VARCHAR(4096)), 4096) AS ColumnValue"
            f", COUNT(*) AS MatchCount"
            f" FROM [{_row.TableSchema}].[{_row.TableName}]"
            f" WHERE CAST([{_row.ColumnName}] AS VARCHAR(4096)) LIKE '{_safe_val}'"
            f" GROUP BY LEFT(CAST([{_row.ColumnName}] AS VARCHAR(4096)), 4096)"
            f" HAVING COUNT(*) > 0"
        )

    _union_sql = " UNION ALL ".join(_selects)

    try:
        _batch_df = pd.read_sql(_union_sql, conn)
        if not _batch_df.empty:
            _results.append(_batch_df)
    except Exception as _ex:
        print(f"  Warning — batch {_batch_start}–{min(_batch_start + BATCH_SIZE - 1, _total - 1)}: {_ex}")

    _searched = min(_batch_start + BATCH_SIZE, _total)
    print(f"  Searched {_searched:,} / {_total:,} columns...", end="\r")

print(f"\nSearch complete.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# %% ── CELL 5 ── RESULTS ─────────────────────────────────────

if _results:
    final_df = (
        pd.concat(_results, ignore_index=True)
          .sort_values(["TableName", "ColumnName", "ColumnValue"])
          .reset_index(drop=True)
    )
    print(f"Found {len(final_df):,} match(es) across {final_df['TableName'].nunique():,} table(s).\n")
    display(final_df)
else:
    print("No matches found.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
