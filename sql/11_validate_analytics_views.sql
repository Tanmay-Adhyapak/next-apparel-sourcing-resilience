-- Validate analytics coverage, metrics and cross-view consistency.
-- Run all twelve blocks; see QC_SUMMARY.md for the result interpretation.

-- 1. Validate analytics view row counts.
-- Expected counts apply to the current WP006 dataset.
-- Expected result: 11 rows, all marked PASS.

WITH view_counts AS (

    SELECT
        'vw_world_trade_period_reported' AS view_name,
        COUNT(*) AS actual_row_count,
        60 AS expected_row_count
    FROM analytics.vw_world_trade_period_reported

    UNION ALL

    SELECT
        'vw_partner_trade_period_reported',
        COUNT(*),
        600
    FROM analytics.vw_partner_trade_period_reported

    UNION ALL

    SELECT
        'vw_partner_trade_period_growth_reported',
        COUNT(*),
        600
    FROM analytics.vw_partner_trade_period_growth_reported

    UNION ALL

    SELECT
        'vw_supplier_country_product_footprint',
        COUNT(*),
        46
    FROM analytics.vw_supplier_country_product_footprint

    UNION ALL

    SELECT
        'vw_supplier_country_product_concentration',
        COUNT(*),
        92
    FROM analytics.vw_supplier_country_product_concentration

    UNION ALL

    SELECT
        'vw_site_supplier_overlap',
        COUNT(*),
        1478
    FROM analytics.vw_site_supplier_overlap

    UNION ALL

    SELECT
        'vw_supplier_channel_country_product_footprint',
        COUNT(*),
        60
    FROM analytics.vw_supplier_channel_country_product_footprint

    UNION ALL

    SELECT
        'vw_site_country_product_profile',
        COUNT(*),
        46
    FROM analytics.vw_site_country_product_profile

    UNION ALL

    SELECT
        'vw_partner_trade_monthly_review_basis',
        COUNT(*),
        3600
    FROM analytics.vw_partner_trade_monthly_review_basis

    UNION ALL

    SELECT
        'vw_partner_trade_period_review_sensitivity',
        COUNT(*),
        600
    FROM analytics.vw_partner_trade_period_review_sensitivity

    UNION ALL

    SELECT
        'vw_partner_trade_period_growth_review_sensitivity',
        COUNT(*),
        520
    FROM analytics.vw_partner_trade_period_growth_review_sensitivity

)

SELECT
    view_name,
    actual_row_count,
    expected_row_count,

    actual_row_count - expected_row_count
        AS row_count_difference,

    CASE
        WHEN actual_row_count = expected_row_count THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM view_counts

ORDER BY
    view_name;

-- 2. Validate uniqueness at each analytics view's intended grain.
-- Count identifier combinations that appear more than once.
-- Expected result: 11 rows, all duplicate_key_groups = 0.

SELECT
    'vw_world_trade_period_reported' AS view_name,
    COUNT(*) AS duplicate_key_groups

