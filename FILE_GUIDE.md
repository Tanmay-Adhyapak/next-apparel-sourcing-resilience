# File guide

The [main README](README.md) is the project entry point. The report PDF offers the quickest complete view; the remaining files provide inspectable technical and analytical evidence.

| Location | Contents | Suggested use |
|---|---|---|
| `power-bi/` | Final PBIX, four-page PDF, theme, report README, six PNGs, DAX, Power Query and methodology | Explore the result and model |
| `excel/` | Seven final analytical workbooks and a workbook guide | Inspect assumptions, calculations and evidence |
| `sql/` | 12 numbered build/validation scripts, optional findings queries, run guide and QC summary | Inspect or reproduce the PostgreSQL evidence base |
| `sql/Inputs/` | 14 fixed CSV staging inputs | Reproduce the archived SQL build |
| `sql/Exports/` | Ten validated analytical CSV outputs | Inspect full-precision SQL results |
| `sql/Validation_Run/` | Selected rebuild checkpoints and export comparison | Inspect the recorded verification |
| `docs/` | Final WP010 recommendation, research question/scope, reporting boundaries and source register | Read decision conditions and evidence provenance |
| `checksums.sha256` | File hashes for this publication snapshot | Optional file-integrity check |

## Work package index

**WP = work package**, a stage of this project. The scope and historical-disclosure stages are represented by the public evidence notes.

| Code | Subject | Published location |
|---|---|---|
| WP001–WP002 | Data sufficiency, historical sourcing disclosures and boundary changes | [Research question and scope](docs/Research_Question_and_Scope.md); [reporting boundaries](docs/governance/Reporting_Boundaries.md) |
| WP003 | Supplier footprint and entity resolution | `excel/` supplier-footprint workbook |
| WP004 | Category screening, tariff/origin assumptions and causal-design assessment | `excel/` category/tariff workbook |
| WP005 | Monthly HMRC trade evidence | `excel/` monthly-trade workbook; `sql/Inputs/` |
| WP006 | PostgreSQL transformation, validation and analytical exports | `sql/` |
| WP007 | Mandatory responsible-sourcing gates | `excel/` gates workbook |
| WP008 | Baseline cost and sourcing scenarios | `excel/` scenario workbook |
| WP009 | 26-case sensitivity and break-even analysis | `excel/` sensitivity workbook |
| WP010 | Final recommendation and commercial conditions | `docs/` decision document; `excel/` evidence workbook |
| WP011 | Power BI report and technical model | `power-bi/` |

RS01–RS08 are responsible-sourcing gates; ST01–ST04 are stop rules. Decision (D), question (Q), hypothesis (H) and limitation (L) codes referenced in the workbooks are explained in the scope record.

## Open and refresh

- Open the report PDF for a static view. The four default page images are 1280 × 720; the two filter-comparison figures are 1280 × 1650.
- Open the PBIX without refresh for the saved interactive report. Source paths are needed only for refresh; instructions are in the report's technical reference.
- Open the Excel files to inspect their saved state. Use copies for experiments.
- Follow `sql/RUN_GUIDE.md` only if rebuilding the PostgreSQL database. Reading the outputs does not require a database.

## Snapshot boundaries

WP010 v1.1 is the final recommendation. Earlier workbook outputs remain supporting analysis and may represent baseline cases rather than the final preferred mix. The original third-party PDFs and raw API responses are cited through the evidence registers; this repository includes the fixed analytical inputs needed for the SQL build, not the entire source archive.

Workbook source fingerprints identify the original analytical inputs; `checksums.sha256` identifies the files in this publication package. A changed publication filename or explanatory note does not imply a changed analytical result.
