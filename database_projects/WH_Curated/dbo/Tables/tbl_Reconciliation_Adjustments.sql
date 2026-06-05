CREATE TABLE [dbo].[tbl_Reconciliation_Adjustments] (
    [CMPNY]                                  VARCHAR (10)    NULL,
    [Reconciliation_Year]                    VARCHAR (50)    NULL,
    [Sales_Discounts]                        DECIMAL (18, 2) NULL,
    [Sales_Rebates]                          DECIMAL (18, 2) NULL,
    [Tariff_Surcharge_Recovery]              DECIMAL (18, 2) NULL,
    [Pallet_Break_Surcharge]                 DECIMAL (18, 2) NULL,
    [Freight_Billed_Received_From_Customers] DECIMAL (18, 2) NULL,
    [Additional_1]                           DECIMAL (18, 2) NULL,
    [Additional_1_Desc]                      VARCHAR (50)    NULL,
    [Additional_2]                           DECIMAL (18, 2) NULL,
    [Additional_2_Desc]                      VARCHAR (50)    NULL,
    [Total_Adjustments]                      DECIMAL (18, 2) NULL
);


GO