FROM (
    SELECT
        period_type,
        calendar_year,
        cn8_code

    FROM analytics.vw_world_trade_period_reported

    GROUP BY
        period_type,
        calendar_year,
        cn8_code

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_partner_trade_period_reported',
    COUNT(*)

FROM (
    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    FROM analytics.vw_partner_trade_period_reported

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_partner_trade_period_growth_reported',
    COUNT(*)

FROM (
    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    FROM analytics.vw_partner_trade_period_growth_reported

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_supplier_country_product_footprint',
    COUNT(*)

FROM (
    SELECT
        country_standardized,
        product_type_standardized

    FROM analytics.vw_supplier_country_product_footprint

    GROUP BY
        country_standardized,
        product_type_standardized

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_supplier_country_product_concentration',
    COUNT(*)

FROM (
    SELECT
        country_standardized,
        product_type_standardized,
        supplier_basis

    FROM analytics.vw_supplier_country_product_concentration

    GROUP BY
        country_standardized,
        product_type_standardized,
        supplier_basis

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_site_supplier_overlap',
    COUNT(*)

FROM (
    SELECT
        site_id

    FROM analytics.vw_site_supplier_overlap

    GROUP BY
        site_id

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_supplier_channel_country_product_footprint',
    COUNT(*)

FROM (
    SELECT
        country_standardized,
        product_type_standardized,
        declared_channel_type

    FROM analytics.vw_supplier_channel_country_product_footprint

    GROUP BY
        country_standardized,
        product_type_standardized,
        declared_channel_type

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_site_country_product_profile',
    COUNT(*)

FROM (
    SELECT
        country_standardized,
        product_type_standardized

    FROM analytics.vw_site_country_product_profile

    GROUP BY
        country_standardized,
        product_type_standardized

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_partner_trade_monthly_review_basis',
    COUNT(*)

FROM (
    SELECT
        partner_country_id,
        cn8_code,
        month_id

    FROM analytics.vw_partner_trade_monthly_review_basis

    GROUP BY
        partner_country_id,
        cn8_code,
        month_id

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_partner_trade_period_review_sensitivity',
    COUNT(*)

FROM (
    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    FROM analytics.vw_partner_trade_period_review_sensitivity

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    HAVING COUNT(*) > 1
) AS duplicate_keys

UNION ALL

SELECT
    'vw_partner_trade_period_growth_review_sensitivity',
    COUNT(*)

FROM (
    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    FROM analytics.vw_partner_trade_period_growth_review_sensitivity

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

    HAVING COUNT(*) > 1
) AS duplicate_keys

ORDER BY
    view_name;

-- 3. Validate reported period coverage against core monthly data.
-- Check both missing/incorrect rows and unexpected rows.
-- Expected result: four checks, all discrepancy_rows = 0.

WITH period_months AS (

    SELECT
        'FULL_YEAR' AS period_type,
        month_id

    FROM core.dim_month

    WHERE complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        month_id

    FROM core.dim_month

    WHERE like_for_like_h1_flag = 1

),

expected_world AS (

    SELECT
        period.period_type,
        world.calendar_year,
        world.cn8_code,
        COUNT(*) AS month_count,
        MIN(world.month_date) AS first_month_date,
        MAX(world.month_date) AS last_month_date

    FROM core.fct_hmrc_world_monthly AS world

    INNER JOIN period_months AS period
        ON world.month_id = period.month_id

    GROUP BY
        period.period_type,
        world.calendar_year,
        world.cn8_code

),

actual_world AS (

    SELECT
        period_type,
        calendar_year,
        cn8_code,
        month_count,
        first_month_date,
        last_month_date

    FROM analytics.vw_world_trade_period_reported

),

expected_partner AS (

    SELECT
        period.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.cn8_code,
        COUNT(*) AS month_count

    FROM core.fct_hmrc_import_monthly AS monthly

    INNER JOIN period_months AS period
        ON monthly.month_id = period.month_id

    GROUP BY
        period.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.cn8_code

),

actual_partner AS (

    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code,
        month_count

    FROM analytics.vw_partner_trade_period_reported

)

SELECT
    'world_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_world

    EXCEPT ALL

    SELECT * FROM actual_world
) AS differences

UNION ALL

SELECT
    'world_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_world

    EXCEPT ALL

    SELECT * FROM expected_world
) AS differences

UNION ALL

SELECT
    'partner_expected_minus_actual',
    COUNT(*)

FROM (
    SELECT * FROM expected_partner

    EXCEPT ALL

    SELECT * FROM actual_partner
) AS differences

UNION ALL

SELECT
    'partner_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_partner

    EXCEPT ALL

    SELECT * FROM expected_partner
) AS differences

ORDER BY
    check_name;

-- 4. Reconcile reported trade metrics against core monthly data.
-- Compare unrounded values in both directions.
-- Expected result: four checks, all discrepancy_rows = 0.

WITH period_months AS (

    SELECT
        'FULL_YEAR' AS period_type,
        month_id

    FROM core.dim_month

    WHERE complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        month_id

    FROM core.dim_month

    WHERE like_for_like_h1_flag = 1

),

expected_world AS (

    SELECT
        period.period_type,
        world.calendar_year,
        world.cn8_code,

        SUM(world.world_import_value_gbp)
            AS world_import_value_gbp,

        SUM(world.world_net_mass_kg)
            AS world_net_mass_kg,

        SUM(world.world_supplementary_quantity)
            AS world_supplementary_quantity,

        SUM(world.world_import_value_gbp)
            / NULLIF(SUM(world.world_net_mass_kg), 0)
            AS weighted_unit_value_gbp_per_kg,

        SUM(
            CASE
                WHEN world.unit_value_review_flag_2_5x = 'REVIEW'
                    THEN 1
                ELSE 0
            END
        ) AS review_month_count,

        SUM(
            CASE
                WHEN world.suppression_flag = 1 THEN 1
                ELSE 0
            END
        ) AS suppression_month_count

    FROM core.fct_hmrc_world_monthly AS world

    INNER JOIN period_months AS period
        ON world.month_id = period.month_id

    GROUP BY
        period.period_type,
        world.calendar_year,
        world.cn8_code

),

actual_world AS (

    SELECT
        period_type,
        calendar_year,
        cn8_code,
        world_import_value_gbp,
        world_net_mass_kg,
        world_supplementary_quantity,
        weighted_unit_value_gbp_per_kg,
        review_month_count,
        suppression_month_count

    FROM analytics.vw_world_trade_period_reported

),

expected_partner AS (

    SELECT
        period.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.partner_country_iso2,
        monthly.partner_country_name,
        monthly.cn8_code,

        SUM(monthly.import_value_gbp)
            AS total_import_value_gbp,

        SUM(monthly.net_mass_kg)
            AS total_net_mass_kg,

        SUM(monthly.import_value_gbp)
            / NULLIF(SUM(monthly.net_mass_kg), 0)
            AS weighted_unit_value_gbp_per_kg,

        SUM(world.world_import_value_gbp)
            AS world_import_value_gbp,

        SUM(monthly.import_value_gbp)
            / NULLIF(SUM(world.world_import_value_gbp), 0)
            AS world_import_share,

        SUM(
            CASE
                WHEN monthly.unit_value_review_flag_2_5x = 'REVIEW'
                    THEN 1
                ELSE 0
            END
        ) AS review_month_count,

        SUM(
            CASE
                WHEN monthly.record_status = 'NO_API_RECORD'
                    THEN 1
                ELSE 0
            END
        ) AS no_api_month_count

    FROM core.fct_hmrc_import_monthly AS monthly

    INNER JOIN period_months AS period
        ON monthly.month_id = period.month_id

    INNER JOIN core.fct_hmrc_world_monthly AS world
        ON monthly.month_id = world.month_id
        AND monthly.cn8_code = world.cn8_code

    GROUP BY
        period.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.partner_country_iso2,
        monthly.partner_country_name,
        monthly.cn8_code

),

actual_partner AS (

    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code,
        total_import_value_gbp,
        total_net_mass_kg,
        weighted_unit_value_gbp_per_kg,
        world_import_value_gbp,
        world_import_share,
        review_month_count,
        no_api_month_count

    FROM analytics.vw_partner_trade_period_reported

)

SELECT
    'world_metrics_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_world

    EXCEPT ALL

    SELECT * FROM actual_world
) AS differences

UNION ALL

SELECT
    'world_metrics_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_world

    EXCEPT ALL

    SELECT * FROM expected_world
) AS differences

UNION ALL

SELECT
    'partner_metrics_expected_minus_actual',
    COUNT(*)

FROM (
    SELECT * FROM expected_partner

    EXCEPT ALL

    SELECT * FROM actual_partner
) AS differences

UNION ALL

SELECT
    'partner_metrics_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_partner

    EXCEPT ALL

    SELECT * FROM expected_partner
) AS differences

ORDER BY
    check_name;

-- 5. Validate reported growth using independently sequenced periods.
-- Check 3 established the expected consecutive-year coverage.
-- Expected result: two checks, both discrepancy_rows = 0.

WITH period_history AS (

    SELECT
        reported.*,

        LAG(calendar_year) OVER history
            AS previous_calendar_year,

        LAG(total_import_value_gbp) OVER history
            AS previous_import_value_gbp,

        LAG(world_import_share) OVER history
            AS previous_world_import_share,

        LAG(weighted_unit_value_gbp_per_kg) OVER history
            AS previous_weighted_unit_value_gbp_per_kg,

        LAG(month_count) OVER history
            AS previous_month_count,

        LAG(review_month_count) OVER history
            AS previous_review_month_count,

        LAG(no_api_month_count) OVER history
            AS previous_no_api_month_count

    FROM analytics.vw_partner_trade_period_reported AS reported

    WINDOW history AS (
        PARTITION BY
            period_type,
            partner_country_id,
            cn8_code
        ORDER BY
            calendar_year
    )

),

expected_growth AS (

    SELECT
        period_type,
        calendar_year,
        previous_calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code,

        previous_import_value_gbp,

        total_import_value_gbp
            AS current_import_value_gbp,

        (
            total_import_value_gbp - previous_import_value_gbp
        )
            / NULLIF(previous_import_value_gbp, 0)
            * 100 AS import_value_growth_pct,

        previous_world_import_share * 100
            AS previous_world_share_pct,

        world_import_share * 100
            AS current_world_share_pct,

        (
            world_import_share - previous_world_import_share
        ) * 100 AS world_share_change_pp,

        previous_weighted_unit_value_gbp_per_kg,

        weighted_unit_value_gbp_per_kg
            AS current_weighted_unit_value_gbp_per_kg,

        previous_month_count,
        month_count AS current_month_count,

        previous_review_month_count,
        review_month_count AS current_review_month_count,

        previous_no_api_month_count,
        no_api_month_count AS current_no_api_month_count,

        CASE
            WHEN previous_calendar_year IS NULL
                THEN 'NO_PRIOR_PERIOD'

            WHEN previous_import_value_gbp = 0
                THEN 'ZERO_PRIOR_VALUE'

            ELSE 'COMPARABLE'
        END AS import_value_growth_status

    FROM period_history

),

actual_growth AS (

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

)

SELECT
    'growth_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_growth

    EXCEPT ALL

    SELECT * FROM actual_growth
) AS differences

UNION ALL

SELECT
    'growth_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_growth

    EXCEPT ALL

    SELECT * FROM expected_growth
) AS differences

ORDER BY
    check_name;

-- 6. Reconcile supplier footprint and channel metrics.
-- Recalculate each country-product combination from core data.
-- Expected result: four checks, all discrepancy_rows = 0.

WITH relationship_base AS (

    SELECT
        site.country_standardized,
        bridge.product_type_standardized,
        bridge.declared_channel_type,
        bridge.site_id,
        bridge.supplier_id,
        bridge.supplier_group_id

    FROM core.supplier_site_bridge AS bridge

    INNER JOIN core.site_master AS site
        ON bridge.site_id = site.site_id

),

expected_footprint AS (

    SELECT
        country_standardized,
        product_type_standardized,

        COUNT(*) AS relationship_count,

        COUNT(DISTINCT site_id)
            AS distinct_site_count,

        COUNT(DISTINCT supplier_id)
            AS source_supplier_count,

        COUNT(DISTINCT supplier_group_id)
            AS resolved_supplier_group_count

    FROM relationship_base

    GROUP BY
        country_standardized,
        product_type_standardized

),

actual_footprint AS (

    SELECT
        country_standardized,
        product_type_standardized,
        relationship_count,
        distinct_site_count,
        source_supplier_count,
        resolved_supplier_group_count

    FROM analytics.vw_supplier_country_product_footprint

),

channel_counts AS (

    SELECT
        country_standardized,
        product_type_standardized,
        declared_channel_type,

        COUNT(*) AS relationship_count,

        COUNT(DISTINCT site_id)
            AS distinct_site_count,

        COUNT(DISTINCT supplier_id)
            AS source_supplier_count,

        COUNT(DISTINCT supplier_group_id)
            AS resolved_supplier_group_count

    FROM relationship_base

    GROUP BY
        country_standardized,
        product_type_standardized,
        declared_channel_type

),

expected_channel AS (

    SELECT
        channel.country_standardized,
        channel.product_type_standardized,
        channel.declared_channel_type,
        channel.relationship_count,
        channel.distinct_site_count,
        channel.source_supplier_count,
        channel.resolved_supplier_group_count,

        footprint.relationship_count
            AS country_product_relationship_count,

        footprint.distinct_site_count
            AS country_product_site_count,

        CAST(channel.relationship_count AS NUMERIC)
            / NULLIF(footprint.relationship_count, 0)
            AS channel_relationship_share,

        CAST(channel.distinct_site_count AS NUMERIC)
            / NULLIF(footprint.distinct_site_count, 0)
            AS channel_site_reach_share

    FROM channel_counts AS channel

    INNER JOIN expected_footprint AS footprint
        ON channel.country_standardized =
            footprint.country_standardized
        AND channel.product_type_standardized =
            footprint.product_type_standardized

),

actual_channel AS (

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

)

SELECT
    'footprint_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_footprint

    EXCEPT ALL

    SELECT * FROM actual_footprint
) AS differences

