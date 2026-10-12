# Power Query transformations

Extracted from the saved model. Local source paths below are replaced by `C:\PATH\TO\inputs\` for portability; the PBIX retains its original source paths. Set the three file sources in Power Query before refreshing.

## stg_WP009_Sensitivity

```powerquery
let
    Source = Excel.Workbook(File.Contents("C:\PATH\TO\inputs\NEXT_WP009_Sensitivity_and_Break_Even_v1.1.xlsx"), null, true),
    Sensitivity_Sheet = Source{[Item="Sensitivity",Kind="Sheet"]}[Data]
in
    Sensitivity_Sheet
```

## stg_WP009_SourceData

```powerquery
let
    Source = Excel.Workbook(File.Contents("C:\PATH\TO\inputs\NEXT_WP009_Sensitivity_and_Break_Even_v1.1.xlsx"), null, true),
    Source_Data_Sheet = Source{[Item="Source_Data",Kind="Sheet"]}[Data]
in
    Source_Data_Sheet
```

## stg_WP010_CategoryDecisions

```powerquery
let
    Source = Excel.Workbook(File.Contents("C:\PATH\TO\inputs\NEXT_WP010_Recommendation_Evidence_v1.1.xlsx"), null, true),
    Category_Decisions_Sheet = Source{[Item="Category_Decisions",Kind="Sheet"]}[Data]
in
    Category_Decisions_Sheet
```

## stg_HeadroomComparisons

```powerquery
let
    Source = stg_WP010_CategoryDecisions,
    #"Removed Top Rows" = Table.Skip(Source,50),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",10),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Case", Int64.Type}, {"Comparison", type text}, {"Price basis", type text}, {"Receiver duty-paid GBP/kg", type number}, {"China duty-paid GBP/kg", type number}, {"Headroom GBP/kg", type number}, {"Max premium", type number}, {"Cotton moves", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Case", "Case ID"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "CN8", each if Text.StartsWith([Comparison], "Dresses")
then "62044300"
else "61103099"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom",{{"CN8", type text}})
in
    #"Changed Type1"
```

## stg_HeadroomCottonDefaults

```powerquery
let
    Source = stg_WP010_CategoryDecisions,
    #"Removed Top Rows" = Table.Skip(Source,14),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",5),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column3", "Column4", "Column5", "Column6"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"CN8", type text}, {"China duty GBP/kg", type number}, {"Receiver GBP/kg", type number}, {"Headroom GBP/kg", type number}, {"Max receiver premium", type number}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each ([CN8] = "61091000" or [CN8] = "62052000")),
    #"Renamed Columns" = Table.RenameColumns(#"Filtered Rows",{{"China duty GBP/kg", "China duty-paid GBP/kg"}, {"Receiver GBP/kg", "Receiver duty-paid GBP/kg"}, {"Max receiver premium", "Max premium"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "Case ID", each 1),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "Comparison", each "Default mix"),
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "Price basis", each "H1 2026 reported"),
    #"Added Custom3" = Table.AddColumn(#"Added Custom2", "Cotton moves", each "Yes"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom3",{{"Case ID", Int64.Type}, {"Comparison", type text}, {"Price basis", type text}, {"Cotton moves", type text}})
in
    #"Changed Type1"
```

## FactScenarioCategory

```powerquery
let
    Source = stg_WP009_Sensitivity,
    #"Removed Top Rows" = Table.Skip(Source,56),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",105),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Case ID", Int64.Type}, {"CN8", type text}, {"Feasible shift", type number}, {"Cost change", type number}, {"HHI change", type number}, {"Max receiver multiple", type number}})
in
    #"Changed Type"
```

## DimScenario

```powerquery
let
    Source = stg_WP009_Sensitivity,
    #"Removed Top Rows" = Table.Skip(Source,169),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",27),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8", "Column9", "Column10", "Column11"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"ID", Int64.Type}, {"Case", type text}, {"Price period", type text}, {"Data basis", type text}, {"Tariff test", type text}, {"Use growth cap", Int64.Type}, {"Max multiple", Int64.Type}, {"Requested shift", type number}, {"Premium", type number}, {"Mix ID", Int64.Type}, {"Operating set", Int64.Type}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"ID", "Case ID"}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Renamed Columns",{{"Max multiple", type number}, {"Case", type text}})
