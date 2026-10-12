# NEXT sourcing resilience — WP006 SQL core

**A PostgreSQL evidence base for evaluating NEXT's sourcing resilience.** This work package combines the disclosed supplier footprint with UK import data to measure market trends, supplier concentration, shared sites and the sensitivity of trade results to unusual monthly observations.

WP006 supplies evidence for later responsible-sourcing and commercial scenarios. It does not determine a final sourcing allocation or landed-cost recommendation.

WP means **work package**, a named project stage. WP003 is the supplier-footprint evidence, WP005 the monthly-trade evidence and WP006 this PostgreSQL build. The [project file guide](../FILE_GUIDE.md) maps the remaining codes.

## Data and scope

| Source | Coverage |
| --- | --- |
| WP003 supplier extracts | February 2026 Tier 1 disclosure: 672 supplier IDs, 1,478 official Site IDs and 2,097 supplier–site–product relationships |
| WP005 HMRC extracts | January 2019–June 2026: 90 months, ten partners and separate World totals |
| Commodity basket | CN8 61091000, 61103099, 62044300 and 62052000; one inactive reserve retained in the dimension |
| Delivery | 12 numbered SQL scripts, 14 staging tables, 14 core tables, 11 analytics views and 10 CSV exports |

The ten partners are Bangladesh, Cambodia, China, India, Morocco, Myanmar, Pakistan, Sri Lanka, Turkey and Vietnam. The inputs are fixed, governed extracts; upstream source registers and review workbooks hold the wider evidence history.

## SQL approach

Text staging tables preserve the input fields. Typed core tables add keys, constraints and traceability. Analytics views calculate period totals, weighted unit values, World shares, year-on-year changes, supplier/site metrics and REVIEW-exclusion sensitivity. Validation checks reconcile the stages and analytical outputs.

The implementation uses CTEs, joins, conditional aggregation, window functions, median calculations and set comparisons. The `qc` schema is reserved; validation currently returns result sets rather than storing QC tables.

## Main findings

- **Bangladesh gained share in the four-code UK import basket:** its share by import value rose from 25.3% in 2022 to 28.0% in 2025. Over the same period, China rose from 14.6% to 15.4%, India stayed near 6.6%, and Turkey fell from 9.3% to 7.5%. Each share divides the country’s summed four-code value by the corresponding World total; it is not an average of code-level shares or a NEXT procurement share.

- **Supplier resolution changes measured sharing:** 338 sites are shared across source supplier IDs, compared with 329 across resolved supplier groups.
- **Channel reach differs from ownership:** NEXT sourcing-labelled relationships reach 383 sites; only three sites carry the documented confirmed NEXT-owned classification.
- **Sensitivity affects four of forty H1 2026 comparisons:** no World-share change reverses direction, but magnitudes change. Turkey's CN8 61103099 import-value growth changes from −19.78% reported to −26.18% using retained matched months.

These findings support further investigation; share-direction stability does not establish stable country rankings or a sourcing recommendation.

## Interpretation rules

- The baseline is NEXT's disclosed footprint. Its disclosed 73% top-three sourcing-map share has a mixed brand/tier boundary and is not a verified own-brand apparel procurement allocation.
- HMRC partner geography is dispatch/partner-country basis, not proof of manufacturing origin. UK trade is a market benchmark, not NEXT procurement; GBP/kg unit values are not supplier quotes.
- `FULL_YEAR` covers 2019–2025; `H1` covers January–June 2019–2026. These periods overlap and must not be summed. Comparisons spanning the 2022 EU collection-method change require the upstream caveat.
- Reported values remain the baseline. Period sensitivity removes matching partner and World months together; growth sensitivity retains a calendar-month pair only when both years qualify. Countries may retain different months.
- Relationship/site counts measure footprint, not spend or available capacity. Whole-site employees are not NEXT-dedicated workers. APPAREL/HOME labels do not prove CN8-level factory capability.
- Shares and relationship HHI are stored as fractions; `_pct` fields are percentages and `_pp` fields are percentage-point changes. HHI uses a 0–1 scale; multiply by 10,000 to express HHI points.

## Explore the package

| Location | Purpose |
| --- | --- |
| [Exports/](Exports/) | Ten analytical datasets, ready for downstream analysis |
| [Analysis/selected_findings.sql](Analysis/selected_findings.sql) | Three queries illustrating share changes, concentration and sensitivity |
| [RUN_GUIDE.md](RUN_GUIDE.md) | Execution order, input mapping, export settings and calculation reference |
| [QC_SUMMARY.md](QC_SUMMARY.md) | Check coverage, snapshot totals, export inventory and verification limits |
| [Validation_Run/](Validation_Run/) | Saved rebuild checkpoints and exact export comparison |
| [Inputs/](Inputs/) and numbered SQL files | Fixed extracts and build/validation/export code |

`checksums.sha256` records the package file hashes. Creation and loading run once per fresh database; validation and analytical SELECT queries are reusable on the populated database.

## Verification and next stage

A manual rebuild from an empty PostgreSQL database completed on 16 September 2026. Staging, core and analytics validation passed; all ten rebuilt exports are byte-for-byte identical to the previously reconciled outputs. Selected CSV checkpoints and the export comparison are retained in `Validation_Run/`. Remaining validation results are recorded from manual run confirmations; no consolidated execution transcript is included. See the QC summary for coverage and limits.

The outputs now support WP007 responsible-sourcing gates and subsequent commercial scenarios. Final recommendations require origin, capability and commercial evidence beyond this SQL work package.