UNION ALL

SELECT
    'footprint_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_footprint

    EXCEPT ALL

    SELECT * FROM expected_footprint
) AS differences

UNION ALL

SELECT
    'channel_expected_minus_actual',
    COUNT(*)

FROM (
    SELECT * FROM expected_channel

    EXCEPT ALL

    SELECT * FROM actual_channel
) AS differences

UNION ALL

SELECT
    'channel_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_channel

    EXCEPT ALL

    SELECT * FROM expected_channel
) AS differences

ORDER BY
    check_name;

-- 7. Validate supplier concentration under both supplier bases.
-- Recalculate HHI directly from entity relationship counts.
-- Allow a small tolerance for numeric division precision.
-- Expected result: two checks, both discrepancy_rows = 0.

WITH relationship_base AS (

    SELECT
        site.country_standardized,
        bridge.product_type_standardized,
        bridge.supplier_id,
        bridge.supplier_group_id

    FROM core.supplier_site_bridge AS bridge

    INNER JOIN core.site_master AS site
        ON bridge.site_id = site.site_id

),

entity_counts AS (

    SELECT
        country_standardized,
        product_type_standardized,
        'SOURCE_SUPPLIER' AS supplier_basis,
        supplier_id AS entity_id,
        CAST(COUNT(*) AS NUMERIC) AS relationship_count

    FROM relationship_base

    GROUP BY
        country_standardized,
        product_type_standardized,
        supplier_id

    UNION ALL

    SELECT
        country_standardized,
        product_type_standardized,
        'RESOLVED_GROUP' AS supplier_basis,
        supplier_group_id AS entity_id,
        CAST(COUNT(*) AS NUMERIC) AS relationship_count

    FROM relationship_base

    GROUP BY
        country_standardized,
        product_type_standardized,
        supplier_group_id

),

