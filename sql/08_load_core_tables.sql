-- Load all fourteen core tables in dependency order.
-- Run once against empty core tables after staging validation.
-- Validate the resulting data with script 09.

-- 1. Load commodity dimension.
-- Preserve all five codes and their inclusion statuses:
-- four active core codes and one inactive reserve code.

INSERT INTO core.dim_commodity (
    cn8_code,
    hs2_code,
    hs4_code,
    hs6_code,
    description,
    construction,
    fibre,
    basket_role,
    inclusion_status
)
SELECT
    cn8_code,
    hs2_code,
    hs4_code,
    hs6_code,
    description,
    construction,
    fibre,
    basket_role,
    inclusion_status
FROM staging.wp005_dim_commodity;

-- 2. Load partner-country dimension.

INSERT INTO core.dim_partner_country (
    partner_country_id,
    country_code_numeric,
    partner_country_iso2,
    partner_country_name,
    hmrc_flow_type_id,
    scope_status,
    geographical_basis
)
SELECT
    CAST(partner_country_id AS INTEGER),
    country_code_numeric,
    partner_country_iso2,
    partner_country_name,
    CAST(hmrc_flow_type_id AS INTEGER),
    scope_status,
    geographical_basis
FROM staging.wp005_dim_partner_country;

-- 3. Load month dimension.

INSERT INTO core.dim_month (
    month_id,
    month_date,
    calendar_year,
    month_number,
    month_name,
    calendar_quarter,
    half_year,
    complete_calendar_year_flag,
    ytd_2026_flag,
    like_for_like_h1_flag
)
SELECT
    CAST(month_id AS INTEGER),
    MAKE_DATE(
        CAST(calendar_year AS INTEGER),
        CAST(month_number AS INTEGER),
        1
    ),
    CAST(calendar_year AS INTEGER),
    CAST(month_number AS INTEGER),
    month_name,
    calendar_quarter,
    half_year,
    CAST(complete_calendar_year_flag AS SMALLINT),
    CAST(ytd_2026_flag AS SMALLINT),
    CAST(like_for_like_h1_flag AS SMALLINT)
FROM staging.wp005_dim_month;

-- 4. Load typed partner source observations.

INSERT INTO core.raw_partner_monthly (
    source_query_id,
    source_record_no,
    month_id,
    commodity_id,
    country_id,
    flow_type_id,
    suppression_index,
    supp_unit,
    net_mass,
    value_gbp,
    source_file
)
SELECT
    source_query_id,
    CAST(source_record_no AS INTEGER),
    CAST(month_id AS INTEGER),
    commodity_id,
    CAST(country_id AS INTEGER),
    CAST(flow_type_id AS INTEGER),
    CAST(suppression_index AS INTEGER),
    CAST(REPLACE(supp_unit, ',', '') AS NUMERIC(20, 6)),
    CAST(REPLACE(net_mass, ',', '') AS NUMERIC(20, 6)),
    CAST(REPLACE(value_gbp, ',', '') AS NUMERIC(20, 6)),
    source_file
FROM staging.wp005_raw_partner_monthly;

-- 5. Load typed World source observations.

INSERT INTO core.raw_world_monthly (
    source_query_id,
    source_record_no,
    month_id,
    commodity_id,
    flow_type_id,
    suppression_index,
    supp_unit,
    net_mass,
    value_gbp,
    source_file
)
SELECT
    source_query_id,
    CAST(source_record_no AS INTEGER),
    CAST(month_id AS INTEGER),
    commodity_id,
    CAST(flow_type_id AS INTEGER),
    CAST(suppression_index AS INTEGER),
    CAST(REPLACE(supp_unit, ',', '') AS NUMERIC(20, 6)),
    CAST(REPLACE(net_mass, ',', '') AS NUMERIC(20, 6)),
    CAST(REPLACE(value_gbp, ',', '') AS NUMERIC(20, 6)),
    source_file
FROM staging.wp005_raw_world_monthly;

-- 6. Rebuild World monthly facts from typed source observations.
-- The staging fact export contains rounded display strings.
-- Recalculate derived measures using the governed WP005 rules.
-- Retain all observations, including those labelled REVIEW.

