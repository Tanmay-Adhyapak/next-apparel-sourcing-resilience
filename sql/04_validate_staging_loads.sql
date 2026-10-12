-- Validate the imported WP005 staging data.
-- Counts and distributions describe the fixed snapshot; exception queries must be clear.

SELECT COUNT(*) AS actual_row_count
FROM staging.wp005_dim_commodity;

SELECT
    cn8_code,
    description,
    inclusion_status
FROM staging.wp005_dim_commodity
ORDER BY cn8_code ASC;

SELECT
    cn8_code,
    COUNT(*) AS row_count
FROM staging.wp005_dim_commodity
GROUP BY cn8_code
HAVING COUNT(*) >1;

SELECT COUNT(*) AS missing_required_field_count
FROM staging.wp005_dim_commodity
WHERE
    (cn8_code IS NULL OR TRIM(cn8_code) = '')
    OR (description IS NULL OR TRIM(description) = '')
    OR (inclusion_status IS NULL OR TRIM(inclusion_status) = '');

SELECT
    inclusion_status,
    COUNT(*) AS row_count
FROM staging.wp005_dim_commodity
GROUP BY inclusion_status
ORDER BY inclusion_status;

SELECT
    cn8_code,
    description,
    inclusion_status
FROM staging.wp005_dim_commodity
WHERE inclusion_status <> 'Core';

SELECT
    'wp005_dim_partner_country' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp005_dim_partner_country

UNION ALL

SELECT
    'wp005_dim_month' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp005_dim_month;

SELECT
    'partner_country_id' AS key_name,
    partner_country_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp005_dim_partner_country
GROUP BY partner_country_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'month_id' AS key_name,
    month_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp005_dim_month
GROUP BY month_id
HAVING COUNT(*) > 1;

SELECT
    'wp005_dim_partner_country' AS table_name,
    COUNT(*) AS missing_required_field_count
FROM staging.wp005_dim_partner_country
WHERE
    (partner_country_id IS NULL OR TRIM(partner_country_id) = '')
    OR (country_code_numeric IS NULL OR TRIM(country_code_numeric) = '')
    OR (partner_country_iso2 IS NULL OR TRIM(partner_country_iso2) = '')
    OR (partner_country_name IS NULL OR TRIM(partner_country_name) = '')
    OR (hmrc_flow_type_id IS NULL OR TRIM(hmrc_flow_type_id) = '')
    OR (scope_status IS NULL OR TRIM(scope_status) = '')
    OR (geographical_basis IS NULL OR TRIM(geographical_basis) = '')

UNION ALL

SELECT
    'wp005_dim_month' AS table_name,
    COUNT(*) AS missing_required_field_count
FROM staging.wp005_dim_month
WHERE
    (month_id IS NULL OR TRIM(month_id) = '')
    OR (month_date IS NULL OR TRIM(month_date) = '')
    OR (calendar_year IS NULL OR TRIM(calendar_year) = '')
    OR (month_number IS NULL OR TRIM(month_number) = '')
    OR (month_name IS NULL OR TRIM(month_name) = '')
    OR (calendar_quarter IS NULL OR TRIM(calendar_quarter) = '')
    OR (half_year IS NULL OR TRIM(half_year) = '')
    OR (complete_calendar_year_flag IS NULL OR TRIM(complete_calendar_year_flag) = '')
    OR (ytd_2026_flag IS NULL OR TRIM(ytd_2026_flag) = '')
    OR (like_for_like_h1_flag IS NULL OR TRIM(like_for_like_h1_flag) = '');

SELECT
    partner_country_id,
    country_code_numeric,
    partner_country_iso2,
    partner_country_name,
    hmrc_flow_type_id
FROM staging.wp005_dim_partner_country
ORDER BY partner_country_iso2;

SELECT
    COUNT(*) AS actual_row_count,
    COUNT(DISTINCT month_id) AS distinct_month_count,
    MIN(month_id) AS first_month_id,
    MAX(month_id) AS last_month_id,
    MIN(month_date) AS first_month_date,
    MAX(month_date) AS last_month_date
FROM staging.wp005_dim_month;

SELECT
    'wp005_raw_partner_monthly' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp005_raw_partner_monthly

UNION ALL

SELECT
    'wp005_raw_world_monthly' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp005_raw_world_monthly;

SELECT
    'wp005_raw_partner_monthly' AS table_name,
    source_query_id,
    source_record_no,
    COUNT(*) AS row_count
FROM staging.wp005_raw_partner_monthly
GROUP BY
    source_query_id,
    source_record_no
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'wp005_raw_world_monthly' AS table_name,
    source_query_id,
    source_record_no,
    COUNT(*) AS row_count
FROM staging.wp005_raw_world_monthly
GROUP BY
    source_query_id,
    source_record_no
HAVING COUNT(*) > 1;

SELECT
    'partner' AS dataset_name,
    source_query_id,
    flow_type_id,
    COUNT(*) AS row_count
FROM staging.wp005_raw_partner_monthly
GROUP BY
    source_query_id,
    flow_type_id

UNION ALL

SELECT
    'world' AS dataset_name,
    source_query_id,
    flow_type_id,
    COUNT(*) AS row_count
FROM staging.wp005_raw_world_monthly
GROUP BY
    source_query_id,
    flow_type_id

ORDER BY
    source_query_id,
    flow_type_id;

SELECT
    COUNT(*) AS orphan_row_count
