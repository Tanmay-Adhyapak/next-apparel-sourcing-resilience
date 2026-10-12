-- Create the eleven analytics views over validated core data.
-- Validate with script 11; export with script 12.

-- 1. Create reported World trade summaries.
-- Grain: one row per period type, calendar year and CN8 code.
-- Preserve REVIEW observations in the reported-data baseline.

CREATE VIEW analytics.vw_world_trade_period_reported AS

WITH period_rows AS (
    SELECT
        'FULL_YEAR' AS period_type,
        world.*
    FROM core.fct_hmrc_world_monthly AS world
    INNER JOIN core.dim_month AS month_dim
        ON world.month_id = month_dim.month_id
    WHERE month_dim.complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        world.*
    FROM core.fct_hmrc_world_monthly AS world
    INNER JOIN core.dim_month AS month_dim
        ON world.month_id = month_dim.month_id
    WHERE month_dim.like_for_like_h1_flag = 1
)

SELECT
    period_type,
    calendar_year,
    cn8_code,
    hs4_code,
    MIN(month_date) AS first_month_date,
    MAX(month_date) AS last_month_date,
    COUNT(*) AS month_count,

    SUM(world_import_value_gbp) AS world_import_value_gbp,
    SUM(world_net_mass_kg) AS world_net_mass_kg,
    SUM(world_supplementary_quantity)
        AS world_supplementary_quantity,

    SUM(world_import_value_gbp)
        / NULLIF(SUM(world_net_mass_kg), 0)
        AS weighted_unit_value_gbp_per_kg,

    SUM(
        CASE
            WHEN unit_value_review_flag_2_5x = 'REVIEW'
                THEN 1
            ELSE 0
        END
    ) AS review_month_count,

    SUM(
        CASE
            WHEN suppression_flag = 1
                THEN 1
            ELSE 0
        END
    ) AS suppression_month_count

FROM period_rows
GROUP BY
    period_type,
    calendar_year,
    cn8_code,
    hs4_code;

-- 2. Create reported partner-country trade summaries.
-- Grain: one row per period type, year, country and CN8 code.

CREATE VIEW analytics.vw_partner_trade_period_reported AS

WITH period_rows AS (
    SELECT
        'FULL_YEAR' AS period_type,
        monthly.*
    FROM core.fct_hmrc_import_monthly AS monthly
    INNER JOIN core.dim_month AS month_dim
        ON monthly.month_id = month_dim.month_id
    WHERE month_dim.complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        monthly.*
    FROM core.fct_hmrc_import_monthly AS monthly
    INNER JOIN core.dim_month AS month_dim
        ON monthly.month_id = month_dim.month_id
    WHERE month_dim.like_for_like_h1_flag = 1
),

country_totals AS (
    SELECT
        monthly.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.partner_country_iso2,
        monthly.partner_country_name,
        monthly.cn8_code,

        COUNT(*) AS month_count,

        SUM(monthly.import_value_gbp)
            AS total_import_value_gbp,

        SUM(monthly.net_mass_kg)
            AS total_net_mass_kg,

        SUM(monthly.import_value_gbp)
            / NULLIF(SUM(monthly.net_mass_kg), 0)
            AS weighted_unit_value_gbp_per_kg,

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

    FROM period_rows AS monthly
    GROUP BY
        monthly.period_type,
        monthly.calendar_year,
        monthly.partner_country_id,
        monthly.partner_country_iso2,
        monthly.partner_country_name,
        monthly.cn8_code
)

SELECT
    country.*,
    world.world_import_value_gbp,

    country.total_import_value_gbp
        / NULLIF(world.world_import_value_gbp, 0)
        AS world_import_share

FROM country_totals AS country
INNER JOIN analytics.vw_world_trade_period_reported AS world
    ON country.period_type = world.period_type
    AND country.calendar_year = world.calendar_year
    AND country.cn8_code = world.cn8_code;

-- 3. Create reported partner-country growth comparisons.
-- Match the same country, product and period type to the previous year.
-- Preserve REVIEW observations and expose their counts.