WITH world_components AS (
    SELECT
        commodity_id AS cn8_code,
        month_id,

        SUM(CASE WHEN flow_type_id = 1
            THEN value_gbp ELSE 0 END) AS eu_import_value_gbp,
        SUM(CASE WHEN flow_type_id = 3
            THEN value_gbp ELSE 0 END) AS non_eu_import_value_gbp,
        SUM(value_gbp) AS world_import_value_gbp,

        SUM(CASE WHEN flow_type_id = 1
            THEN net_mass ELSE 0 END) AS eu_net_mass_kg,
        SUM(CASE WHEN flow_type_id = 3
            THEN net_mass ELSE 0 END) AS non_eu_net_mass_kg,
        SUM(net_mass) AS world_net_mass_kg,

        SUM(CASE WHEN flow_type_id = 1
            THEN supp_unit ELSE 0 END) AS eu_supplementary_quantity,
        SUM(CASE WHEN flow_type_id = 3
            THEN supp_unit ELSE 0 END) AS non_eu_supplementary_quantity,
        SUM(supp_unit) AS world_supplementary_quantity,

        STRING_AGG(
            DISTINCT CAST(suppression_index AS TEXT),
            ', ' ORDER BY CAST(suppression_index AS TEXT)
        ) FILTER (WHERE flow_type_id = 1)
            AS eu_suppression_index_list,

        STRING_AGG(
            DISTINCT CAST(suppression_index AS TEXT),
            ', ' ORDER BY CAST(suppression_index AS TEXT)
        ) FILTER (WHERE flow_type_id = 3)
            AS non_eu_suppression_index_list,

        MAX(CASE WHEN suppression_index <> 0
            THEN 1 ELSE 0 END) AS suppression_flag,

        STRING_AGG(
            DISTINCT source_query_id,
            ', ' ORDER BY source_query_id
        ) AS source_query_id,

        STRING_AGG(
            DISTINCT source_file,
            ', ' ORDER BY source_file
        ) AS source_file

    FROM core.raw_world_monthly
    GROUP BY
        commodity_id,
        month_id
),

world_unit_values AS (
    SELECT
        wc.*,
        CASE
            WHEN world_net_mass_kg > 0
            THEN world_import_value_gbp / world_net_mass_kg
            ELSE NULL
        END AS unit_value_gbp_per_kg
    FROM world_components AS wc
),

world_medians AS (
    SELECT
        cn8_code,
        CAST(
            PERCENTILE_CONT(0.5)
                WITHIN GROUP (ORDER BY unit_value_gbp_per_kg)
            AS NUMERIC
        ) AS reference_median
    FROM world_unit_values
    GROUP BY cn8_code
),

world_ratios AS (
    SELECT
        uv.*,
        CASE
            WHEN uv.unit_value_gbp_per_kg IS NOT NULL
            THEN med.reference_median
            ELSE NULL
        END AS reference_median_unit_value_gbp_per_kg,

        uv.unit_value_gbp_per_kg
            / NULLIF(med.reference_median, 0)
            AS unit_value_ratio_to_reference_median

    FROM world_unit_values AS uv
    INNER JOIN world_medians AS med
        ON uv.cn8_code = med.cn8_code
)

INSERT INTO core.fct_hmrc_world_monthly (
    world_monthly_key,
    month_date,
    month_id,
    calendar_year,
    calendar_month,
    cn8_code,
    hs4_code,
    eu_import_value_gbp,
    non_eu_import_value_gbp,
    world_import_value_gbp,
    eu_net_mass_kg,
    non_eu_net_mass_kg,
    world_net_mass_kg,
    eu_supplementary_quantity,
    non_eu_supplementary_quantity,
    world_supplementary_quantity,
    unit_value_gbp_per_kg,
    eu_suppression_index_list,
    non_eu_suppression_index_list,
    suppression_flag,
    source_query_id,
    source_file,
    reference_median_unit_value_gbp_per_kg,
    unit_value_ratio_to_reference_median,
    unit_value_review_flag_2_5x
)
SELECT
    wr.cn8_code || '_WORLD_'
        || CAST(wr.month_id AS TEXT) || '_IMPORT',
    dm.month_date,
    wr.month_id,
    dm.calendar_year,
    dm.month_number,
    wr.cn8_code,
    dc.hs4_code,
    wr.eu_import_value_gbp,
    wr.non_eu_import_value_gbp,
    wr.world_import_value_gbp,
    wr.eu_net_mass_kg,
    wr.non_eu_net_mass_kg,
    wr.world_net_mass_kg,
    wr.eu_supplementary_quantity,
    wr.non_eu_supplementary_quantity,
    wr.world_supplementary_quantity,
    wr.unit_value_gbp_per_kg,
    wr.eu_suppression_index_list,
    wr.non_eu_suppression_index_list,
    wr.suppression_flag,
    wr.source_query_id,
    wr.source_file,
    wr.reference_median_unit_value_gbp_per_kg,
    wr.unit_value_ratio_to_reference_median,
    CASE
        WHEN wr.unit_value_ratio_to_reference_median IS NULL
            THEN 'NOT_APPLICABLE'
        WHEN wr.unit_value_ratio_to_reference_median < 0.4
            OR wr.unit_value_ratio_to_reference_median > 2.5
            THEN 'REVIEW'
        ELSE 'WITHIN_BAND'
    END
