# WP006 run guide

Use this guide to execute the SQL package or reproduce its exports. For the business purpose and main findings, start with [README.md](README.md); validation evidence is in [QC_SUMMARY.md](QC_SUMMARY.md).

Reading the project and using the included CSVs requires no database setup. Follow the reproduction instructions below to build a separate database or regenerate the exports.

## Prerequisites and execution

Verified environment: PostgreSQL 18.1, 64-bit Windows, with DBeaver 25.3.0. The manual rebuild used `next_sourcing_analytics`; the original working database was `next_sourcing_resilience`. Database names are local choices. Credentials and connection settings are not included.

The scripts use PostgreSQL features including `FILTER`, window functions, `PERCENTILE_CONT`, `EXCEPT ALL`, regular-expression functions and `IS DISTINCT FROM`. They are not intended to run unchanged in another SQL dialect.

### Existing validated database

The CSV exports came from an already populated and validated database. Replacing saved SQL files does not require rerunning table creation or inserts. Run read-only validation or export queries when needed.

### Reproducing the build

To reproduce the fixed snapshot, use a fresh database. Run creation and loading once per database; validation and analytical SELECT queries can be rerun against the populated database. Repeating plain creation statements encounters existing objects, and repeating core inserts encounters key conflicts. The scripts do not implement a refresh or upsert process, and do not drop or reset existing data.

Create a separate database from a maintenance connection with autocommit enabled:

```sql
CREATE DATABASE next_sourcing_analytics
    TEMPLATE template0;
```

Then connect each numbered script to that new database. Check `SELECT current_database();` in its editor before running creation or loading statements. `template0` supplies an unmodified database template; it does not copy project tables from the original database.

| Order | Action |
| --- | --- |
| 1 | Connect to the fresh database; run `01_create_schemas.sql` and `02_verify_schemas.sql`. |
| 2 | Run `03_create_staging_tables.sql`. |
| 3 | Import the seven WP005 files listed below into their staging tables. |
| 4 | Run `04_validate_staging_loads.sql`; inspect counts, distributions and exception results. |
| 5 | Run `05_create_wp003_staging_tables.sql`. |
| 6 | Import the seven WP003 files listed below into their staging tables. |
| 7 | Run `06_validate_wp003_staging.sql` and resolve unexpected exceptions. |
| 8 | Run `07_create_core_tables.sql`, then `08_load_core_tables.sql` in order. |
| 9 | Run all blocks of `09_validate_core_tables.sql`. |
| 10 | Run `10_create_analytics_views.sql`. |
| 11 | Run all twelve blocks of `11_validate_analytics_views.sql`. |
| 12 | Run one query at a time from `12_export_analytics_outputs.sql` and export each result. |

Do not continue a rebuild after an unexpected error. The scripts rely on checking results between stages; they are not an automated test runner that aborts on a nonzero diagnostic count. Staging includes informational distributions and legitimate exceptions, so not every staging result should be empty. Consult the controls in [QC_SUMMARY.md](QC_SUMMARY.md).

The manual rebuild completed on 16 September 2026. In that run, scripts 03 and 05 were executed together before all fourteen imports, followed by checks 04 and 06; the remaining dependencies followed the order above. All ten exported files matched the earlier outputs byte-for-byte. Selected checkpoints and the comparison are documented in [QC_SUMMARY.md](QC_SUMMARY.md).

## Staging CSV imports

In DBeaver, select the existing target staging table and import its mapped CSV. Use UTF-8, comma-separated fields, the first row as headers and `"` as the quote character. Map columns by their exact header names. Import each file once and confirm its row count. The input CSVs retain display formatting from source workbooks, including thousands separators, currency symbols, percentage signs and ratio suffixes. Staging preserves these fields as text. **Import the files unchanged: do not clean or reformat them before import, and do not replace missing values with zero.** Core loads parse the relevant numeric fields; script 09 reconciles formatted reference measures using the documented display-rounding tolerances.

Use the included `Inputs/` files for staging, not the analytical exports. The final-export convention of writing SQL nulls as the literal marker `NULL` is separate from the original input format.

| Input CSV in `Inputs/` | Target staging table | Rows |
| --- | --- | ---: |
| `NEXT_WP005_dim_commodity.csv` | `staging.wp005_dim_commodity` | 5 |
| `NEXT_WP005_dim_partner_country.csv` | `staging.wp005_dim_partner_country` | 10 |
| `NEXT_WP005_dim_month.csv` | `staging.wp005_dim_month` | 90 |
| `NEXT_WP005_raw_partner_monthly.csv` | `staging.wp005_raw_partner_monthly` | 3,588 |
| `NEXT_WP005_raw_world_monthly.csv` | `staging.wp005_raw_world_monthly` | 720 |
| `NEXT_WP005_HMRC_Monthly_Trade_Core4_10Partners_2019-01_to_2026-06.csv` | `staging.wp005_fct_partner_monthly` | 3,600 |
| `NEXT_WP005_HMRC_Monthly_Trade_Core4_World_2019-01_to_2026-06.csv` | `staging.wp005_fct_world_monthly` | 360 |
| `NEXT_WP003_supplier_master.csv` | `staging.wp003_supplier_master` | 672 |
| `NEXT_WP003_supplier_group_master.csv` | `staging.wp003_supplier_group_master` | 661 |
| `NEXT_WP003_supplier_resolution_map.csv` | `staging.wp003_supplier_resolution_map` | 672 |
| `NEXT_WP003_supplier_entity_map.csv` | `staging.wp003_supplier_entity_map` | 672 |
| `NEXT_WP003_site_master.csv` | `staging.wp003_site_master` | 1,478 |
| `NEXT_WP003_raw_tier1_relationships.csv` | `staging.wp003_raw_tier1_relationships` | 2,202 |
| `NEXT_WP003_supplier_site_bridge.csv` | `staging.wp003_supplier_site_bridge` | 2,097 |