expected_concentration AS (

    SELECT
        country_standardized,
        product_type_standardized,
        supplier_basis,

        COUNT(*) AS entity_count,

        SUM(relationship_count) AS relationship_count,

        MAX(relationship_count)
            / NULLIF(SUM(relationship_count), 0)
            AS largest_entity_relationship_share,

        SUM(relationship_count * relationship_count)
            / NULLIF(
                SUM(relationship_count) * SUM(relationship_count),
                0
            ) AS relationship_hhi

    FROM entity_counts

    GROUP BY
        country_standardized,
        product_type_standardized,
        supplier_basis

)

SELECT
    'concentration_recalculation' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM expected_concentration AS expected

FULL OUTER JOIN analytics.vw_supplier_country_product_concentration AS actual
    ON expected.country_standardized = actual.country_standardized
    AND expected.product_type_standardized =
        actual.product_type_standardized
    AND expected.supplier_basis = actual.supplier_basis

WHERE expected.supplier_basis IS NULL
    OR actual.supplier_basis IS NULL

    OR expected.entity_count IS DISTINCT FROM actual.entity_count

    OR expected.relationship_count
        IS DISTINCT FROM actual.relationship_count

    OR actual.largest_entity_relationship_share IS NULL

    OR ABS(
        expected.largest_entity_relationship_share
            - actual.largest_entity_relationship_share
    ) > 0.000000000001

    OR actual.relationship_hhi IS NULL

    OR ABS(
        expected.relationship_hhi - actual.relationship_hhi
    ) > 0.000000000001

UNION ALL

SELECT
    'concentration_supplier_basis_consistency',
    COUNT(*)

FROM analytics.vw_supplier_country_product_concentration AS source_basis

