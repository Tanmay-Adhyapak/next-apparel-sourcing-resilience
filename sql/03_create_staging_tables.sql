-- Create text staging tables for the seven WP005 CSV inputs.
-- Import the mapped Inputs/ files before running script 04.

CREATE TABLE staging.wp005_dim_commodity (
    cn8_code TEXT,
    hs2_code TEXT,
    hs4_code TEXT,
    hs6_code TEXT,
    description TEXT,
    construction TEXT,
    fibre TEXT,
    basket_role TEXT,
    inclusion_status TEXT
);

CREATE TABLE staging.wp005_dim_partner_country(
    partner_country_id TEXT,
    country_code_numeric TEXT,
    partner_country_iso2 TEXT,
    partner_country_name TEXT,
    hmrc_flow_type_id TEXT,
    scope_status TEXT,
    geographical_basis TEXT
);

CREATE TABLE staging.wp005_dim_month(
    month_id TEXT,
    month_date TEXT,
    calendar_year TEXT,
    month_number TEXT,
    month_name TEXT,
    calendar_quarter TEXT,
    half_year TEXT,
    complete_calendar_year_flag TEXT,
    ytd_2026_flag TEXT,
    like_for_like_h1_flag TEXT
);

CREATE TABLE staging.wp005_raw_partner_monthly(
    source_query_id TEXT,
    source_record_no TEXT,
    month_id TEXT,
    commodity_id TEXT,
    country_id TEXT,
    flow_type_id TEXT,
    suppression_index TEXT,
    supp_unit TEXT,
    net_mass TEXT,
    value_gbp TEXT,
    source_file TEXT
);

CREATE TABLE staging.wp005_raw_world_monthly(
    source_query_id TEXT,
    source_record_no TEXT,
    month_id TEXT,
    commodity_id TEXT,
    flow_type_id TEXT,
    suppression_index TEXT,
    supp_unit TEXT,
    net_mass TEXT,
    value_gbp TEXT,
    source_file TEXT
    );

CREATE TABLE staging.wp005_fct_partner_monthly (
    monthly_import_key TEXT,
    month_date TEXT,
    month_id TEXT,
    calendar_year TEXT,
    calendar_month TEXT,
    cn8_code TEXT,
    hs4_code TEXT,
    partner_country_id TEXT,
    partner_country_iso2 TEXT,
    partner_country_name TEXT,
    flow TEXT,
    flow_type_id TEXT,
    api_row_present_flag TEXT,
    record_status TEXT,
    suppression_index_list TEXT,
    suppression_flag TEXT,
    import_value_gbp TEXT,
    net_mass_kg TEXT,
    supplementary_quantity TEXT,
    mass_status TEXT,
    unit_value_gbp_per_kg TEXT,
    world_import_value_gbp TEXT,
    partner_value_share TEXT,
    source_query_id TEXT,
    source_file TEXT,
    reference_median_unit_value_gbp_per_kg TEXT,
    unit_value_ratio_to_reference_median TEXT,
    unit_value_review_flag_2_5x TEXT
);

CREATE TABLE staging.wp005_fct_world_monthly (
    world_monthly_key TEXT,
    month_date TEXT,
    month_id TEXT,
    calendar_year TEXT,
    calendar_month TEXT,
    cn8_code TEXT,
    hs4_code TEXT,
    eu_import_value_gbp TEXT,
    non_eu_import_value_gbp TEXT,
    world_import_value_gbp TEXT,
    eu_net_mass_kg TEXT,
    non_eu_net_mass_kg TEXT,
    world_net_mass_kg TEXT,
    eu_supplementary_quantity TEXT,
    non_eu_supplementary_quantity TEXT,
    world_supplementary_quantity TEXT,
    unit_value_gbp_per_kg TEXT,
    eu_suppression_index_list TEXT,
    non_eu_suppression_index_list TEXT,
    suppression_flag TEXT,
    source_query_id TEXT,
    source_file TEXT,
    reference_median_unit_value_gbp_per_kg TEXT,
    unit_value_ratio_to_reference_median TEXT,
    unit_value_review_flag_2_5x TEXT
);
