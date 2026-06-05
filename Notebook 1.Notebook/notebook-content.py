# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

# Welcome to your new notebook
# Type here in the cell editor to add code!
import requests
import json
import logging
import time
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger()

# Constants
WORKSPACE_ID = "2b09b481-244a-470e-9797-6743fd25ca05"
WAREHOUSE_NAME = "WH_Curated"
COLLATION = "Latin1_General_100_CI_AS_KS_WS_SC_UTF8"

# Get Fabric API token using mssparkutils
token = mssparkutils.credentials.getToken("https://api.fabric.microsoft.com/")
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# Payload to create the warehouse
payload = {
    "type": "Warehouse",
    "displayName": WAREHOUSE_NAME,
    "description": "Warehouse with case-insensitive collation",
    "creationPayload": {
        "defaultCollation": COLLATION
    }
}

# API call to create the warehouse
url = f"https://api.fabric.microsoft.com/v1/workspaces/{WORKSPACE_ID}/items"
response = requests.post(url, headers=headers, data=json.dumps(payload))

# Log the result
if response.status_code in [200, 201, 202]:
    logger.info(f"✅ Warehouse '{WAREHOUSE_NAME}' created successfully.")
    logger.info(f"Response: {response.json()}")
else:
    logger.error(f"❌ Failed to create warehouse. Status: {response.status_code}")
    logger.error(f"Response: {response.text}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
