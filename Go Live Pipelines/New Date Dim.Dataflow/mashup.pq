[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Sheet1_DataDestination", IsNewTarget = true], Settings = [Kind = "Manual", AllowCreation = true, ColumnSettings = [Mappings = {[SourceColumnName = "RECID", DestinationColumnName = "RECID"], [SourceColumnName = "FISCAL QTR", DestinationColumnName = "FISCAL QTR"], [SourceColumnName = "FISCAL YR", DestinationColumnName = "FISCAL YR"], [SourceColumnName = "FISCAL PERIOD", DestinationColumnName = "FISCAL PERIOD"], [SourceColumnName = "WEEKS IN PERIOD", DestinationColumnName = "WEEKS IN PERIOD"], [SourceColumnName = "FISCAL WEEK #", DestinationColumnName = "FISCAL WEEK #"], [SourceColumnName = "YEAR", DestinationColumnName = "YEAR"], [SourceColumnName = "QTR", DestinationColumnName = "QTR"], [SourceColumnName = "MONTH", DestinationColumnName = "MONTH"], [SourceColumnName = "DAY", DestinationColumnName = "DAY"], [SourceColumnName = "WEEKDAY", DestinationColumnName = "WEEKDAY"], [SourceColumnName = "WEEK #", DestinationColumnName = "WEEK #"], [SourceColumnName = "DATE", DestinationColumnName = "DATE"], [SourceColumnName = "DAY #", DestinationColumnName = "DAY #"], [SourceColumnName = "FISCAL DAY #", DestinationColumnName = "FISCAL DAY #"], [SourceColumnName = "Reconciliation Year", DestinationColumnName = "Reconciliation Year"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared Sheet1 = let
  Source = Excel.Workbook(Web.Contents("https://shamrocktechnologiesus-my.sharepoint.com/personal/jcorby_shamrocktechnologies_com/Documents/Apps/Microsoft Power Query/Uploaded Files/NewDateDimension.xlsx"), null, true),
  #"Navigation 1" = Source{[Item = "Sheet1", Kind = "Sheet"]}[Data],
  #"Promoted headers" = Table.PromoteHeaders(#"Navigation 1", [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"RECID", Int64.Type}, {"FISCAL QTR", Int64.Type}, {"FISCAL YR", Int64.Type}, {"FISCAL PERIOD", Int64.Type}, {"WEEKS IN PERIOD", type number}, {"FISCAL WEEK #", Int64.Type}, {"YEAR", Int64.Type}, {"QTR", Int64.Type}, {"MONTH", Int64.Type}, {"DAY", Int64.Type}, {"WEEKDAY", type text}, {"WEEK #", Int64.Type}, {"DATE", type date}, {"DAY #", Int64.Type}, {"FISCAL DAY #", Int64.Type}, {"Reconciliation Year", type text}})
in
  #"Changed column type";
shared Sheet1_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false]),
  Navigation_1 = Pattern{[workspaceId = "2b09b481-244a-470e-9797-6743fd25ca05"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "66bd9948-838f-472b-ac00-f264e80cf5d2"]}[Data],
  TableNavigation = Navigation_2{[Item = "tbl_Mo_Dim_Date", Schema = "dbo"]}?[Data]?
in
  TableNavigation;
