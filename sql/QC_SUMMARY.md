# WP006 quality-control summary

QC summary date: **16 September 2026**. Counts below describe the fixed WP003/WP005 snapshot; they are not universal expectations for future refreshes.

## Verification status

| Check | Recorded result | Evidence and limit |
| --- | --- | --- |
| Staging and core validation | Passed in the manual rebuild | Saved totals, supplier counts and control checkpoints; remaining checks recorded from manual run confirmations. |
| Analytics validation | All 12 blocks in script 11 passed in the manual rebuild | Eleven view counts and seven consistency checks saved; remaining zero-discrepancy results recorded from manual run confirmations. |
| Source-to-export reconciliation | All ten CSVs reconciled to the source extracts; no discrepancies at the stated precision | Checks the fixed extracts and exported calculations, not the underlying accuracy of external source data. |
| Script inventory | Fourteen core inserts, fourteen core table definitions, eleven view definitions and ten export queries | Static inventory check; not an execution test. |
| SQL preservation | Retained executable statements match the working-script versions before formatting | Token comparison checks preservation; it does not establish a PostgreSQL execution result. |
| CSV preservation | Included inputs and final exports retain the source file contents | Byte comparison checks file preservation, not analytical accuracy. |
| Fresh database rebuild | **Completed manually, 16 September 2026** | Empty-database environment checkpoint, staged imports, validation results and ten rebuilt exports. No consolidated execution transcript is included. |
| Rebuilt export comparison | **10 of 10 byte-for-byte matches** | Direct byte comparison and matching SHA-256 hashes against the previously verified exports; no numerical tolerance was needed. |

Read-only validation and analytical queries can be rerun against the working database. For reproduction in a separate fresh database, follow the staging-import pauses and validation gates in [RUN_GUIDE.md](RUN_GUIDE.md).

## Rebuild evidence

The rebuild used `next_sourcing_analytics` on PostgreSQL 18.1 (64-bit Windows). The initial checkpoint at 10:58:35 +0100 on 16 September 2026 records zero project schemas and zero user tables/views. Scripts 01–12 were then executed manually with the staging-import pauses and validation checks. This was an interactive run, not an unattended automated test.

The following files are retained in [Validation_Run/](Validation_Run/):

| File | Coverage and result |
| --- | --- |
| `00_environment.csv` | Database, server version, timestamp and empty starting state |
| `02_schema_verification.csv` | Four schemas: analytics, core, qc and staging |
| `04_partner_totals.csv` | Raw/reference partner totals agree: GBP 12,399,576,995 and 880,954,318 kg |
| `04_world_totals.csv` | Raw/reference World totals agree: GBP 19,382,615,221 and 1,133,076,866 kg |
| `06_supplier_staging_counts.csv` | Seven supplier staging row counts |
| `09_supplier_core_counts.csv` | Seven supplier core counts: PASS, zero differences |
| `09_supplier_site_controls.csv` | Eighteen supplier/site controls: PASS, zero differences |
| `09_core_inventory_controls.csv` | Twenty-four core inventory/control checks: PASS, zero differences |
| `09_world_fact_reconciliation.csv` | World facts recomputed from typed raw observations: two zero-discrepancy checks |
| `09_partner_fact_reconciliation.csv` | Partner facts recomputed from typed raw observations: two zero-discrepancy checks |
| `11_analytics_view_counts.csv` | Eleven view counts: PASS, zero differences |
| `11_analytics_consistency.csv` | Seven cross-view checks: zero discrepancies |
| `12_export_comparison.csv` | Ten rebuilt outputs: identical bytes, headers, rows and missing-value markers |

These are selected checkpoints, not a capture of every SQL statement or result. Other staging checks were recorded as passed; the remaining core and analytics discrepancy checks were confirmed as zero during the manual run. The export comparison establishes output reproducibility for this fixed snapshot; it does not certify external source accuracy or future refreshes.

## Core inventory

| Core table | Rows |
| --- | ---: |
| `dim_commodity` | 5 |
| `dim_partner_country` | 10 |
| `dim_month` | 90 |
| `raw_partner_monthly` | 3,588 |
| `raw_world_monthly` | 720 |
| `fct_hmrc_import_monthly` | 3,600 |
| `fct_hmrc_world_monthly` | 360 |
| `supplier_master` | 672 |
| `supplier_group_master` | 661 |
| `supplier_resolution_map` | 672 |
| `supplier_entity_map` | 672 |
| `site_master` | 1,478 |
| `raw_tier1_relationships` | 2,202 |
| `supplier_site_bridge` | 2,097 |

Script 09 has 18 numbered sections and 21 executable statements because sections 12 and 13 have subchecks. It checks full-field reconciliation, types, relationship integrity, pipe-separated raw-record lineage, source-rebuilt trade facts, governed reference rounding, complete panels and documented control totals.

Staging scripts 04 and 06 also contain informational queries. Interpret counts and distributions against the fixed input manifest; duplicate/orphan/unexpected-data queries should return no exceptions. The inactive reserve commodity and documented annotations are legitimate data, not errors to remove.

## Analytics validation coverage

| Script 11 block | Coverage | Recorded result |
| --- | --- | --- |
| 1 | All eleven view row counts | 11 PASS rows |
| 2 | Uniqueness at each view's grain | 11 zero counts |
| 3 | Reported-period keys and month coverage | 4 zero counts |
| 4 | Trade values, mass, weighted unit values, shares and diagnostics | 4 zero counts |
| 5 | Reported growth and first-year nulls using sequenced periods | 2 zero counts |
| 6 | Supplier footprint and channel metrics | 4 zero counts |
| 7 | HHI reconstruction and supplier-basis consistency | 2 zero counts |
| 8 | Site overlap and country-product profiles | 4 zero counts |
| 9 | Monthly sensitivity data/classifications | 2 zero counts |
| 10 | Period sensitivity metrics | 2 zero counts |
| 11 | Matched-month growth sensitivity | 2 zero counts |
| 12 | Cross-view consistency and unchanged results with no exclusions | 7 zero counts |