FULL OUTER JOIN analytics.vw_supplier_country_product_concentration
    AS resolved_basis
    ON source_basis.country_standardized =
        resolved_basis.country_standardized
    AND source_basis.product_type_standardized =
        resolved_basis.product_type_standardized
    AND source_basis.supplier_basis = 'SOURCE_SUPPLIER'
    AND resolved_basis.supplier_basis = 'RESOLVED_GROUP'

WHERE (
    source_basis.supplier_basis = 'SOURCE_SUPPLIER'
    OR resolved_basis.supplier_basis = 'RESOLVED_GROUP'
)
AND (
    source_basis.supplier_basis IS NULL
    OR resolved_basis.supplier_basis IS NULL

    OR source_basis.relationship_count
        IS DISTINCT FROM resolved_basis.relationship_count

    OR resolved_basis.entity_count > source_basis.entity_count

    OR resolved_basis.relationship_hhi
        < source_basis.relationship_hhi - 0.000000000001

    OR resolved_basis.largest_entity_relationship_share
        < source_basis.largest_entity_relationship_share
            - 0.000000000001
)

ORDER BY
    check_name;

-- 8. Reconcile site overlap and country-product site profiles.
-- Calculate employee and ownership metrics directly from site_master.
-- Expected result: four checks, all discrepancy_rows = 0.

WITH supplier_counts AS (

    SELECT
        site_id,
        COUNT(*) AS relationship_count,

        COUNT(DISTINCT supplier_id)
            AS source_supplier_count,

        COUNT(DISTINCT supplier_group_id)
            AS resolved_supplier_group_count

    FROM core.supplier_site_bridge

    GROUP BY
        site_id

),

expected_overlap AS (

    SELECT
        site.site_id,
        site.site_name_canonical,
        site.country_standardized,
        site.product_type_standardized,

        supplier.relationship_count,
        supplier.source_supplier_count,
        supplier.resolved_supplier_group_count,

        CASE
            WHEN supplier.source_supplier_count > 1 THEN 1
            ELSE 0
        END AS source_supplier_shared_site_flag,

        CASE
            WHEN supplier.resolved_supplier_group_count > 1 THEN 1
            ELSE 0
        END AS resolved_group_shared_site_flag,

        site.physical_site_review_flag,
        site.physical_site_review_status,
        site.responsible_sourcing_review_flag

    FROM core.site_master AS site

    LEFT JOIN supplier_counts AS supplier
        ON site.site_id = supplier.site_id

),

actual_overlap AS (

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

),

expected_profile AS (

    SELECT
        country_standardized,
        product_type_standardized,

        COUNT(*) AS site_count,

        COUNT(total_employees)
            AS employee_data_available_site_count,

        COUNT(*) - COUNT(total_employees)
            AS employee_data_missing_site_count,

        SUM(total_employees)
            AS reported_total_employees,

        SUM(responsible_sourcing_review_flag)
            AS responsible_sourcing_review_site_count,

        SUM(physical_site_review_flag)
            AS physical_site_review_site_count,

        COUNT(*) FILTER (
            WHERE site_owner_group = 'NEXT_GROUP'
                AND site_ownership_status =
                    'Confirmed group-owned manufacturing operation'
        ) AS confirmed_next_owned_site_count

    FROM core.site_master

    GROUP BY
        country_standardized,
        product_type_standardized

),

actual_profile AS (

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

)

SELECT
    'site_overlap_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_overlap

    EXCEPT ALL

    SELECT * FROM actual_overlap
) AS differences

UNION ALL

SELECT
    'site_overlap_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_overlap

    EXCEPT ALL

    SELECT * FROM expected_overlap
) AS differences

UNION ALL

SELECT
    'site_profile_expected_minus_actual',
    COUNT(*)

FROM (
    SELECT * FROM expected_profile

    EXCEPT ALL

    SELECT * FROM actual_profile
) AS differences

UNION ALL

SELECT
    'site_profile_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_profile

    EXCEPT ALL

    SELECT * FROM expected_profile
) AS differences

ORDER BY
    check_name;

-- 9. Validate monthly REVIEW-sensitivity data and classifications.
-- Rebuild expected rows directly from core partner and World facts.
-- Expected result: two checks, both discrepancy_rows = 0.

WITH expected_monthly AS (

    SELECT
        monthly.monthly_import_key,
        monthly.month_id,
        monthly.month_date,
        monthly.calendar_year,
        monthly.calendar_month,
        monthly.partner_country_id,
        monthly.partner_country_iso2,
        monthly.partner_country_name,
        monthly.cn8_code,

        monthly.import_value_gbp,
        monthly.net_mass_kg,

        world.world_import_value_gbp,
        world.world_net_mass_kg,

        monthly.record_status,

        monthly.unit_value_review_flag_2_5x
            AS partner_unit_value_review_status,

        world.unit_value_review_flag_2_5x
            AS world_unit_value_review_status,

        CASE
            WHEN monthly.unit_value_review_flag_2_5x = 'REVIEW'
                OR world.unit_value_review_flag_2_5x = 'REVIEW'
                THEN 0
            ELSE 1
        END AS review_sensitivity_inclusion_flag,

        CASE
            WHEN monthly.unit_value_review_flag_2_5x = 'REVIEW'
                AND world.unit_value_review_flag_2_5x = 'REVIEW'
                THEN 'PARTNER_AND_WORLD_REVIEW'

            WHEN monthly.unit_value_review_flag_2_5x = 'REVIEW'
                THEN 'PARTNER_REVIEW'

            WHEN world.unit_value_review_flag_2_5x = 'REVIEW'
                THEN 'WORLD_REVIEW'

            ELSE 'RETAINED'
        END AS review_sensitivity_status

    FROM core.fct_hmrc_import_monthly AS monthly

    INNER JOIN core.fct_hmrc_world_monthly AS world
        ON monthly.month_id = world.month_id
        AND monthly.cn8_code = world.cn8_code

),