CREATE VIEW analytics.vw_partner_trade_period_growth_reported AS

SELECT
    current_period.period_type,
    current_period.calendar_year,
    previous_period.calendar_year AS previous_calendar_year,
    current_period.partner_country_id,
    current_period.partner_country_iso2,
    current_period.partner_country_name,
    current_period.cn8_code,

    previous_period.total_import_value_gbp
        AS previous_import_value_gbp,

    current_period.total_import_value_gbp
        AS current_import_value_gbp,

    (
        current_period.total_import_value_gbp
        - previous_period.total_import_value_gbp
    )
        / NULLIF(previous_period.total_import_value_gbp, 0)
        * 100
        AS import_value_growth_pct,

    previous_period.world_import_share * 100
        AS previous_world_share_pct,

    current_period.world_import_share * 100
        AS current_world_share_pct,

    (
        current_period.world_import_share
        - previous_period.world_import_share
    ) * 100
        AS world_share_change_pp,

    previous_period.weighted_unit_value_gbp_per_kg
        AS previous_weighted_unit_value_gbp_per_kg,

    current_period.weighted_unit_value_gbp_per_kg
        AS current_weighted_unit_value_gbp_per_kg,

    previous_period.month_count AS previous_month_count,
    current_period.month_count AS current_month_count,

    previous_period.review_month_count
        AS previous_review_month_count,

    current_period.review_month_count
        AS current_review_month_count,

    previous_period.no_api_month_count
        AS previous_no_api_month_count,

    current_period.no_api_month_count
        AS current_no_api_month_count,

    CASE
        WHEN previous_period.calendar_year IS NULL
            THEN 'NO_PRIOR_PERIOD'
        WHEN previous_period.total_import_value_gbp = 0
            THEN 'ZERO_PRIOR_VALUE'
        ELSE 'COMPARABLE'
    END AS import_value_growth_status

FROM analytics.vw_partner_trade_period_reported AS current_period
LEFT JOIN analytics.vw_partner_trade_period_reported AS previous_period
    ON current_period.partner_country_id =
        previous_period.partner_country_id
    AND current_period.cn8_code = previous_period.cn8_code
    AND current_period.period_type = previous_period.period_type
    AND previous_period.calendar_year =
        current_period.calendar_year - 1;

-- 4. Create the supplier footprint by country and product type.
-- Use standardized site countries.
-- Retain the complete WP003 footprint.

CREATE VIEW analytics.vw_supplier_country_product_footprint AS

SELECT
    site.country_standardized,
    bridge.product_type_standardized,

    COUNT(*) AS relationship_count,

    COUNT(DISTINCT bridge.site_id)
        AS distinct_site_count,

    COUNT(DISTINCT bridge.supplier_id)
        AS source_supplier_count,

    COUNT(DISTINCT bridge.supplier_group_id)
        AS resolved_supplier_group_count

FROM core.supplier_site_bridge AS bridge
INNER JOIN core.site_master AS site
    ON bridge.site_id = site.site_id
GROUP BY
    site.country_standardized,
    bridge.product_type_standardized;

-- 5. Compare source-supplier and resolved-group concentration.
-- Weight each entity by its governed relationship count.
-- HHI uses the 0-to-1 scale.

CREATE VIEW analytics.vw_supplier_country_product_concentration AS

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
        COUNT(*) AS relationship_count
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
        COUNT(*) AS relationship_count
    FROM relationship_base
    GROUP BY
        country_standardized,
        product_type_standardized,
        supplier_group_id
),

entity_shares AS (
    SELECT
        country_standardized,
        product_type_standardized,
        supplier_basis,
        entity_id,
        relationship_count,

        CAST(relationship_count AS NUMERIC)
            / NULLIF(
                SUM(relationship_count) OVER (
                    PARTITION BY
                        country_standardized,
                        product_type_standardized,
                        supplier_basis
                ),
                0
            ) AS relationship_share

    FROM entity_counts
)