FROM world_ratios AS wr
INNER JOIN core.dim_month AS dm
    ON wr.month_id = dm.month_id
INNER JOIN core.dim_commodity AS dc
    ON wr.cn8_code = dc.cn8_code;

-- 7. Rebuild partner monthly facts.
-- Preserve the governed 3,600-row panel.
-- Recalculate measures and diagnostics from typed observations.
-- NO_API_RECORD zeros are analytical placeholders.

WITH partner_source_totals AS (
    SELECT
        commodity_id AS cn8_code,
        country_id AS partner_country_id,
        month_id,
        flow_type_id,
        SUM(value_gbp) AS import_value_gbp,
        SUM(net_mass) AS net_mass_kg,
        SUM(supp_unit) AS supplementary_quantity,

        STRING_AGG(
            DISTINCT CAST(suppression_index AS TEXT),
            ', ' ORDER BY CAST(suppression_index AS TEXT)
        ) AS suppression_index_list,

        MAX(CASE WHEN suppression_index <> 0
            THEN 1 ELSE 0 END) AS suppression_flag

    FROM core.raw_partner_monthly
    GROUP BY
        commodity_id,
        country_id,
        month_id,
        flow_type_id
),

partner_panel AS (
    SELECT
        monthly_import_key,
        CAST(month_id AS INTEGER) AS month_id,
        cn8_code,
        CAST(partner_country_id AS INTEGER) AS partner_country_id,
        CAST(flow_type_id AS INTEGER) AS flow_type_id,
        source_query_id,
        source_file
    FROM staging.wp005_fct_partner_monthly
),

partner_base AS (
    SELECT
        p.monthly_import_key,
        dm.month_date,
        p.month_id,
        dm.calendar_year,
        dm.month_number AS calendar_month,
        p.cn8_code,
        dc.hs4_code,
        p.partner_country_id,
        country.partner_country_iso2,
        country.partner_country_name,
        'IMPORT' AS flow,
        p.flow_type_id,

        CASE WHEN r.partner_country_id IS NULL
            THEN 0 ELSE 1 END AS api_row_present_flag,

        CASE WHEN r.partner_country_id IS NULL
            THEN 'NO_API_RECORD'
            ELSE 'REPORTED' END AS record_status,

        r.suppression_index_list,
        COALESCE(r.suppression_flag, 0) AS suppression_flag,
        COALESCE(r.import_value_gbp, 0) AS import_value_gbp,
        COALESCE(r.net_mass_kg, 0) AS net_mass_kg,
        COALESCE(r.supplementary_quantity, 0)
            AS supplementary_quantity,

        world.world_import_value_gbp,
        p.source_query_id,
        p.source_file

    FROM partner_panel AS p

    LEFT JOIN partner_source_totals AS r
        ON p.cn8_code = r.cn8_code
        AND p.partner_country_id = r.partner_country_id
        AND p.month_id = r.month_id
        AND p.flow_type_id = r.flow_type_id

    INNER JOIN core.dim_month AS dm
        ON p.month_id = dm.month_id

    INNER JOIN core.dim_commodity AS dc
        ON p.cn8_code = dc.cn8_code

    INNER JOIN core.dim_partner_country AS country
        ON p.partner_country_id = country.partner_country_id

    INNER JOIN core.fct_hmrc_world_monthly AS world
        ON p.cn8_code = world.cn8_code
        AND p.month_id = world.month_id
),

partner_unit_values AS (
    SELECT
        b.*,

        CASE
            WHEN net_mass_kg > 0 THEN 'USABLE'
            WHEN import_value_gbp > 0 THEN 'VALUE_WITHOUT_MASS'
            ELSE 'NO_REPORTED_TRADE'
        END AS mass_status,

        CASE
            WHEN net_mass_kg > 0
            THEN import_value_gbp / net_mass_kg
            ELSE NULL
        END AS unit_value_gbp_per_kg,

        CASE
            WHEN world_import_value_gbp > 0
            THEN import_value_gbp / world_import_value_gbp
            ELSE NULL
        END AS partner_value_share

    FROM partner_base AS b
),