actual_monthly AS (

    SELECT
        monthly_import_key,
        month_id,
        month_date,
        calendar_year,
        calendar_month,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code,
        import_value_gbp,
        net_mass_kg,
        world_import_value_gbp,
        world_net_mass_kg,
        record_status,
        partner_unit_value_review_status,
        world_unit_value_review_status,
        review_sensitivity_inclusion_flag,
        review_sensitivity_status

    FROM analytics.vw_partner_trade_monthly_review_basis

)

SELECT
    'monthly_sensitivity_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_monthly

    EXCEPT ALL

    SELECT * FROM actual_monthly
) AS differences

UNION ALL

SELECT
    'monthly_sensitivity_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_monthly

    EXCEPT ALL

    SELECT * FROM expected_monthly
) AS differences

ORDER BY
    check_name;

-- 10. Reconcile period REVIEW-sensitivity metrics.
-- Recalculate from the validated monthly sensitivity basis.
-- Expected result: two checks, both discrepancy_rows = 0.

WITH period_months AS (

    SELECT
        'FULL_YEAR' AS period_type,
        month_id

    FROM core.dim_month

    WHERE complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        month_id

    FROM core.dim_month

    WHERE like_for_like_h1_flag = 1

),

expected_totals AS (

    SELECT
        period.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.cn8_code,

        COUNT(*) AS baseline_month_count,

        COUNT(*) FILTER (
            WHERE monthly.review_sensitivity_inclusion_flag = 1
        ) AS retained_month_count,

        COUNT(*) FILTER (
            WHERE monthly.review_sensitivity_inclusion_flag = 0
        ) AS excluded_month_count,

        COUNT(*) FILTER (
            WHERE monthly.review_sensitivity_inclusion_flag = 1
                AND monthly.record_status = 'NO_API_RECORD'
        ) AS retained_no_api_month_count,

        SUM(monthly.import_value_gbp) FILTER (
            WHERE monthly.review_sensitivity_inclusion_flag = 1
        ) AS retained_import_value_gbp,

        SUM(monthly.net_mass_kg) FILTER (
            WHERE monthly.review_sensitivity_inclusion_flag = 1
        ) AS retained_net_mass_kg,

        SUM(monthly.world_import_value_gbp) FILTER (
            WHERE monthly.review_sensitivity_inclusion_flag = 1
        ) AS retained_world_import_value_gbp

    FROM analytics.vw_partner_trade_monthly_review_basis AS monthly

    INNER JOIN period_months AS period
        ON monthly.month_id = period.month_id

    GROUP BY
        period.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.cn8_code

),

expected_sensitivity AS (

    SELECT
        totals.period_type,
        totals.calendar_year,
        totals.partner_country_id,
        reported.partner_country_iso2,
        reported.partner_country_name,
        totals.cn8_code,

        totals.baseline_month_count,
        totals.retained_month_count,
        totals.excluded_month_count,
        totals.retained_no_api_month_count,

        reported.total_import_value_gbp
            AS reported_import_value_gbp,

        totals.retained_import_value_gbp,
        totals.retained_net_mass_kg,
        totals.retained_world_import_value_gbp,

        reported.weighted_unit_value_gbp_per_kg
            AS reported_weighted_unit_value_gbp_per_kg,

        totals.retained_import_value_gbp
            / NULLIF(totals.retained_net_mass_kg, 0)
            AS retained_weighted_unit_value_gbp_per_kg,

        reported.world_import_share
            AS reported_world_import_share,

        totals.retained_import_value_gbp
            / NULLIF(totals.retained_world_import_value_gbp, 0)
            AS retained_world_import_share,

        (
            totals.retained_import_value_gbp
                / NULLIF(totals.retained_world_import_value_gbp, 0)
            - reported.world_import_share
        ) * 100 AS world_share_sensitivity_change_pp

    FROM expected_totals AS totals

    INNER JOIN analytics.vw_partner_trade_period_reported AS reported
        ON totals.period_type = reported.period_type
        AND totals.calendar_year = reported.calendar_year
        AND totals.partner_country_id = reported.partner_country_id
        AND totals.cn8_code = reported.cn8_code

),

actual_sensitivity AS (

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

)

SELECT
    'period_sensitivity_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_sensitivity

    EXCEPT ALL

    SELECT * FROM actual_sensitivity
) AS differences

UNION ALL

SELECT
    'period_sensitivity_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_sensitivity

    EXCEPT ALL

    SELECT * FROM expected_sensitivity
) AS differences

ORDER BY
    check_name;

-- 11. Reconcile matched-month growth sensitivity.
-- month_id uses YYYYMM, so subtracting 100 selects the prior year.
-- Require both months to belong to the same eligible period type.
-- Expected result: two checks, both discrepancy_rows = 0.

