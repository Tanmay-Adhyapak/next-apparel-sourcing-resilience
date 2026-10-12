# Excel evidence

**WP means work package**, a named project stage. Start with **WP010** for the decision or **WP009** for the scenario engine and saved sensitivity cases. Earlier workbooks explain the evidence chain; their intermediate findings do not supersede WP010 v1.1.

| Workbook | Purpose | Useful starting sheets |
|---|---|---|
| [WP003 — Supplier footprint](NEXT_WP003_Tier1_Supplier_Footprint_2026.xlsx) | Standardised Tier 1 sites, supplier relationships and resolution evidence | README; site_master; supplier_site_bridge; qc_checks |
| [WP004 — Category and tariff lock](NEXT_WP004_Category_Tariff_Lock.xlsx) | Category selection, archived tariff/origin assumptions and causal-design limitations | README; Tariff_Matrix; Natural_Experiment; QC_Checks |
| [WP005 — Monthly trade](NEXT_WP005_HMRC_Monthly_Trade_Core4_2019-01_to_2026-06.xlsx) | Governed HMRC monthly panel and World denominator | README; Scope_Contract; Reconciliation; QC_Checks |
| [WP007 — Responsible-sourcing gates](NEXT_WP007_Responsible_Sourcing_Gates_v1.0.xlsx) | Mandatory gates, Pending annotations and Myanmar exclusion | Gate_Matrix; Site_Review; Evidence; QC_Checks |
| [WP008 — Cost and sourcing scenarios](NEXT_WP008_Cost_and_Sourcing_Scenarios_v1.1.xlsx) | Baseline scenario design, feasibility and gate assumptions | Summary; Assumptions; Cost_Model; Candidate_Gates |
| [WP009 — Sensitivity and break-even](NEXT_WP009_Sensitivity_and_Break_Even_v1.1.xlsx) | 26 saved cases, category outcomes, headroom and sensitivity | Summary; Sensitivity; Break_Even; QC_Checks; ReadMe |
| [WP010 — Final recommendation evidence](NEXT_WP010_Recommendation_Evidence_v1.1.xlsx) | Final category decisions and proceed/stop/reopen conditions | Recommendation; Category_Decisions; Implementation; Evidence |

These workbooks retain the analytical snapshot, formulas and saved results. The [scope record](../docs/Research_Question_and_Scope.md) defines the decision and question codes used in their notes; the [source register](../docs/governance/Source_Register.md) lists external evidence.

Use a separate working copy to change assumptions. WP009's saved scenario ensemble does not automatically regenerate when an input changes; follow its ReadMe and refresh all affected saved results before using a changed analysis. Opening these workbooks is not a live-data refresh.

The Power BI report reads saved blocks in WP009 and WP010. Their worksheet names and analytical row positions are retained. Point the report's two workbook sources to the files in this folder only if refreshing is needed.
