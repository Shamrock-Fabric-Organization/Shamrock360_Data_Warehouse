[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "mtbl_EDW_RouteType_DataDestination", IsNewTarget = true], Settings = [Kind = "Manual", AllowCreation = true, ColumnSettings = [Mappings = {[SourceColumnName = "RouteNo", DestinationColumnName = "RouteNo"], [SourceColumnName = "RouteType", DestinationColumnName = "RouteType"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared mtbl_EDW_RouteType = let
  Source = Csv.Document(Web.Contents("https://shamrocktechnologiesus-my.sharepoint.com/personal/kyoung_shamrocktechnologies_com/Documents/Apps/Microsoft Power Query/Uploaded Files/RouteType 2.csv"), [Delimiter = ",", Columns = 2, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Changed column type" = Table.TransformColumnTypes(Source, {{"Column1", type text}, {"Column2", type text}}),
  #"Promoted headers" = Table.PromoteHeaders(#"Changed column type", [PromoteAllScalars = true])
in
  #"Promoted headers";
shared mtbl_EDW_RouteType_DataDestination = let
  Pattern = Fabric.Warehouse([HierarchicalNavigation = null, CreateNavigationProperties = false]),
  Navigation_1 = Pattern{[workspaceId = "2b09b481-244a-470e-9797-6743fd25ca05"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "c7f6f216-ce5d-45b3-878f-30c744b0fa28"]}[Data],
  TableNavigation = Navigation_2{[Item = "EDW_RouteType", Schema = "dbo"]}?[Data]?
in
  TableNavigation;