WITH period_months AS (

    SELECT
        'FULL_YEAR' AS period_type,
        month_id

    FROM core.dim_month

    WHERE complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        month_id

    FROM core.dim_month

    WHERE like_for_like_h1_flag = 1

),

expected_pairs AS (

    SELECT
        current_period.period_type,
        current_month.calendar_year,
        current_month.partner_country_id,
        current_month.partner_country_iso2,
        current_month.partner_country_name,
        current_month.cn8_code,

        previous_month.import_value_gbp
            AS previous_import_value_gbp,

        current_month.import_value_gbp
            AS current_import_value_gbp,

        previous_month.world_import_value_gbp
            AS previous_world_import_value_gbp,

        current_month.world_import_value_gbp
            AS current_world_import_value_gbp,

        CASE
            WHEN current_month.review_sensitivity_inclusion_flag = 1
                AND previous_month.review_sensitivity_inclusion_flag = 1
                THEN 1
            ELSE 0
        END AS retain_pair_flag

    FROM analytics.vw_partner_trade_monthly_review_basis AS current_month

    INNER JOIN analytics.vw_partner_trade_monthly_review_basis
        AS previous_month
        ON current_month.partner_country_id =
            previous_month.partner_country_id
        AND current_month.cn8_code = previous_month.cn8_code
        AND previous_month.month_id = current_month.month_id - 100

    INNER JOIN period_months AS current_period
        ON current_month.month_id = current_period.month_id

    INNER JOIN period_months AS previous_period
        ON previous_month.month_id = previous_period.month_id
        AND current_period.period_type = previous_period.period_type

),

expected_totals AS (

    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code,

        COUNT(*) AS baseline_month_pair_count,

        COUNT(*) FILTER (
            WHERE retain_pair_flag = 1
        ) AS retained_month_pair_count,

        COUNT(*) FILTER (
            WHERE retain_pair_flag = 0
        ) AS excluded_month_pair_count,

        SUM(
            CASE
                WHEN retain_pair_flag = 1
                    THEN previous_import_value_gbp
            END
        ) AS previous_retained_import_value_gbp,

        SUM(
            CASE
                WHEN retain_pair_flag = 1
                    THEN current_import_value_gbp
            END
        ) AS current_retained_import_value_gbp,

        SUM(
            CASE
                WHEN retain_pair_flag = 1
                    THEN previous_world_import_value_gbp
            END
        ) AS previous_retained_world_import_value_gbp,

        SUM(
            CASE
                WHEN retain_pair_flag = 1
                    THEN current_world_import_value_gbp
            END
        ) AS current_retained_world_import_value_gbp

    FROM expected_pairs

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code

),

expected_growth AS (

    SELECT
        totals.*,

        calendar_year - 1 AS previous_calendar_year,

        (
            current_retained_import_value_gbp
                - previous_retained_import_value_gbp
        )
            / NULLIF(previous_retained_import_value_gbp, 0)
            * 100 AS retained_import_value_growth_pct,

        previous_retained_import_value_gbp
            / NULLIF(previous_retained_world_import_value_gbp, 0)
            * 100 AS previous_retained_world_share_pct,

        current_retained_import_value_gbp
            / NULLIF(current_retained_world_import_value_gbp, 0)
            * 100 AS current_retained_world_share_pct,

        (
            current_retained_import_value_gbp
                / NULLIF(current_retained_world_import_value_gbp, 0)
            - previous_retained_import_value_gbp
                / NULLIF(previous_retained_world_import_value_gbp, 0)
        ) * 100 AS retained_world_share_change_pp

    FROM expected_totals AS totals

),

actual_growth AS (

    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code,
        baseline_month_pair_count,
        retained_month_pair_count,
        excluded_month_pair_count,
        previous_retained_import_value_gbp,
        current_retained_import_value_gbp,
        previous_retained_world_import_value_gbp,
        current_retained_world_import_value_gbp,
        previous_calendar_year,
        retained_import_value_growth_pct,
        previous_retained_world_share_pct,
        current_retained_world_share_pct,
        retained_world_share_change_pp

    FROM analytics.vw_partner_trade_period_growth_review_sensitivity

)

SELECT
    'growth_sensitivity_expected_minus_actual' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM (
    SELECT * FROM expected_growth

    EXCEPT ALL

    SELECT * FROM actual_growth
) AS differences

UNION ALL

SELECT
    'growth_sensitivity_actual_minus_expected',
    COUNT(*)

FROM (
    SELECT * FROM actual_growth

    EXCEPT ALL

    SELECT * FROM expected_growth
) AS differences

ORDER BY
    check_name;

-- 12. Validate consistency across analytics outputs.
-- Expected result: seven checks, all discrepancy_rows = 0.

WITH channel_totals AS (

    SELECT
        country_standardized,
        product_type_standardized,

        SUM(relationship_count) AS relationship_count,

        SUM(channel_relationship_share)
            AS relationship_share_total

    FROM analytics.vw_supplier_channel_country_product_footprint

    GROUP BY
        country_standardized,
        product_type_standardized

)

SELECT
    'period_sensitivity_month_accounting' AS check_name,
    COUNT(*) AS discrepancy_rows

FROM analytics.vw_partner_trade_period_review_sensitivity