in
    #"Changed Type1"
```

## DimCategory

```powerquery
let
    Source = stg_WP009_SourceData,
    #"Removed Top Rows" = Table.Skip(Source,174),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",5),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column2"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"CN8", Int64.Type}, {"Product", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Product", "Category"}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Renamed Columns",{{"CN8", type text}})
in
    #"Changed Type1"
```

## FactBasket

```powerquery
let
    Source = stg_WP009_Sensitivity,
    #"Removed Top Rows" = Table.Skip(Source,5),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",27),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column3", "Column4"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"ID", Int64.Type}, {"Equal-weight cost change", type number}, {"Value-weight cost change", type number}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"ID", "Case ID"}})
in
    #"Renamed Columns"
```

## FactHeadroom

```powerquery
let
    Source = Table.Combine({stg_HeadroomComparisons, stg_HeadroomCottonDefaults})
in
    Source
```

## FactSiteFootprint

```powerquery
let
    Source = Csv.Document(File.Contents("C:\PATH\TO\inputs\NEXT_WP006_site_supplier_overlap.csv"),[Delimiter=",", Columns=12, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"site_id", type text}, {"site_name_canonical", type text}, {"country_standardized", type text}, {"product_type_standardized", type text}, {"relationship_count", Int64.Type}, {"source_supplier_count", Int64.Type}, {"resolved_supplier_group_count", Int64.Type}, {"source_supplier_shared_site_flag", Int64.Type}, {"resolved_group_shared_site_flag", Int64.Type}, {"physical_site_review_flag", Int64.Type}, {"physical_site_review_status", type text}, {"responsible_sourcing_review_flag", Int64.Type}})
in
    #"Changed Type"
```

## DimCountry

```powerquery
let
    Source = FactSiteFootprint,
    #"Removed Other Columns" = Table.SelectColumns(Source,{"country_standardized"}),
    #"Removed Duplicates" = Table.Distinct(#"Removed Other Columns"),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Duplicates",{{"country_standardized", "Country"}})
in
    #"Renamed Columns"
```

## FactTradeBenchmark

```powerquery
let
    Source = stg_WP009_SourceData,
    #"Removed Top Rows" = Table.Skip(Source,4),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",121),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8", "Column9", "Column10", "Column11", "Column12", "Column13", "Column14", "Column15", "Column16"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Key", type text}, {"Period", type text}, {"Country", type text}, {"CN8", Int64.Type}, {"Reported value £", Int64.Type}, {"Reported mass kg", type number}, {"Months", Int64.Type}, {"REVIEW months", Int64.Type}, {"Export UV £/kg", type number}, {"Start month", Int64.Type}, {"End month", Int64.Type}, {"Common value £", type number}, {"Common mass kg", type number}, {"Common months", Int64.Type}, {"Common UV £/kg", type number}, {"Key count", Int64.Type}})
in
    #"Changed Type"
```

## DimPeriod

```powerquery
let
    Source = FactTradeBenchmark,
    #"Removed Other Columns" = Table.SelectColumns(Source,{"Period"}),
    #"Removed Duplicates" = Table.Distinct(#"Removed Other Columns")
in
    #"Removed Duplicates"
```

## FactTariffBenchmark

```powerquery
let
    Source = stg_WP009_SourceData,
    #"Removed Top Rows" = Table.Skip(Source,129),
    #"Kept First Rows" = Table.FirstN(#"Removed Top Rows",41),
    #"Removed Other Columns" = Table.SelectColumns(#"Kept First Rows",{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8", "Column9", "Column10", "Column11", "Column12"}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Removed Other Columns", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Key", type text}, {"Country", type text}, {"CN8", type text}, {"2025 eligible", type number}, {"Pre-15 July 2026", type number}, {"From 15 July 2026", type number}, {"MFN fallback", type number}, {"Conditional", type text}, {"Source IDs", type text}, {"Evidence queries", type text}, {"WP004 location", type text}, {"Key count", Int64.Type}})
in
    #"Changed Type"
```

