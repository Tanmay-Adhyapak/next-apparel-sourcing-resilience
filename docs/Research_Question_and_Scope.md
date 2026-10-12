# Research question and scope

## Original research question

> Should NEXT rebalance its disclosed sourcing footprint following the 2026 changes in relative UK trade treatment-and, for the selected apparel category, which country alternatives are most attractive, by how much, and under what conditions?

This is the original research question for the project. The discussion below records the scope decisions and limitations needed to interpret the published analysis. Decision codes link the analytical choices to the evidence below.

## Why the company-wide question cannot be answered from public data

The published sourcing series changes measurement basis, brand coverage and supplier-tier coverage. The [reporting-boundary evidence](governance/Reporting_Boundaries.md) identifies each disclosure and its page or section. The [source register](governance/Source_Register.md) provides the corresponding documents and links.

The 2026 top-three share of 73% relates to a mixed brand and supplier-tier sourcing-map boundary. It must not be labelled NEXT own-brand apparel procurement. Factory lists establish disclosed presence, not country procurement value. These limits prevent a defensible NEXT apparel country-value allocation baseline from public data.

Non-comparability is the finding. It does not establish that an apparent change was entirely a reporting artefact or that the underlying sourcing footprint was unchanged.

## Selected analytical decisions

| ID | Decision and its consequence | Published evidence |
|---|---|---|
| D008 | Responsible-sourcing requirements are minimum gates. Lower cost cannot offset mandatory failure. | [WP007](../excel/NEXT_WP007_Responsible_Sourcing_Gates_v1.0.xlsx), Gate_Matrix and Evidence; NEXT Modern Slavery and Code of Practice sources in the source register. |
| D010 | Use NEXT's disclosed footprint as company context and UK apparel trade as an external category benchmark. Allocations remain illustrative. | Reporting-boundary evidence; [WP003 footprint](../excel/NEXT_WP003_Tier1_Supplier_Footprint_2026.xlsx); [WP010 recommendation](../excel/NEXT_WP010_Recommendation_Evidence_v1.1.xlsx). |
| D012 | Preserve the 672 source supplier IDs. Separate declared buying-channel labels, 661 review-resolved supplier groups and parent/label-family roll-ups. Analytical families do not establish legal ownership or spend concentration. | WP003 README, supplier_entity_map and supplier_resolution_map. |
| D013 | Lock the four tested CN8 categories; 62063000 remains an inactive reserve. Conclusions remain category-specific. | WP004 Scope_Lock and Commodity_Shortlist. |
| D014 | Treat HMRC import statistical value as the border-value proxy, apply duty once and avoid adding international freight twice. | WP004 Scope_Lock and HMRC valuation evidence; WP008 Cost_Model. |
| D015 | Fix monthly trade at January 2019–June 2026 for ten origins plus World, keeping full years and 2026 year-to-date separate. | WP004 Scope_Lock; WP005 Scope_Contract and the SQL inputs. |
| D016 | In the archived scenarios, preferential zero rates require origin eligibility and valid proof; retain non-qualifying tariff cases. | WP004 Scope_Lock, Tariff_Matrix and Origin_Rules; WP007 gates. |
| D017 | Preserve the archived HMRC Q0–Q8 and tariff T01–T11 evidence cut. Use inclusive HS2 totals for market denominators and true CN8 observations for exact product analysis. | WP004 Scope_Lock, evidence and reconciliation sheets. |
| D020 | Myanmar remains excluded from actionable additional allocation. Thirteen listed sites and zero annotations do not establish clearance; enhanced requirements apply. Pending evidence is not confirmed failure. | WP007 Gate_Matrix and Site_Review; WP004 Tariff_Matrix and Origin_Rules. Reconsider only on dated site/product evidence and a separate eligibility decision. |
| D021 | Use FY2025 ten-country import-mass shares as the illustrative baseline. Test receiver mixes, growth constraints and category weights. The default mix is India 50%, Turkey 25%, Vietnam 25%, with a 35% recipient ceiling, 10 pp maximum addition and 3× baseline-share cap. | [WP008](../excel/NEXT_WP008_Cost_and_Sourcing_Scenarios_v1.1.xlsx), Assumptions and Cost_Model; [WP009](../excel/NEXT_WP009_Sensitivity_and_Break_Even_v1.1.xlsx), Assumptions and Sensitivity. These are test assumptions, not actual allocations or verified capacity. |
| D023 | Retain the original question and present the Data Sufficiency Gate as an evidenced finding. Keep company footprint, trade benchmarks and scenario populations distinct, and retain the causal-design limitation. | This scope record, reporting-boundary evidence, WP004 Natural_Experiment and final WP010 v1.1. |

## Analytical criteria and limitations referenced by the workbooks

| Reference | Meaning |
|---|---|
| Q0.1, Q1.1 and Q1.3 | The Data Sufficiency Gate and historical exposure questions: without comparable disclosure boundaries and apparel procurement values, do not estimate company allocation changes from the series. |
| Q2.6 | Where unobservable operational assumptions dominate, use break-even thresholds and relative cost indices rather than presenting a verified landed-cost estimate. |
| Q4.6 | Apply the eight mandatory responsible-sourcing gates. Insufficient evidence remains Pending; any confirmed mandatory failure excludes the candidate regardless of cost advantage. See WP007. |
| Q5.2 | Test illustrative requests of 5, 10 and 15 percentage points, constrained by caps and eligibility. The requests are not orders or forecasts. |
| Q5.4 | Test the basket-level cost proposition across modelling choices. Savings in 10/26 equal-weight cases and 17/26 value-weight cases, with seven sign disagreements, do not support a general basket-saving claim. |
| H5 | The hypothesis that China's synthetic-category position is economically hardest to displace is challenged by the scenario costs. Product, quality and capability equivalence remain unproven, so the full support/rejection criteria are not met. See WP010 Hypotheses and WP009 Sensitivity. |
| L007 | HMRC import unit values reflect external market-level product mix and border-value conventions, not NEXT supplier quotes or purchase prices. |
| L008 | Trade observations end in June 2026. They cannot establish a post-change response to the later date assumed in the archived CETA scenarios. |
| L009 | UK-wide comparisons crossing the 2022 EU import collection-method change need caution. Use 2022 onward as the primary comparable market-wide period. |
| L024 | Scenarios transfer share only from China. Bangladesh is 58.6% of the cotton T-shirt baseline and 54.7% of shirts; the tested lever does not address that dominant exposure. Other donor proposals are outside scope. |

## What the failed causal design establishes

WP004 Natural_Experiment compares H1 2026 with H1 2025 chapter-level mass. India's HS62-minus-HS61 growth difference is +17.4 percentage points. Cambodia's +13.5 pp and Pakistan's +43.7 pp placebo differences undermine attributing India's result to the chapter-specific treatment. Vietnam's +47.5 pp is a qualified comparison because some lines continued UKVFTA staging.

**The placebo evidence undermines the causal identification strategy. The tariff effect remains unestimated by this design; it was not shown to be zero.** The recommendation therefore relies on explicit benchmark scenarios and conditions rather than a claimed causal tariff estimate. Source: [WP004 Natural_Experiment](../excel/NEXT_WP004_Category_Tariff_Lock.xlsx) and the [final decision document](NEXT_WP010_Decision_Recommendation_v1.1.docx).

## How to read the identifiers

WP means **work package**, a named stage of this project. Q identifies an analytical question, H a hypothesis, D an analytical decision, L a limitation, RS a responsible-sourcing gate and ST a stop rule. These labels connect evidence across files. The [file guide](../FILE_GUIDE.md) maps every published work package to its deliverable.