Block 5's `LAG` check uses preceding rows as preceding years only after the earlier coverage checks establish consecutive-year coverage for this snapshot. This assumption must be reconsidered if a future dataset has year gaps.

## Export verification

All filenames below are in `Exports/`. The rebuilt exports match these files byte-for-byte; `Validation_Run/12_export_comparison.csv` records both hashes. In the earlier source-to-export reconciliation, every exported field was checked, with exact comparisons for keys, labels, counts and summed measures and a numerical tolerance for calculated ratios. Missing and duplicate keys, column selections and sort order were also checked.

| CSV filename | Rows | Columns |
| --- | ---: | ---: |
| `NEXT_WP006_world_trade_period_reported.csv` | 60 | 13 |
| `NEXT_WP006_partner_trade_period_reported.csv` | 600 | 14 |
| `NEXT_WP006_partner_trade_period_growth_reported.csv` | 600 | 22 |
| `NEXT_WP006_supplier_country_product_footprint.csv` | 46 | 6 |
| `NEXT_WP006_supplier_country_product_concentration.csv` | 92 | 7 |
| `NEXT_WP006_site_supplier_overlap.csv` | 1,478 | 12 |
| `NEXT_WP006_supplier_channel_country_product_footprint.csv` | 60 | 11 |
| `NEXT_WP006_site_country_product_profile.csv` | 46 | 9 |
| `NEXT_WP006_partner_trade_period_review_sensitivity.csv` | 600 | 19 |
| `NEXT_WP006_partner_trade_period_growth_review_sensitivity.csv` | 520 | 18 |

The 3,600-row monthly sensitivity view is an intermediate object and has no separate standard CSV export. Reported growth includes 80 first-year rows with `NO_PRIOR_PERIOD` and 520 `COMPARABLE` rows. The reported-growth CSV contains 720 explicit `NULL` markers for unavailable first-year fields; missing values are not zeros.

### Precision

`1e-12` means 10 to the power of −12, or 0.000000000001. This is a selected numerical comparison tolerance, not an estimate calculated from the dataset or a business materiality threshold. A check flags an absolute difference greater than this limit; it does not round or alter the exported values.

- Source-to-export reconciliation checks allow an absolute difference of at most **1e-12** for derived ratios, unit values, percentage calculations and HHI. Counts, identifiers, classifications and summed measures are exact.
- SQL concentration validation also allows **1e-12**, because summing squared shares and dividing squared counts can differ in the last decimal places.
- Script 09's comparison with upstream *formatted reference CSVs* uses display-rounding tolerances: GBP/kg 0.005001; median/ratio 0.000051; share fraction 0.0000505. These do not apply to raw trade totals and are not business materiality thresholds.

## Documented controls and retained exceptions

| Control | Snapshot result |
| --- | ---: |
| Active CN8 codes | 4 |
| Missing-API panel placeholders | 12 |
| Partner monthly REVIEW rows | 37 |
| World monthly REVIEW rows | 2 |
| Monthly partner rows excluded by combined partner/World review | 57 |
| Monthly partner rows retained | 3,543 |
| Raw duplicate-flagged observations retained | 16 |
| Sites missing each employee-count measure | 11 |
| Responsible-sourcing review sites | 16 |
| Physical-review flags after documented normalisation | 10 |
| Shared sites, source-supplier basis | 338 |
| Shared sites, resolved-group basis | 329 |
| NEXT sourcing-labelled supplier IDs | 19 |
| NEXT sourcing-labelled relationships | 438 |
| NEXT sourcing-channel distinct sites | 383 |
| Confirmed NEXT-owned sites | 3 |
| Listed workers at those three sites | 2,888 |

The two World REVIEW observations are March and April 2019 for CN8 62052000. Each affects ten partner rows, producing twenty World-related monthly exclusions. None overlaps a partner REVIEW row in this snapshot: 37 + 20 = 57.

| Sensitivity control | FULL_YEAR | H1 |
| --- | ---: | ---: |
| Period rows | 280 | 320 |
| Period rows with exclusions | 32 | 21 |
| Excluded month observations within period rows | 52 | 36 |
| Minimum retained months | 8 | 3 |
| Growth comparison rows | 240 | 280 |
| Growth comparisons with exclusions | 43 | 29 |
| Excluded month pairs | 70 | 47 |
| Minimum retained month pairs | 8 | 3 |

FULL_YEAR and H1 overlap, so their exclusion counts must not be added as unique source exclusions. Among the forty H1 2026 growth comparisons, four are affected and no share-change direction reverses under this sensitivity. Country ranking stability is not established by that result.

The 1,478 sites split into 1,263 APPAREL and 215 HOME sites. Listed employee totals are 1,418,547 and 84,463 respectively, with employee data missing at eight APPAREL sites and three HOME sites. These are whole-site workforce counts.

NEXT-channel and external-channel site reach totals are 383 and 1,213. Their sum exceeds the overall site count because 118 sites appear under both channels. Each relationship belongs to one declared channel, so relationship totals still reconcile to 2,097.

## Use of the result

The checks support the integrity of the fixed SQL data pipeline and its exports. They do not establish available production capacity, supplier legal ownership beyond recorded evidence, preference eligibility, causality of tariff changes or the final sourcing recommendation. The interpretation limits in the README and the calculation reference in RUN_GUIDE.md remain part of the output contract.
