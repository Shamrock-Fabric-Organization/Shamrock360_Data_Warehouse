CREATE TABLE [dbo].[tbl_DIM_StandardCost] (
    [StandardCostKey]                                    BIGINT          NULL,
    [CMPNY]                                              VARCHAR (8000)  NULL,
    [Product_ID]                                         VARCHAR (8000)  NULL,
    [SiteID]                                             VARCHAR (8000)  NULL,
    [ActivationDate]                                     DATETIME2 (3)   NULL,
    [EndDate]                                            DATETIME2 (6)   NULL,
    [Costing_Version]                                    VARCHAR (8000)  NULL,
    [CurrentActiveCost]                                  INT             NULL,
    [ProductName]                                        VARCHAR (8000)  NULL,
    [ProductSearchName]                                  VARCHAR (8000)  NULL,
    [Direct_Material_Cost_Standard]                      DECIMAL (38, 6) NULL,
    [Packaging_Cost_Standard]                            DECIMAL (38, 6) NULL,
    [Direct_Labor_Cost_Standard]                         DECIMAL (38, 6) NULL,
    [Direct_Utility_Cost_Standard]                       DECIMAL (38, 6) NULL,
    [Overhead_Warehouse_Cost_Standard]                   DECIMAL (38, 6) NULL,
    [Overhead_Indirect_Supervisor_Cost_Standard]         DECIMAL (38, 6) NULL,
    [Overhead_Quality_Cost_Standard]                     DECIMAL (38, 6) NULL,
    [Overhead_Maintenance_Cost_Standard]                 DECIMAL (38, 6) NULL,
    [Overhead_Manufacturing_Admin_Cost_Standard]         DECIMAL (38, 6) NULL,
    [Overhead_Depreciation_Cost_Standard]                DECIMAL (38, 6) NULL,
    [Overhead_Miscellaneous_Manufacturing_Cost_Standard] DECIMAL (38, 6) NULL,
    [Outside_Processing_Cost_Standard]                   DECIMAL (38, 6) NULL,
    [Total_Direct_Cost_Standard]                         DECIMAL (38, 6) NULL,
    [Total_Overhead_Cost_Standard]                       DECIMAL (38, 6) NULL,
    [TotalCost]                                          DECIMAL (38, 6) NULL,
    [accountingcurrency]                                 VARCHAR (8000)  NULL,
    [RecordEffectiveStartDate]                           DATETIME2 (3)   NULL,
    [RecordEffectiveEndDate]                             DATETIME2 (3)   NULL,
    [RecordStatus]                                       INT             NOT NULL,
    [Source]                                             VARCHAR (6)     NOT NULL
);


GO