SELECT
    country_standardized,
    product_type_standardized,
    supplier_basis,
    COUNT(*) AS entity_count,
    SUM(relationship_count) AS relationship_count,
    MAX(relationship_share) AS largest_entity_relationship_share,

    SUM(relationship_share * relationship_share)
        AS relationship_hhi

FROM entity_shares
GROUP BY
    country_standardized,
    product_type_standardized,
    supplier_basis;

-- 6. Measure supplier overlap at each official Site ID.
-- Preserve official Site IDs, including sites retained separately
-- after physical-site review.

CREATE VIEW analytics.vw_site_supplier_overlap AS

WITH site_supplier_counts AS (

    SELECT
        bridge.site_id,
        COUNT(*) AS relationship_count,
        COUNT(DISTINCT bridge.supplier_id)
            AS source_supplier_count,
        COUNT(DISTINCT bridge.supplier_group_id)
            AS resolved_supplier_group_count

    FROM core.supplier_site_bridge AS bridge

    GROUP BY
        bridge.site_id

)

SELECT
    site.site_id,
    site.site_name_canonical,
    site.country_standardized,
    site.product_type_standardized,

    supplier_counts.relationship_count,
    supplier_counts.source_supplier_count,
    supplier_counts.resolved_supplier_group_count,

    CASE
        WHEN supplier_counts.source_supplier_count > 1 THEN 1
        ELSE 0
    END AS source_supplier_shared_site_flag,

    CASE
        WHEN supplier_counts.resolved_supplier_group_count > 1 THEN 1
        ELSE 0
    END AS resolved_group_shared_site_flag,

    site.physical_site_review_flag,
    site.physical_site_review_status,
    site.responsible_sourcing_review_flag

FROM core.site_master AS site

INNER JOIN site_supplier_counts AS supplier_counts
    ON site.site_id = supplier_counts.site_id;

-- 7. Measure declared sourcing-channel reach by country and product.
-- Channel links do not establish site ownership.
-- A site may appear under more than one channel.

CREATE VIEW analytics.vw_supplier_channel_country_product_footprint AS

WITH channel_counts AS (

    SELECT
        site.country_standardized,
        bridge.product_type_standardized,
        bridge.declared_channel_type,

        COUNT(*) AS relationship_count,

        COUNT(DISTINCT bridge.site_id)
            AS distinct_site_count,

        COUNT(DISTINCT bridge.supplier_id)
            AS source_supplier_count,

        COUNT(DISTINCT bridge.supplier_group_id)
            AS resolved_supplier_group_count

    FROM core.supplier_site_bridge AS bridge

    INNER JOIN core.site_master AS site
        ON bridge.site_id = site.site_id

    GROUP BY
        site.country_standardized,
        bridge.product_type_standardized,
        bridge.declared_channel_type

)

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

INNER JOIN analytics.vw_supplier_country_product_footprint AS footprint
    ON channel.country_standardized =
        footprint.country_standardized
    AND channel.product_type_standardized =
        footprint.product_type_standardized;

-- 8. Summarise site data coverage, review flags and ownership.
-- Count each official Site ID once.
-- Employee totals cover listed sites, not workers dedicated to NEXT.
-- Missing ownership evidence does not establish external ownership.

CREATE VIEW analytics.vw_site_country_product_profile AS

SELECT
    site.country_standardized,
    site.product_type_standardized,

    COUNT(*) AS site_count,

    COUNT(site.total_employees)
        AS employee_data_available_site_count,

    SUM(
        CASE
            WHEN site.total_employees IS NULL THEN 1
            ELSE 0
        END
    ) AS employee_data_missing_site_count,

    SUM(site.total_employees)
        AS reported_total_employees,

    SUM(site.responsible_sourcing_review_flag)
        AS responsible_sourcing_review_site_count,

    SUM(site.physical_site_review_flag)
        AS physical_site_review_site_count,

    SUM(
        CASE
            WHEN site.site_owner_group = 'NEXT_GROUP'
                AND site.site_ownership_status =
                    'Confirmed group-owned manufacturing operation'
                THEN 1
            ELSE 0
        END
    ) AS confirmed_next_owned_site_count

FROM core.site_master AS site

GROUP BY
    site.country_standardized,
    site.product_type_standardized;

