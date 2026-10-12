-- Optional interpretation queries over the validated views.
-- These are not required for the build or the ten standard exports.
-- Rounding is for display only; scenario inputs use the full-precision exports.

-- Inspect H1 2026 market-share changes against H1 2025.
-- Retain all countries, including observations carrying review flags.
-- Round only the displayed results.

SELECT
    growth.cn8_code,
    growth.partner_country_name,

    ROUND(growth.previous_import_value_gbp, 2)
        AS import_value_h1_2025_gbp,

    ROUND(growth.current_import_value_gbp, 2)
        AS import_value_h1_2026_gbp,

    ROUND(growth.import_value_growth_pct, 2)
        AS import_value_growth_pct,

    ROUND(growth.previous_world_share_pct, 2)
        AS world_share_h1_2025_pct,

    ROUND(growth.current_world_share_pct, 2)
        AS world_share_h1_2026_pct,

    ROUND(growth.world_share_change_pp, 3)
        AS world_share_change_pp,

    CASE
        WHEN growth.world_share_change_pp > 0
            THEN 'GAINED_SHARE'
        WHEN growth.world_share_change_pp < 0
            THEN 'LOST_SHARE'
        WHEN growth.world_share_change_pp = 0
            THEN 'UNCHANGED'
        ELSE 'NOT_COMPARABLE'
    END AS share_direction,

    growth.previous_review_month_count,
    growth.current_review_month_count,
    growth.previous_no_api_month_count,
    growth.current_no_api_month_count

FROM analytics.vw_partner_trade_period_growth_reported AS growth
WHERE growth.period_type = 'H1'
    AND growth.calendar_year = 2026
ORDER BY
    growth.cn8_code,
    growth.world_share_change_pp DESC NULLS LAST,
    growth.partner_country_name;

-- Compare concentration before and after supplier-group resolution.
-- Show the largest increases in relationship-based HHI first.

SELECT
    source_basis.country_standardized,
    source_basis.product_type_standardized,
    source_basis.relationship_count,

    source_basis.entity_count AS source_supplier_count,
    resolved_basis.entity_count AS resolved_supplier_group_count,

    ROUND(
        source_basis.relationship_hhi,
        6
    ) AS source_supplier_hhi,

    ROUND(
        resolved_basis.relationship_hhi,
        6
    ) AS resolved_group_hhi,

    ROUND(
        resolved_basis.relationship_hhi
            - source_basis.relationship_hhi,
        6
    ) AS hhi_increase,

    ROUND(
        source_basis.largest_entity_relationship_share * 100,
        2
    ) AS largest_source_supplier_share_pct,

    ROUND(
        resolved_basis.largest_entity_relationship_share * 100,
        2
    ) AS largest_resolved_group_share_pct

FROM analytics.vw_supplier_country_product_concentration AS source_basis

INNER JOIN analytics.vw_supplier_country_product_concentration AS resolved_basis
    ON source_basis.country_standardized =
        resolved_basis.country_standardized
    AND source_basis.product_type_standardized =
        resolved_basis.product_type_standardized

WHERE source_basis.supplier_basis = 'SOURCE_SUPPLIER'
    AND resolved_basis.supplier_basis = 'RESOLVED_GROUP'

ORDER BY
    resolved_basis.relationship_hhi
        - source_basis.relationship_hhi DESC,
    source_basis.country_standardized,
    source_basis.product_type_standardized;

-- Compare reported and matched-month sensitivity for H1 2026.
-- Evaluate direction using unrounded values.

SELECT
    reported.cn8_code,
    reported.partner_country_name,

    sensitivity.baseline_month_pair_count,
    sensitivity.retained_month_pair_count,
    sensitivity.excluded_month_pair_count,

    ROUND(
        reported.import_value_growth_pct,
        2
    ) AS reported_import_value_growth_pct,

    ROUND(
        sensitivity.retained_import_value_growth_pct,
        2
    ) AS sensitivity_import_value_growth_pct,

    ROUND(
        reported.world_share_change_pp,
        6
    ) AS reported_world_share_change_pp,

    ROUND(
        sensitivity.retained_world_share_change_pp,
        6
    ) AS sensitivity_world_share_change_pp,

    ROUND(
        sensitivity.retained_world_share_change_pp
            - reported.world_share_change_pp,
        6
    ) AS sensitivity_minus_reported_change_pp,

    CASE
        WHEN reported.world_share_change_pp IS NULL
            OR sensitivity.retained_world_share_change_pp IS NULL
            THEN 'NOT_COMPARABLE'

        WHEN SIGN(reported.world_share_change_pp) =
            SIGN(sensitivity.retained_world_share_change_pp)
            THEN 'SAME_DIRECTION'

        ELSE 'CHANGED_DIRECTION'
    END AS share_direction_comparison

FROM analytics.vw_partner_trade_period_growth_reported AS reported

INNER JOIN analytics.vw_partner_trade_period_growth_review_sensitivity
    AS sensitivity
    ON reported.period_type = sensitivity.period_type
    AND reported.calendar_year = sensitivity.calendar_year
    AND reported.partner_country_id = sensitivity.partner_country_id
    AND reported.cn8_code = sensitivity.cn8_code

WHERE reported.period_type = 'H1'
    AND reported.calendar_year = 2026

ORDER BY
    sensitivity.excluded_month_pair_count DESC,

    ABS(
        sensitivity.retained_world_share_change_pp
            - reported.world_share_change_pp
    ) DESC NULLS LAST,

    reported.cn8_code,
    reported.partner_country_name;