FROM staging.wp005_raw_partner_monthly AS raw
LEFT JOIN staging.wp005_dim_commodity AS commodity
    ON raw.commodity_id = commodity.cn8_code
LEFT JOIN staging.wp005_dim_partner_country AS country
    ON raw.country_id = country.partner_country_id
LEFT JOIN staging.wp005_dim_month AS month_dim
    ON raw.month_id = month_dim.month_id
WHERE
    commodity.cn8_code IS NULL
    OR country.partner_country_id IS NULL
    OR month_dim.month_id IS NULL;

SELECT
    COUNT(*) AS orphan_row_count
FROM staging.wp005_raw_world_monthly AS raw
LEFT JOIN staging.wp005_dim_commodity AS commodity
    ON raw.commodity_id = commodity.cn8_code
LEFT JOIN staging.wp005_dim_month AS month_dim
    ON raw.month_id = month_dim.month_id
WHERE
    commodity.cn8_code IS NULL
    OR month_dim.month_id IS NULL;

SELECT
    'partner' AS dataset_name,
    COUNT(*) AS missing_measure_or_lineage_count
FROM staging.wp005_raw_partner_monthly
WHERE
    (suppression_index IS NULL OR TRIM(suppression_index) = '')
    OR (supp_unit IS NULL OR TRIM(supp_unit) = '')
    OR (net_mass IS NULL OR TRIM(net_mass) = '')
    OR (value_gbp IS NULL OR TRIM(value_gbp) = '')
    OR (source_file IS NULL OR TRIM(source_file) = '')

UNION ALL

SELECT
    'world' AS dataset_name,
    COUNT(*) AS missing_measure_or_lineage_count
FROM staging.wp005_raw_world_monthly
WHERE
    (suppression_index IS NULL OR TRIM(suppression_index) = '')
    OR (supp_unit IS NULL OR TRIM(supp_unit) = '')
    OR (net_mass IS NULL OR TRIM(net_mass) = '')
    OR (value_gbp IS NULL OR TRIM(value_gbp) = '')
    OR (source_file IS NULL OR TRIM(source_file) = '');

SELECT
    'wp005_fct_partner_monthly' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp005_fct_partner_monthly

UNION ALL

SELECT
    'wp005_fct_world_monthly' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp005_fct_world_monthly;

SELECT
    'partner' AS dataset_name,
    monthly_import_key AS duplicate_key,
    COUNT(*) AS row_count
FROM staging.wp005_fct_partner_monthly
GROUP BY monthly_import_key
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'world' AS dataset_name,
    world_monthly_key AS duplicate_key,
    COUNT(*) AS row_count
FROM staging.wp005_fct_world_monthly
GROUP BY world_monthly_key
HAVING COUNT(*) > 1;

SELECT
    'partner' AS dataset_name,
    COUNT(*) AS missing_key_count
FROM staging.wp005_fct_partner_monthly
WHERE
    monthly_import_key IS NULL
    OR TRIM(monthly_import_key) = ''

UNION ALL

SELECT
    'world' AS dataset_name,
    COUNT(*) AS missing_key_count
FROM staging.wp005_fct_world_monthly
WHERE
    world_monthly_key IS NULL
    OR TRIM(world_monthly_key) = '';

SELECT
    api_row_present_flag,
    record_status,
    COUNT(*) AS row_count
FROM staging.wp005_fct_partner_monthly
GROUP BY
    api_row_present_flag,
    record_status
ORDER BY
    api_row_present_flag,
    record_status;

SELECT
    'partner' AS dataset_name,
    unit_value_review_flag_2_5x AS review_status,
    COUNT(*) AS row_count
FROM staging.wp005_fct_partner_monthly
GROUP BY unit_value_review_flag_2_5x

UNION ALL

SELECT
    'world' AS dataset_name,
    unit_value_review_flag_2_5x AS review_status,
    COUNT(*) AS row_count
FROM staging.wp005_fct_world_monthly
GROUP BY unit_value_review_flag_2_5x

ORDER BY
    dataset_name,
    review_status;

SELECT
    'raw_partner' AS data_layer,
    SUM(CAST(REPLACE(value_gbp, ',', '') AS NUMERIC)) AS total_value_gbp,
    SUM(CAST(REPLACE(net_mass, ',', '') AS NUMERIC)) AS total_net_mass_kg
FROM staging.wp005_raw_partner_monthly

UNION ALL

SELECT
    'reference_partner' AS data_layer,
    SUM(CAST(REPLACE(import_value_gbp, ',', '') AS NUMERIC)) AS total_value_gbp,
    SUM(CAST(REPLACE(net_mass_kg, ',', '') AS NUMERIC)) AS total_net_mass_kg
FROM staging.wp005_fct_partner_monthly;

SELECT
    'raw_world' AS data_layer,
    SUM(CAST(REPLACE(value_gbp, ',', '') AS NUMERIC)) AS total_value_gbp,
    SUM(CAST(REPLACE(net_mass, ',', '') AS NUMERIC)) AS total_net_mass_kg
FROM staging.wp005_raw_world_monthly

UNION ALL

SELECT
    'reference_world' AS data_layer,
    SUM(CAST(REPLACE(world_import_value_gbp, ',', '') AS NUMERIC)) AS total_value_gbp,
    SUM(CAST(REPLACE(world_net_mass_kg, ',', '') AS NUMERIC)) AS total_net_mass_kg
FROM staging.wp005_fct_world_monthly;