These are work-package extracts. The original PDFs/API responses, source register and upstream review workbooks remain the evidence archive for WP003/WP005 and are not reproduced here. Source IDs, source filenames and available record-level lineage are retained in the core tables. Reproduction uses the fixed extracts, not a new request to a live API.

## Export procedure

Run each statement in `12_export_analytics_outputs.sql` separately. Export all result rows and columns, not only selected or currently fetched rows. Use CSV, UTF-8, comma delimiter, headers at the top, label headers with case unchanged, quote character `"`, **Format numbers disabled**, and **NULL string = `NULL`**. No manual rounding is applied in the export queries.

Set the output directory to `Exports/`. Enter the filename from the query comment **without `.csv`** in DBeaver's File name pattern; the CSV exporter adds the extension. Reimport consumers should treat the marker `NULL` as missing and preserve CN8 and Site IDs as identifiers.

The first two outputs are World and partner period trade; they must not be added together. The World denominator repeated on partner rows must not be summed across partner countries.

The full export inventory and snapshot counts are in [QC_SUMMARY.md](QC_SUMMARY.md). Optional display queries in `Analysis/selected_findings.sql` do not replace these full-precision outputs.

## Calculation and interpretation reference

`staging` preserves the source CSV structure as text. `core` adds types, keys and constraints. `analytics` contains the reporting views. `qc` is reserved; the current validation scripts return result sets and do not persist QC tables.

World facts are rebuilt by combining the raw EU and non-EU components. Partner facts are rebuilt from raw observations using the governed 3,600-row panel. Formatted upstream fact CSVs serve as reference/coverage inputs; rounded unit-value strings are not the analytical calculation basis. Core calculated monthly measures are stored at the declared six-decimal precision; period calculations sum value and mass again.

The bridge has one row per supplier–site–product relationship. The site master has one row per official Site ID. Supplier IDs, resolved supplier groups and parent/analytical label families are distinct concepts. This package reports concentration by source supplier and resolved group; it does not reproduce every parent-family or external-only concentration measure from WP003.

### Periods and units

- `FULL_YEAR`: complete calendar years 2019–2025, twelve months each.
- `H1`: January–June 2019–2026, six months each.
- The two period types overlap. Never sum them together. Do not treat H1 2026 as a full year.
- Weighted unit value is `SUM(import_value_gbp) / SUM(net_mass_kg)`, in GBP/kg, with a null result for a zero denominator.
- `world_import_share`, `reported_world_import_share`, `retained_world_import_share`, `channel_relationship_share` and `channel_site_reach_share` are fractions. Multiply by 100 for percentage display.
- Growth-view fields ending in `_pct` are already percentages. Fields ending in `_pp` are percentage-point changes.
- `relationship_hhi` is the sum of squared relationship shares on a **0–1 scale**. Multiply by 10,000 only when comparing with the upstream HHI-points convention. Compare the same population and supplier basis as well as the same scale.
- `COMPARABLE` in the reported growth view indicates availability of a prior period and a nonzero prior value. It does not certify methodological comparability or the absence of review flags.

### REVIEW sensitivity

The monthly diagnostic uses the full-series CN8-partner median, or the CN8 median for World. A ratio below 0.40 or above 2.50 is labelled `REVIEW`. The flag does not establish an error. Reported values remain the baseline.

Period sensitivity retains a month only if neither its partner observation nor its matching World observation is flagged. Partner and World measures use the same retained months. The 12 `NO_API_RECORD` panel placeholders keep their governed zero-value treatment and explicit status; they are not confirmed observations of zero trade.

Growth sensitivity retains a calendar-month pair only when both years meet the exclusion rule. An excluded March in either year removes March from both sides of that comparison. Retained totals are not annualised. Countries may retain different months, so sensitivity results do not automatically support a like-for-like ranking across countries.

### Supplier/site interpretation

- Relationship and site counts are footprint measures, not spend, available capacity or procurement allocation.
- Whole-site employees cover the listed workforce across customers, not workers dedicated to NEXT. Aggregate employees once per Site ID; missing counts remain null.
- A sourcing-channel link does not establish site ownership. Only the explicitly documented ownership classification supports the confirmed-owned count.
- Distinct suppliers/groups are not additive across country-product rows. Sites may also overlap across sourcing channels.
- Official Site IDs 20221 and 24006 remain separate. Their descriptive physical-review flags are normalised to 1 only under the documented closed-review condition. A physical-review flag can refer to a closed review.
- APPAREL/HOME labels do not assign individual sites to the selected CN8 products or prove garment capability. Audit annotations are evidence-review inputs, not automatic compliance failures.

## File integrity

`checksums.sha256` lists a SHA-256 hash and relative path for each other public package file. Compare a file's recalculated hash with its listed value to check that its contents match this snapshot. A mismatch means the bytes differ; it does not identify the cause or establish that the file is wrong.

Hashes verify file contents, not SQL correctness, authorship or analytical accuracy. Regenerate the manifest after intentional edits, including comment or documentation changes, and after adding, removing or renaming files. The manifest excludes itself. It is optional integrity documentation and is not needed to execute the SQL.