-- 9. Prepare monthly partner and World data for review sensitivity.
-- Preserve all rows and identify eligibility for the sensitivity.
-- Exclude matching partner and World measures together.

CREATE VIEW analytics.vw_partner_trade_monthly_review_basis AS

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
    AND monthly.cn8_code = world.cn8_code;

-- 10. Build period-level REVIEW-exclusion sensitivity.
-- Apply the same retained months to partner and World measures.
-- Preserve period rows even if no months qualify.

CREATE VIEW analytics.vw_partner_trade_period_review_sensitivity AS

WITH period_rows AS (

    SELECT
        'FULL_YEAR' AS period_type,
        monthly.*

    FROM analytics.vw_partner_trade_monthly_review_basis AS monthly

    INNER JOIN core.dim_month AS month_dim
        ON monthly.month_id = month_dim.month_id

    WHERE month_dim.complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        monthly.*

    FROM analytics.vw_partner_trade_monthly_review_basis AS monthly

    INNER JOIN core.dim_month AS month_dim
        ON monthly.month_id = month_dim.month_id

    WHERE month_dim.like_for_like_h1_flag = 1

),

period_totals AS (

    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code,

        COUNT(*) AS baseline_month_count,

        SUM(review_sensitivity_inclusion_flag)
            AS retained_month_count,

        SUM(1 - review_sensitivity_inclusion_flag)
            AS excluded_month_count,

        SUM(
            CASE
                WHEN review_sensitivity_inclusion_flag = 1
                    AND record_status = 'NO_API_RECORD'
                    THEN 1
                ELSE 0
            END
        ) AS retained_no_api_month_count,

        SUM(
            CASE
                WHEN review_sensitivity_inclusion_flag = 1
                    THEN import_value_gbp
            END
        ) AS retained_import_value_gbp,

        SUM(
            CASE
                WHEN review_sensitivity_inclusion_flag = 1
                    THEN net_mass_kg
            END
        ) AS retained_net_mass_kg,

        SUM(
            CASE
                WHEN review_sensitivity_inclusion_flag = 1
                    THEN world_import_value_gbp
            END
        ) AS retained_world_import_value_gbp

    FROM period_rows

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        cn8_code

)

SELECT
    sensitivity.period_type,
    sensitivity.calendar_year,
    sensitivity.partner_country_id,
    reported.partner_country_iso2,
    reported.partner_country_name,
    sensitivity.cn8_code,

    sensitivity.baseline_month_count,
    sensitivity.retained_month_count,
    sensitivity.excluded_month_count,
    sensitivity.retained_no_api_month_count,

    reported.total_import_value_gbp
        AS reported_import_value_gbp,

    sensitivity.retained_import_value_gbp,
    sensitivity.retained_net_mass_kg,
    sensitivity.retained_world_import_value_gbp,

    reported.weighted_unit_value_gbp_per_kg
        AS reported_weighted_unit_value_gbp_per_kg,

    sensitivity.retained_import_value_gbp
        / NULLIF(sensitivity.retained_net_mass_kg, 0)
        AS retained_weighted_unit_value_gbp_per_kg,

    reported.world_import_share
        AS reported_world_import_share,

    sensitivity.retained_import_value_gbp
        / NULLIF(sensitivity.retained_world_import_value_gbp, 0)
        AS retained_world_import_share,

    (
        sensitivity.retained_import_value_gbp
            / NULLIF(sensitivity.retained_world_import_value_gbp, 0)
        - reported.world_import_share
    ) * 100 AS world_share_sensitivity_change_pp

FROM period_totals AS sensitivity

INNER JOIN analytics.vw_partner_trade_period_reported AS reported
    ON sensitivity.period_type = reported.period_type
    AND sensitivity.calendar_year = reported.calendar_year
    AND sensitivity.partner_country_id = reported.partner_country_id
    AND sensitivity.cn8_code = reported.cn8_code;

-- 11. Calculate year-on-year sensitivity using matched months.
-- Retain a calendar month only when both years qualify.
-- Apply the same months to partner and World measures.

