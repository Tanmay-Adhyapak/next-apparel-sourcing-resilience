-- Export the ten validated analytical outputs.
-- Run one SELECT at a time and export its result through DBeaver.
-- Use UTF-8, column headers, unformatted numbers and NULL as the null marker.
-- In File name pattern, omit .csv because the exporter adds the extension.

-- 1. World trade by period and commodity.
-- Output: NEXT_WP006_world_trade_period_reported.csv
-- FULL_YEAR and H1 overlap; do not sum across period types.

SELECT
    period_type,
    calendar_year,
    cn8_code,
    hs4_code,
    first_month_date,
    last_month_date,
    month_count,
    world_import_value_gbp,
    world_net_mass_kg,
    world_supplementary_quantity,
    weighted_unit_value_gbp_per_kg,
    review_month_count,
    suppression_month_count

FROM analytics.vw_world_trade_period_reported

ORDER BY
    period_type,
    calendar_year,
    cn8_code;

-- 2. Reported partner trade by period and commodity.
-- Output: NEXT_WP006_partner_trade_period_reported.csv
-- World import share is a fraction; multiply by 100 for percentage display.
-- FULL_YEAR and H1 overlap; do not sum across period types.

SELECT
    period_type,
    calendar_year,
    partner_country_id,
    partner_country_iso2,
    partner_country_name,
    cn8_code,
    month_count,
    total_import_value_gbp,
    total_net_mass_kg,
    weighted_unit_value_gbp_per_kg,
    world_import_value_gbp,
    world_import_share,
    review_month_count,
    no_api_month_count

FROM analytics.vw_partner_trade_period_reported

ORDER BY
    period_type,
    calendar_year,
    cn8_code,
    partner_country_id;

-- 3. Reported partner trade growth between comparable periods.
-- Output: NEXT_WP006_partner_trade_period_growth_reported.csv
-- Growth and shares are percentages; share changes are percentage points.
-- Retain first-year rows and diagnostic counts for interpretation.

SELECT
    period_type,
    calendar_year,
    previous_calendar_year,
    partner_country_id,
    partner_country_iso2,
    partner_country_name,
    cn8_code,

    previous_import_value_gbp,
    current_import_value_gbp,
    import_value_growth_pct,

    previous_world_share_pct,
    current_world_share_pct,
    world_share_change_pp,

    previous_weighted_unit_value_gbp_per_kg,
    current_weighted_unit_value_gbp_per_kg,

    previous_month_count,
    current_month_count,

    previous_review_month_count,
    current_review_month_count,

    previous_no_api_month_count,
    current_no_api_month_count,

    import_value_growth_status

FROM analytics.vw_partner_trade_period_growth_reported

ORDER BY
    period_type,
    calendar_year,
    cn8_code,
    partner_country_id;

-- 4. Supplier footprint by country and product category.
-- Output: NEXT_WP006_supplier_country_product_footprint.csv
-- Relationship counts do not measure procurement spend or capacity.
-- Distinct supplier counts must not be summed across countries or products.

SELECT
    country_standardized,
    product_type_standardized,
    relationship_count,
    distinct_site_count,
    source_supplier_count,
    resolved_supplier_group_count

FROM analytics.vw_supplier_country_product_footprint

ORDER BY
    product_type_standardized,
    relationship_count DESC,
    country_standardized;

-- 5. Relationship-based supplier concentration by country and product.
-- Output: NEXT_WP006_supplier_country_product_concentration.csv
-- HHI and largest-entity share use the 0-to-1 scale.
-- Supplier bases are alternative classifications; do not add them together.

SELECT
    country_standardized,
    product_type_standardized,
    supplier_basis,
    entity_count,
    relationship_count,
    largest_entity_relationship_share,
    relationship_hhi

FROM analytics.vw_supplier_country_product_concentration

ORDER BY
    product_type_standardized,
    country_standardized,

    CASE
        WHEN supplier_basis = 'SOURCE_SUPPLIER' THEN 1
        WHEN supplier_basis = 'RESOLVED_GROUP' THEN 2
        ELSE 3
    END;