partner_medians AS (
    SELECT
        cn8_code,
        partner_country_id,
        CAST(
            PERCENTILE_CONT(0.5)
                WITHIN GROUP (ORDER BY unit_value_gbp_per_kg)
            AS NUMERIC
        ) AS reference_median
    FROM partner_unit_values
    GROUP BY
        cn8_code,
        partner_country_id
),

partner_ratios AS (
    SELECT
        uv.*,

        CASE
            WHEN uv.unit_value_gbp_per_kg IS NOT NULL
            THEN med.reference_median
            ELSE NULL
        END AS reference_median_unit_value_gbp_per_kg,

        uv.unit_value_gbp_per_kg
            / NULLIF(med.reference_median, 0)
            AS unit_value_ratio_to_reference_median

    FROM partner_unit_values AS uv
    INNER JOIN partner_medians AS med
        ON uv.cn8_code = med.cn8_code
        AND uv.partner_country_id = med.partner_country_id
)

INSERT INTO core.fct_hmrc_import_monthly (
    monthly_import_key,
    month_date,
    month_id,
    calendar_year,
    calendar_month,
    cn8_code,
    hs4_code,
    partner_country_id,
    partner_country_iso2,
    partner_country_name,
    flow,
    flow_type_id,
    api_row_present_flag,
    record_status,
    suppression_index_list,
    suppression_flag,
    import_value_gbp,
    net_mass_kg,
    supplementary_quantity,
    mass_status,
    unit_value_gbp_per_kg,
    world_import_value_gbp,
    partner_value_share,
    source_query_id,
    source_file,
    reference_median_unit_value_gbp_per_kg,
    unit_value_ratio_to_reference_median,
    unit_value_review_flag_2_5x
)
SELECT
    monthly_import_key,
    month_date,
    month_id,
    calendar_year,
    calendar_month,
    cn8_code,
    hs4_code,
    partner_country_id,
    partner_country_iso2,
    partner_country_name,
    flow,
    flow_type_id,
    api_row_present_flag,
    record_status,
    suppression_index_list,
    suppression_flag,
    import_value_gbp,
    net_mass_kg,
    supplementary_quantity,
    mass_status,
    unit_value_gbp_per_kg,
    world_import_value_gbp,
    partner_value_share,
    source_query_id,
    source_file,
    reference_median_unit_value_gbp_per_kg,
    unit_value_ratio_to_reference_median,

    CASE
        WHEN record_status <> 'REPORTED'
            OR unit_value_ratio_to_reference_median IS NULL
            THEN 'NOT_APPLICABLE'
        WHEN unit_value_ratio_to_reference_median < 0.4
            OR unit_value_ratio_to_reference_median > 2.5
            THEN 'REVIEW'
        ELSE 'WITHIN_BAND'
    END

FROM partner_ratios;

-- 8. Load source supplier identities.

INSERT INTO core.supplier_master (
    supplier_id,
    supplier_name_canonical,
    supplier_name_variants,
    raw_name_variant_count,
    distinct_site_count,
    distinct_country_count,
    relationship_count,
    product_types,
    source_id,
    snapshot_month
)
SELECT
    supplier_id,
    supplier_name_canonical,
    supplier_name_variants,
    CAST(REPLACE(raw_name_variant_count, ',', '') AS INTEGER),
    CAST(REPLACE(distinct_site_count, ',', '') AS INTEGER),
    CAST(REPLACE(distinct_country_count, ',', '') AS INTEGER),
    CAST(REPLACE(relationship_count, ',', '') AS INTEGER),
    product_types,
    source_id,
    snapshot_month
FROM staging.wp003_supplier_master;

-- 9. Load resolved supplier groups.

INSERT INTO core.supplier_group_master (
    supplier_group_id,
    supplier_group_name_canonical,
    member_supplier_ids,
    member_supplier_names,
    source_supplier_id_count,
    distinct_site_count,
    distinct_country_count,
    relationship_count,
    product_types,
    parent_group_ids,
    source_id,
    snapshot_month
)
SELECT
    supplier_group_id,
    supplier_group_name_canonical,
    member_supplier_ids,
    member_supplier_names,
    CAST(REPLACE(source_supplier_id_count, ',', '') AS INTEGER),
    CAST(REPLACE(distinct_site_count, ',', '') AS INTEGER),
    CAST(REPLACE(distinct_country_count, ',', '') AS INTEGER),
    CAST(REPLACE(relationship_count, ',', '') AS INTEGER),
    product_types,
    parent_group_ids,
    source_id,
    snapshot_month