CREATE VIEW analytics.vw_partner_trade_period_growth_review_sensitivity AS

WITH period_rows AS (

    SELECT
        'FULL_YEAR' AS period_type,
        monthly.*

    FROM analytics.vw_partner_trade_monthly_review_basis AS monthly

    INNER JOIN core.dim_month AS month_dim
        ON monthly.month_id = month_dim.month_id

    WHERE month_dim.complete_calendar_year_flag = 1

    UNION ALL

    SELECT
        'H1' AS period_type,
        monthly.*

    FROM analytics.vw_partner_trade_monthly_review_basis AS monthly

    INNER JOIN core.dim_month AS month_dim
        ON monthly.month_id = month_dim.month_id

    WHERE month_dim.like_for_like_h1_flag = 1

),

paired_months AS (

    SELECT
        current_period.period_type,
        current_period.calendar_year,
        current_period.partner_country_id,
        current_period.partner_country_iso2,
        current_period.partner_country_name,
        current_period.cn8_code,

        previous_period.import_value_gbp
            AS previous_import_value_gbp,

        current_period.import_value_gbp
            AS current_import_value_gbp,

        previous_period.world_import_value_gbp
            AS previous_world_import_value_gbp,

        current_period.world_import_value_gbp
            AS current_world_import_value_gbp,

        CASE
            WHEN current_period.review_sensitivity_inclusion_flag = 1
                AND previous_period.review_sensitivity_inclusion_flag = 1
                THEN 1
            ELSE 0
        END AS matched_month_inclusion_flag

    FROM period_rows AS current_period

    INNER JOIN period_rows AS previous_period
        ON current_period.partner_country_id =
            previous_period.partner_country_id
        AND current_period.cn8_code = previous_period.cn8_code
        AND current_period.period_type = previous_period.period_type
        AND current_period.calendar_month =
            previous_period.calendar_month
        AND previous_period.calendar_year =
            current_period.calendar_year - 1

),

period_totals AS (

    SELECT
        period_type,
        calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code,

        COUNT(*) AS baseline_month_pair_count,

        SUM(matched_month_inclusion_flag)
            AS retained_month_pair_count,

        SUM(1 - matched_month_inclusion_flag)
            AS excluded_month_pair_count,

        SUM(previous_import_value_gbp)
            FILTER (WHERE matched_month_inclusion_flag = 1)
            AS previous_retained_import_value_gbp,

        SUM(current_import_value_gbp)
            FILTER (WHERE matched_month_inclusion_flag = 1)
            AS current_retained_import_value_gbp,

        SUM(previous_world_import_value_gbp)
            FILTER (WHERE matched_month_inclusion_flag = 1)
            AS previous_retained_world_import_value_gbp,

        SUM(current_world_import_value_gbp)
            FILTER (WHERE matched_month_inclusion_flag = 1)
            AS current_retained_world_import_value_gbp

    FROM paired_months

    GROUP BY
        period_type,
        calendar_year,
        partner_country_id,
        partner_country_iso2,
        partner_country_name,
        cn8_code

)

SELECT
    totals.*,

    totals.calendar_year - 1 AS previous_calendar_year,

    (
        totals.current_retained_import_value_gbp
            - totals.previous_retained_import_value_gbp
    )
        / NULLIF(totals.previous_retained_import_value_gbp, 0)
        * 100 AS retained_import_value_growth_pct,

    totals.previous_retained_import_value_gbp
        / NULLIF(totals.previous_retained_world_import_value_gbp, 0)
        * 100 AS previous_retained_world_share_pct,

    totals.current_retained_import_value_gbp
        / NULLIF(totals.current_retained_world_import_value_gbp, 0)
        * 100 AS current_retained_world_share_pct,

    (
        totals.current_retained_import_value_gbp
            / NULLIF(totals.current_retained_world_import_value_gbp, 0)
        - totals.previous_retained_import_value_gbp
            / NULLIF(totals.previous_retained_world_import_value_gbp, 0)
    ) * 100 AS retained_world_share_change_pp

FROM period_totals AS totals;