-- 6. Supplier overlap at each official Site ID.
-- Output: NEXT_WP006_site_supplier_overlap.csv
-- Shared-site flags distinguish source suppliers from resolved groups.
-- Physical-review flags may include closed reviews; retain their status.

SELECT
    site_id,
    site_name_canonical,
    country_standardized,
    product_type_standardized,

    relationship_count,
    source_supplier_count,
    resolved_supplier_group_count,

    source_supplier_shared_site_flag,
    resolved_group_shared_site_flag,

    physical_site_review_flag,
    physical_site_review_status,
    responsible_sourcing_review_flag

FROM analytics.vw_site_supplier_overlap

ORDER BY
    product_type_standardized,
    country_standardized,
    site_id;

-- 7. Declared sourcing-channel footprint by country and product.
-- Output: NEXT_WP006_supplier_channel_country_product_footprint.csv
-- Channel relationships do not establish site ownership.
-- Sites can appear under multiple channels; site reach shares may overlap.
-- Share columns use the 0-to-1 scale.

SELECT
    country_standardized,
    product_type_standardized,
    declared_channel_type,

    relationship_count,
    distinct_site_count,
    source_supplier_count,
    resolved_supplier_group_count,

    country_product_relationship_count,
    country_product_site_count,

    channel_relationship_share,
    channel_site_reach_share

FROM analytics.vw_supplier_channel_country_product_footprint

ORDER BY
    product_type_standardized,
    country_standardized,
    declared_channel_type;

-- 8. Site data coverage, review flags and documented NEXT ownership.
-- Output: NEXT_WP006_site_country_product_profile.csv
-- Employee totals cover listed sites, not workers dedicated to NEXT.
-- Missing ownership evidence does not establish external ownership.
-- Physical-review counts include retained flags from closed reviews.

SELECT
    country_standardized,
    product_type_standardized,
    site_count,

    employee_data_available_site_count,
    employee_data_missing_site_count,
    reported_total_employees,

    responsible_sourcing_review_site_count,
    physical_site_review_site_count,

    confirmed_next_owned_site_count

FROM analytics.vw_site_country_product_profile

ORDER BY
    product_type_standardized,
    country_standardized;

-- 9. Reported trade compared with REVIEW-excluded period results.
-- Output: NEXT_WP006_partner_trade_period_review_sensitivity.csv
-- Retained totals cover retained months only; they are not annualised.
-- World import shares are fractions; sensitivity changes are percentage points.
-- Countries may retain different months.

SELECT
    period_type,
    calendar_year,
    partner_country_id,
    partner_country_iso2,
    partner_country_name,
    cn8_code,

    baseline_month_count,
    retained_month_count,
    excluded_month_count,
    retained_no_api_month_count,

    reported_import_value_gbp,
    retained_import_value_gbp,
    retained_net_mass_kg,
    retained_world_import_value_gbp,

    reported_weighted_unit_value_gbp_per_kg,
    retained_weighted_unit_value_gbp_per_kg,

    reported_world_import_share,
    retained_world_import_share,
    world_share_sensitivity_change_pp

FROM analytics.vw_partner_trade_period_review_sensitivity

ORDER BY
    period_type,
    calendar_year,
    cn8_code,
    partner_country_id;

-- 10. Year-on-year REVIEW sensitivity using matched months.
-- Output: NEXT_WP006_partner_trade_period_growth_review_sensitivity.csv
-- Exclude month pairs with a partner or World REVIEW flag in either year.
-- Growth and shares are percentages; share changes are percentage points.

SELECT
    period_type,
    calendar_year,
    previous_calendar_year,
    partner_country_id,
    partner_country_iso2,
    partner_country_name,
    cn8_code,

    baseline_month_pair_count,
    retained_month_pair_count,
    excluded_month_pair_count,

    previous_retained_import_value_gbp,
    current_retained_import_value_gbp,
    retained_import_value_growth_pct,

    previous_retained_world_import_value_gbp,
    current_retained_world_import_value_gbp,

    previous_retained_world_share_pct,
    current_retained_world_share_pct,
    retained_world_share_change_pp

FROM analytics.vw_partner_trade_period_growth_review_sensitivity

ORDER BY
    period_type,
    calendar_year,
    cn8_code,
    partner_country_id;