FROM staging.wp003_supplier_group_master;

-- 10. Load source-supplier-to-group assignments.

INSERT INTO core.supplier_resolution_map (
    supplier_id,
    supplier_name_source_canonical,
    supplier_group_id,
    supplier_group_name_canonical,
    resolution_rule,
    review_status,
    match_confidence,
    evidence_note,
    source_id,
    snapshot_month
)
SELECT
    supplier_id,
    supplier_name_source_canonical,
    supplier_group_id,
    supplier_group_name_canonical,
    resolution_rule,
    review_status,
    CAST(TRIM(match_confidence) AS NUMERIC),
    evidence_note,
    source_id,
    snapshot_month
FROM staging.wp003_supplier_resolution_map;

-- 11. Load supplier entity and channel classifications.

INSERT INTO core.supplier_entity_map (
    supplier_id,
    supplier_name_canonical,
    entity_role,
    parent_group_id,
    ownership_status,
    relationship_count,
    distinct_site_count,
    parent_group_relationship_count,
    parent_group_first_flag,
    parent_group_hhi_contribution,
    evidence_source_id,
    evidence_reference,
    classification_confidence,
    review_status,
    classification_note
)
SELECT
    supplier_id,
    supplier_name_canonical,
    entity_role,
    parent_group_id,
    ownership_status,
    CAST(REPLACE(relationship_count, ',', '') AS INTEGER),
    CAST(REPLACE(distinct_site_count, ',', '') AS INTEGER),
    CAST(REPLACE(parent_group_relationship_count, ',', '') AS INTEGER),
    CAST(TRIM(parent_group_first_flag) AS SMALLINT),
    CAST(
        REPLACE(TRIM(parent_group_hhi_contribution), ',', '')
        AS NUMERIC
    ),
    evidence_source_id,
    evidence_reference,
    classification_confidence,
    review_status,
    classification_note
FROM staging.wp003_supplier_entity_map;

-- 12. Load site master.
-- Preserve missing employee counts as NULL.
-- Normalize only the two documented physical-review flag exceptions.

INSERT INTO core.site_master (
    site_id,
    country_raw,
    country_standardized,
    country_variants,
    site_name_canonical,
    site_name_variants,
    address_canonical,
    address_variants,
    product_type_standardized,
    female_employees,
    male_employees,
    total_employees,
    employee_data_status,
    trade_union_flag,
    workers_committee_flag,
    supplier_count,
    source_record_count,
    site_consistency_flag,
    source_record_ids,
    source_id,
    snapshot_month,
    apparel_site_flag,
    home_site_flag,
    mixed_product_site_flag,
    employee_available_site_flag,
    trade_union_yes_site_flag,
    workers_committee_yes_site_flag,
    shared_site_flag,
    site_consistency_review_flag,
    audit_annotation_raw,
    site_audit_status,
    responsible_sourcing_review_flag,
    physical_site_review_flag,
    physical_site_review_status,
    physical_site_group_id,
    site_owner_group,
    site_ownership_status,
    site_ownership_evidence_source_id,
    site_ownership_evidence_reference,
    site_ownership_confidence
)
SELECT
    site_id,
    country_raw,
    country_standardized,
    country_variants,
    site_name_canonical,
    site_name_variants,
    address_canonical,
    address_variants,
    product_type_standardized,

    CAST(
        NULLIF(REPLACE(TRIM(female_employees), ',', ''), '')
        AS INTEGER
    ),
    CAST(
        NULLIF(REPLACE(TRIM(male_employees), ',', ''), '')
        AS INTEGER
    ),
    CAST(
        NULLIF(REPLACE(TRIM(total_employees), ',', ''), '')
        AS INTEGER
    ),

    employee_data_status,
    trade_union_flag,
    workers_committee_flag,
    CAST(REPLACE(supplier_count, ',', '') AS INTEGER),
    CAST(REPLACE(source_record_count, ',', '') AS INTEGER),
    site_consistency_flag,
    source_record_ids,
    source_id,
    snapshot_month,

    CAST(TRIM(apparel_site_flag) AS SMALLINT),
    CAST(TRIM(home_site_flag) AS SMALLINT),
    CAST(TRIM(mixed_product_site_flag) AS SMALLINT),
    CAST(TRIM(employee_available_site_flag) AS SMALLINT),
    CAST(TRIM(trade_union_yes_site_flag) AS SMALLINT),
    CAST(TRIM(workers_committee_yes_site_flag) AS SMALLINT),
    CAST(TRIM(shared_site_flag) AS SMALLINT),
    CAST(TRIM(site_consistency_review_flag) AS SMALLINT),

    NULLIF(TRIM(audit_annotation_raw), ''),
    site_audit_status,
    CAST(TRIM(responsible_sourcing_review_flag) AS SMALLINT),

    CASE
        WHEN TRIM(physical_site_review_flag) IN ('0', '1')
            THEN CAST(TRIM(physical_site_review_flag) AS SMALLINT)

        WHEN site_id IN ('20221', '24006')
            AND TRIM(physical_site_review_flag) =
                'Probable co-location - retained as separate official Site IDs'
            AND TRIM(physical_site_review_status) =
                'Closed - retained separate'
            THEN CAST(1 AS SMALLINT)

        ELSE NULL
    END,

    NULLIF(TRIM(physical_site_review_status), ''),
    NULLIF(TRIM(physical_site_group_id), ''),
    NULLIF(TRIM(site_owner_group), ''),
    NULLIF(TRIM(site_ownership_status), ''),
    NULLIF(TRIM(site_ownership_evidence_source_id), ''),
    NULLIF(TRIM(site_ownership_evidence_reference), ''),
    NULLIF(TRIM(site_ownership_confidence), '')