WHERE baseline_month_count IS NULL
    OR retained_month_count IS NULL
    OR excluded_month_count IS NULL
    OR retained_no_api_month_count IS NULL

    OR baseline_month_count <>
        retained_month_count + excluded_month_count

    OR retained_month_count < 0
    OR excluded_month_count < 0
    OR retained_no_api_month_count < 0
    OR retained_no_api_month_count > retained_month_count

UNION ALL

SELECT
    'growth_sensitivity_month_accounting',
    COUNT(*)

FROM analytics.vw_partner_trade_period_growth_review_sensitivity

WHERE baseline_month_pair_count IS NULL
    OR retained_month_pair_count IS NULL
    OR excluded_month_pair_count IS NULL

    OR baseline_month_pair_count <>
        retained_month_pair_count + excluded_month_pair_count

    OR retained_month_pair_count < 0
    OR excluded_month_pair_count < 0

    OR previous_calendar_year
        IS DISTINCT FROM calendar_year - 1

UNION ALL

SELECT
    'unaffected_period_matches_reported',
    COUNT(*)

FROM analytics.vw_partner_trade_period_review_sensitivity AS sensitivity

INNER JOIN analytics.vw_partner_trade_period_reported AS reported
    ON sensitivity.period_type = reported.period_type
    AND sensitivity.calendar_year = reported.calendar_year
    AND sensitivity.partner_country_id = reported.partner_country_id
    AND sensitivity.cn8_code = reported.cn8_code

WHERE sensitivity.excluded_month_count = 0

AND ROW(
    sensitivity.retained_import_value_gbp,
    sensitivity.retained_net_mass_kg,
    sensitivity.retained_world_import_value_gbp,
    sensitivity.retained_weighted_unit_value_gbp_per_kg,
    sensitivity.retained_world_import_share,
    sensitivity.world_share_sensitivity_change_pp
) IS DISTINCT FROM ROW(
    reported.total_import_value_gbp,
    reported.total_net_mass_kg,
    reported.world_import_value_gbp,
    reported.weighted_unit_value_gbp_per_kg,
    reported.world_import_share,
    0::NUMERIC
)

UNION ALL

SELECT
    'unaffected_growth_matches_reported',
    COUNT(*)

FROM analytics.vw_partner_trade_period_growth_review_sensitivity
    AS sensitivity

INNER JOIN analytics.vw_partner_trade_period_growth_reported AS reported
    ON sensitivity.period_type = reported.period_type
    AND sensitivity.calendar_year = reported.calendar_year
    AND sensitivity.partner_country_id = reported.partner_country_id
    AND sensitivity.cn8_code = reported.cn8_code

WHERE sensitivity.excluded_month_pair_count = 0

AND ROW(
    sensitivity.previous_retained_import_value_gbp,
    sensitivity.current_retained_import_value_gbp,
    sensitivity.retained_import_value_growth_pct,
    sensitivity.previous_retained_world_share_pct,
    sensitivity.current_retained_world_share_pct,
    sensitivity.retained_world_share_change_pp
) IS DISTINCT FROM ROW(
    reported.previous_import_value_gbp,
    reported.current_import_value_gbp,
    reported.import_value_growth_pct,
    reported.previous_world_share_pct,
    reported.current_world_share_pct,
    reported.world_share_change_pp
)

UNION ALL

SELECT
    'channel_relationship_totals_and_shares',
    COUNT(*)

FROM channel_totals AS channel

FULL OUTER JOIN analytics.vw_supplier_country_product_footprint
    AS footprint
    ON channel.country_standardized = footprint.country_standardized
    AND channel.product_type_standardized =
        footprint.product_type_standardized

WHERE channel.country_standardized IS NULL
    OR footprint.country_standardized IS NULL

    OR channel.relationship_count
        IS DISTINCT FROM footprint.relationship_count

    OR channel.relationship_share_total IS NULL

    OR ABS(channel.relationship_share_total - 1)
        > 0.000000000001

UNION ALL

SELECT
    'site_profile_footprint_and_employee_coverage',
    COUNT(*)

FROM analytics.vw_site_country_product_profile AS profile

FULL OUTER JOIN analytics.vw_supplier_country_product_footprint
    AS footprint
    ON profile.country_standardized = footprint.country_standardized
    AND profile.product_type_standardized =
        footprint.product_type_standardized

WHERE profile.country_standardized IS NULL
    OR footprint.country_standardized IS NULL

    OR profile.site_count
        IS DISTINCT FROM footprint.distinct_site_count

    OR profile.site_count IS DISTINCT FROM (
        profile.employee_data_available_site_count
            + profile.employee_data_missing_site_count
    )

UNION ALL

SELECT
    'site_overlap_supplier_basis_consistency',
    COUNT(*)

FROM analytics.vw_site_supplier_overlap

WHERE source_supplier_count IS NULL
    OR resolved_supplier_group_count IS NULL
    OR source_supplier_shared_site_flag IS NULL
    OR resolved_group_shared_site_flag IS NULL

    OR source_supplier_count < 1
    OR resolved_supplier_group_count < 1

    OR resolved_supplier_group_count > source_supplier_count

    OR resolved_group_shared_site_flag >
        source_supplier_shared_site_flag

ORDER BY
    check_name;