FROM staging.wp003_site_master;

-- 13. Load raw Tier 1 supplier-site observations.
-- Preserve source text, duplicate flags and audit annotations.

INSERT INTO core.raw_tier1_relationships (
    source_record_id,
    source_id,
    source_file,
    source_page,
    source_row_on_page,
    pdf_table_row,
    site_id_raw,
    country_raw,
    supplier_name_raw,
    site_name_raw,
    address_raw,
    product_type_raw,
    female_employees_raw,
    male_employees_raw,
    trade_union_raw,
    workers_committee_raw,
    extraction_status,
    extraction_note,
    exact_duplicate_group_count,
    exact_duplicate_flag,
    supplier_id,
    supplier_name_canonical,
    audit_annotation_raw
)
SELECT
    source_record_id,
    source_id,
    source_file,

    CAST(REPLACE(TRIM(source_page), ',', '') AS INTEGER),
    CAST(REPLACE(TRIM(source_row_on_page), ',', '') AS INTEGER),
    CAST(REPLACE(TRIM(pdf_table_row), ',', '') AS INTEGER),

    site_id_raw,
    country_raw,
    supplier_name_raw,
    site_name_raw,
    address_raw,
    product_type_raw,
    female_employees_raw,
    male_employees_raw,
    trade_union_raw,
    workers_committee_raw,
    extraction_status,
    extraction_note,

    CAST(
        REPLACE(TRIM(exact_duplicate_group_count), ',', '')
        AS INTEGER
    ),

    exact_duplicate_flag,
    supplier_id,
    supplier_name_canonical,
    audit_annotation_raw

FROM staging.wp003_raw_tier1_relationships;

-- 14. Load governed supplier-site-product relationships.
-- Preserve source-record lineage and supplier-group assignments.

INSERT INTO core.supplier_site_bridge (
    relationship_id,
    supplier_id,
    supplier_name_canonical,
    site_id,
    country_raw,
    product_type_standardized,
    source_record_id,
    source_record_ids,
    source_record_count,
    exact_duplicate_removed,
    relationship_review_status,
    source_id,
    snapshot_month,
    country_supplier_key,
    country_supplier_first_flag,
    parent_group_id,
    parent_group_site_first_flag,
    declared_channel_type,
    supplier_group_id,
    supplier_group_name_canonical
)
SELECT
    relationship_id,
    supplier_id,
    supplier_name_canonical,
    site_id,
    country_raw,
    product_type_standardized,
    source_record_id,
    source_record_ids,

    CAST(REPLACE(TRIM(source_record_count), ',', '') AS INTEGER),

    exact_duplicate_removed,
    relationship_review_status,
    source_id,
    snapshot_month,
    country_supplier_key,

    CAST(TRIM(country_supplier_first_flag) AS SMALLINT),

    parent_group_id,

    CAST(TRIM(parent_group_site_first_flag) AS SMALLINT),

    declared_channel_type,
    supplier_group_id,
    supplier_group_name_canonical

FROM staging.wp003_supplier_site_bridge;
