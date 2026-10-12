-- Validate typed core data against staging, source calculations and snapshot controls.
-- Expected counts refer to the current WP006 snapshot; see QC_SUMMARY.md.

-- 1. Validate supplier core row counts against staging and controls.

WITH row_counts AS (
    SELECT
        'supplier_master' AS table_name,
        672 AS expected_rows,
        (SELECT COUNT(*)
         FROM staging.wp003_supplier_master) AS staging_rows,
        COUNT(*) AS core_rows
    FROM core.supplier_master

    UNION ALL

    SELECT
        'supplier_group_master',
        661,
        (SELECT COUNT(*)
         FROM staging.wp003_supplier_group_master),
        COUNT(*)
    FROM core.supplier_group_master

    UNION ALL

    SELECT
        'supplier_resolution_map',
        672,
        (SELECT COUNT(*)
         FROM staging.wp003_supplier_resolution_map),
        COUNT(*)
    FROM core.supplier_resolution_map

    UNION ALL

    SELECT
        'supplier_entity_map',
        672,
        (SELECT COUNT(*)
         FROM staging.wp003_supplier_entity_map),
        COUNT(*)
    FROM core.supplier_entity_map

    UNION ALL

    SELECT
        'site_master',
        1478,
        (SELECT COUNT(*)
         FROM staging.wp003_site_master),
        COUNT(*)
    FROM core.site_master

    UNION ALL

    SELECT
        'raw_tier1_relationships',
        2202,
        (SELECT COUNT(*)
         FROM staging.wp003_raw_tier1_relationships),
        COUNT(*)
    FROM core.raw_tier1_relationships

    UNION ALL

    SELECT
        'supplier_site_bridge',
        2097,
        (SELECT COUNT(*)
         FROM staging.wp003_supplier_site_bridge),
        COUNT(*)
    FROM core.supplier_site_bridge
)
SELECT
    table_name,
    expected_rows,
    staging_rows,
    core_rows,
    core_rows - staging_rows AS row_difference,
    CASE
        WHEN staging_rows = expected_rows
            AND core_rows = expected_rows
            THEN 'PASS'
        ELSE 'FAIL'
    END AS check_status
FROM row_counts
ORDER BY table_name;

-- 2. Reconcile raw Tier 1 observations field by field.
-- Compare in both directions to detect missing or unexpected rows.

WITH expected_rows AS (
    SELECT
        source_record_id,
        source_id,
        source_file,
        CAST(REPLACE(TRIM(source_page), ',', '') AS INTEGER)
            AS source_page,
        CAST(REPLACE(TRIM(source_row_on_page), ',', '') AS INTEGER)
            AS source_row_on_page,
        CAST(REPLACE(TRIM(pdf_table_row), ',', '') AS INTEGER)
            AS pdf_table_row,
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
        ) AS exact_duplicate_group_count,
        exact_duplicate_flag,
        supplier_id,
        supplier_name_canonical,
        audit_annotation_raw
    FROM staging.wp003_raw_tier1_relationships
),

missing_or_changed AS (
    SELECT * FROM expected_rows

    EXCEPT ALL

    SELECT * FROM core.raw_tier1_relationships
),

unexpected_or_changed AS (
    SELECT * FROM core.raw_tier1_relationships

    EXCEPT ALL

    SELECT * FROM expected_rows
)

SELECT
    'raw_tier1_missing_or_changed' AS check_name,
    COUNT(*) AS exception_count
FROM missing_or_changed

UNION ALL

SELECT
    'raw_tier1_unexpected_or_changed',
    COUNT(*)
FROM unexpected_or_changed;

-- 3. Reconcile supplier-site bridge field by field.

WITH expected_rows AS (
    SELECT
        relationship_id,
        supplier_id,
        supplier_name_canonical,
        site_id,
        country_raw,
        product_type_standardized,
        source_record_id,
        source_record_ids,
        CAST(REPLACE(TRIM(source_record_count), ',', '') AS INTEGER)
            AS source_record_count,
        exact_duplicate_removed,
        relationship_review_status,
        source_id,
        snapshot_month,
        country_supplier_key,
        CAST(TRIM(country_supplier_first_flag) AS SMALLINT)
            AS country_supplier_first_flag,
        parent_group_id,
        CAST(TRIM(parent_group_site_first_flag) AS SMALLINT)
            AS parent_group_site_first_flag,
        declared_channel_type,
        supplier_group_id,
        supplier_group_name_canonical
    FROM staging.wp003_supplier_site_bridge
),

missing_or_changed AS (
    SELECT * FROM expected_rows

    EXCEPT ALL

    SELECT * FROM core.supplier_site_bridge
),

unexpected_or_changed AS (
    SELECT * FROM core.supplier_site_bridge

    EXCEPT ALL

    SELECT * FROM expected_rows
)

SELECT
    'bridge_missing_or_changed' AS check_name,
    COUNT(*) AS exception_count
FROM missing_or_changed

UNION ALL

SELECT
    'bridge_unexpected_or_changed',
    COUNT(*)
FROM unexpected_or_changed;

-- 4. Reconcile all source-supplier fields
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp003_supplier_master
),
expected_rows AS (
    SELECT
        CAST(supplier_id AS TEXT) AS supplier_id,
        CAST(supplier_name_canonical AS TEXT) AS supplier_name_canonical,
        CAST(supplier_name_variants AS TEXT) AS supplier_name_variants,
        CAST(raw_name_variant_count AS INTEGER) AS raw_name_variant_count,
        CAST(distinct_site_count AS INTEGER) AS distinct_site_count,
        CAST(distinct_country_count AS INTEGER) AS distinct_country_count,
        CAST(relationship_count AS INTEGER) AS relationship_count,
        CAST(product_types AS TEXT) AS product_types,
        CAST(source_id AS TEXT) AS source_id,
        CAST(snapshot_month AS TEXT) AS snapshot_month
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.supplier_master
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.supplier_master
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'supplier_master_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'supplier_master_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 5. Reconcile all resolved supplier-group fields
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp003_supplier_group_master
),
expected_rows AS (
    SELECT
        CAST(supplier_group_id AS TEXT) AS supplier_group_id,
        CAST(supplier_group_name_canonical AS TEXT) AS supplier_group_name_canonical,
        CAST(member_supplier_ids AS TEXT) AS member_supplier_ids,
        CAST(member_supplier_names AS TEXT) AS member_supplier_names,
        CAST(source_supplier_id_count AS INTEGER) AS source_supplier_id_count,
        CAST(distinct_site_count AS INTEGER) AS distinct_site_count,
        CAST(distinct_country_count AS INTEGER) AS distinct_country_count,
        CAST(relationship_count AS INTEGER) AS relationship_count,
        CAST(product_types AS TEXT) AS product_types,
        CAST(parent_group_ids AS TEXT) AS parent_group_ids,
        CAST(source_id AS TEXT) AS source_id,
        CAST(snapshot_month AS TEXT) AS snapshot_month
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.supplier_group_master
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.supplier_group_master
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'supplier_group_master_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'supplier_group_master_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 6. Reconcile all supplier resolution fields
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp003_supplier_resolution_map
),
expected_rows AS (
    SELECT
        CAST(supplier_id AS TEXT) AS supplier_id,
        CAST(supplier_name_source_canonical AS TEXT) AS supplier_name_source_canonical,
        CAST(supplier_group_id AS TEXT) AS supplier_group_id,
        CAST(supplier_group_name_canonical AS TEXT) AS supplier_group_name_canonical,
        CAST(resolution_rule AS TEXT) AS resolution_rule,
        CAST(review_status AS TEXT) AS review_status,
        CAST(match_confidence AS NUMERIC) AS match_confidence,
        CAST(evidence_note AS TEXT) AS evidence_note,
        CAST(source_id AS TEXT) AS source_id,
        CAST(snapshot_month AS TEXT) AS snapshot_month
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.supplier_resolution_map
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.supplier_resolution_map
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'supplier_resolution_map_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'supplier_resolution_map_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 7. Reconcile all supplier entity/channel fields
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp003_supplier_entity_map
),
expected_rows AS (
    SELECT
        CAST(supplier_id AS TEXT) AS supplier_id,
        CAST(supplier_name_canonical AS TEXT) AS supplier_name_canonical,
        CAST(entity_role AS TEXT) AS entity_role,
        CAST(parent_group_id AS TEXT) AS parent_group_id,
        CAST(ownership_status AS TEXT) AS ownership_status,
        CAST(relationship_count AS INTEGER) AS relationship_count,
        CAST(distinct_site_count AS INTEGER) AS distinct_site_count,
        CAST(parent_group_relationship_count AS INTEGER) AS parent_group_relationship_count,
        CAST(parent_group_first_flag AS SMALLINT) AS parent_group_first_flag,
        CAST(parent_group_hhi_contribution AS NUMERIC) AS parent_group_hhi_contribution,
        CAST(evidence_source_id AS TEXT) AS evidence_source_id,
        CAST(evidence_reference AS TEXT) AS evidence_reference,
        CAST(classification_confidence AS TEXT) AS classification_confidence,
        CAST(review_status AS TEXT) AS review_status,
        CAST(classification_note AS TEXT) AS classification_note
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.supplier_entity_map
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.supplier_entity_map
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'supplier_entity_map_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'supplier_entity_map_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 8. Reconcile all site fields, including NULL employees and the two documented flag exceptions
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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

FROM staging.wp003_site_master
),
expected_rows AS (
    SELECT
        CAST(site_id AS TEXT) AS site_id,
        CAST(country_raw AS TEXT) AS country_raw,
        CAST(country_standardized AS TEXT) AS country_standardized,
        CAST(country_variants AS TEXT) AS country_variants,
        CAST(site_name_canonical AS TEXT) AS site_name_canonical,
        CAST(site_name_variants AS TEXT) AS site_name_variants,
        CAST(address_canonical AS TEXT) AS address_canonical,
        CAST(address_variants AS TEXT) AS address_variants,
        CAST(product_type_standardized AS TEXT) AS product_type_standardized,
        CAST(female_employees AS INTEGER) AS female_employees,
        CAST(male_employees AS INTEGER) AS male_employees,
        CAST(total_employees AS INTEGER) AS total_employees,
        CAST(employee_data_status AS TEXT) AS employee_data_status,
        CAST(trade_union_flag AS TEXT) AS trade_union_flag,
        CAST(workers_committee_flag AS TEXT) AS workers_committee_flag,
        CAST(supplier_count AS INTEGER) AS supplier_count,
        CAST(source_record_count AS INTEGER) AS source_record_count,
        CAST(site_consistency_flag AS TEXT) AS site_consistency_flag,
        CAST(source_record_ids AS TEXT) AS source_record_ids,
        CAST(source_id AS TEXT) AS source_id,
        CAST(snapshot_month AS TEXT) AS snapshot_month,
        CAST(apparel_site_flag AS SMALLINT) AS apparel_site_flag,
        CAST(home_site_flag AS SMALLINT) AS home_site_flag,
        CAST(mixed_product_site_flag AS SMALLINT) AS mixed_product_site_flag,
        CAST(employee_available_site_flag AS SMALLINT) AS employee_available_site_flag,
        CAST(trade_union_yes_site_flag AS SMALLINT) AS trade_union_yes_site_flag,
        CAST(workers_committee_yes_site_flag AS SMALLINT) AS workers_committee_yes_site_flag,
        CAST(shared_site_flag AS SMALLINT) AS shared_site_flag,
        CAST(site_consistency_review_flag AS SMALLINT) AS site_consistency_review_flag,
        CAST(audit_annotation_raw AS TEXT) AS audit_annotation_raw,
        CAST(site_audit_status AS TEXT) AS site_audit_status,
        CAST(responsible_sourcing_review_flag AS SMALLINT) AS responsible_sourcing_review_flag,
        CAST(physical_site_review_flag AS SMALLINT) AS physical_site_review_flag,
        CAST(physical_site_review_status AS TEXT) AS physical_site_review_status,
        CAST(physical_site_group_id AS TEXT) AS physical_site_group_id,
        CAST(site_owner_group AS TEXT) AS site_owner_group,
        CAST(site_ownership_status AS TEXT) AS site_ownership_status,
        CAST(site_ownership_evidence_source_id AS TEXT) AS site_ownership_evidence_source_id,
        CAST(site_ownership_evidence_reference AS TEXT) AS site_ownership_evidence_reference,
        CAST(site_ownership_confidence AS TEXT) AS site_ownership_confidence
    FROM expected_source
),
missing_or_changed AS (
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
    FROM expected_rows
    EXCEPT ALL
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
    FROM core.site_master
),
unexpected_or_changed AS (
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
    FROM core.site_master
    EXCEPT ALL
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
    FROM expected_rows
)
SELECT 'site_master_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'site_master_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 9. Check supplier relationships and bridge assignments
-- EXPECTED: 9 rows; every exception_count = 0.
SELECT 'resolution_supplier_orphans' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_resolution_map r LEFT JOIN core.supplier_master s ON r.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL
UNION ALL
SELECT 'resolution_group_or_name_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_resolution_map r LEFT JOIN core.supplier_group_master g ON r.supplier_group_id = g.supplier_group_id
WHERE g.supplier_group_id IS NULL OR r.supplier_group_name_canonical IS DISTINCT FROM g.supplier_group_name_canonical
UNION ALL
SELECT 'entity_supplier_or_name_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_entity_map e LEFT JOIN core.supplier_master s ON e.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL OR e.supplier_name_canonical IS DISTINCT FROM s.supplier_name_canonical
UNION ALL
SELECT 'raw_supplier_or_name_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.raw_tier1_relationships r LEFT JOIN core.supplier_master s ON r.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL OR r.supplier_name_canonical IS DISTINCT FROM s.supplier_name_canonical
UNION ALL
SELECT 'raw_site_orphans' AS check_name, COUNT(*) AS exception_count
FROM core.raw_tier1_relationships r LEFT JOIN core.site_master s ON r.site_id_raw = s.site_id
WHERE s.site_id IS NULL
UNION ALL
SELECT 'bridge_supplier_or_name_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_site_bridge b LEFT JOIN core.supplier_master s ON b.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL OR b.supplier_name_canonical IS DISTINCT FROM s.supplier_name_canonical
UNION ALL
SELECT 'bridge_site_orphans' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_site_bridge b LEFT JOIN core.site_master s ON b.site_id = s.site_id
WHERE s.site_id IS NULL
UNION ALL
SELECT 'bridge_resolution_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_site_bridge b LEFT JOIN core.supplier_resolution_map r ON b.supplier_id = r.supplier_id
WHERE r.supplier_id IS NULL OR b.supplier_group_id IS DISTINCT FROM r.supplier_group_id
   OR b.supplier_group_name_canonical IS DISTINCT FROM r.supplier_group_name_canonical
UNION ALL
SELECT 'bridge_parent_group_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_site_bridge b LEFT JOIN core.supplier_entity_map e ON b.supplier_id = e.supplier_id
WHERE e.supplier_id IS NULL OR b.parent_group_id IS DISTINCT FROM e.parent_group_id;

-- 10. Check the complete bridge lineage, including every pipe-separated source ID
-- EXPECTED: 6 rows; every exception_count = 0.
WITH tokens AS (
    SELECT b.relationship_id, b.supplier_id, b.site_id,
           b.product_type_standardized, TRIM(p.raw_id) AS raw_id
    FROM core.supplier_site_bridge b
    CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(b.source_record_ids, '|')) AS p(raw_id)
),
token_counts AS (
    SELECT relationship_id, COUNT(*) AS token_count
    FROM tokens GROUP BY relationship_id
)
SELECT 'lineage_missing_or_wrong_relationship' AS check_name, COUNT(*) AS exception_count
FROM tokens t
LEFT JOIN core.raw_tier1_relationships r ON t.raw_id = r.source_record_id
WHERE r.source_record_id IS NULL
   OR r.supplier_id IS DISTINCT FROM t.supplier_id
   OR r.site_id_raw IS DISTINCT FROM t.site_id
   OR r.product_type_raw IS DISTINCT FROM t.product_type_standardized
UNION ALL
SELECT 'lineage_count_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_site_bridge b
LEFT JOIN token_counts t ON b.relationship_id = t.relationship_id
WHERE b.source_record_count IS DISTINCT FROM t.token_count
UNION ALL
SELECT 'lineage_representative_id_absent' AS check_name, COUNT(*) AS exception_count
FROM core.supplier_site_bridge b
WHERE NOT EXISTS (SELECT 1 FROM tokens t
                  WHERE t.relationship_id = b.relationship_id
                    AND t.raw_id = b.source_record_id)
UNION ALL
SELECT 'raw_observations_without_bridge_lineage' AS check_name, COUNT(*) AS exception_count
FROM core.raw_tier1_relationships r
WHERE NOT EXISTS (SELECT 1 FROM tokens t WHERE t.raw_id = r.source_record_id)
UNION ALL
SELECT 'raw_ids_repeated_in_bridge_lineage' AS check_name, COUNT(*) AS exception_count
FROM (SELECT raw_id FROM tokens GROUP BY raw_id HAVING COUNT(*) <> 1) d
UNION ALL
SELECT 'bridge_grain_duplicates' AS check_name, COUNT(*) AS exception_count
FROM (SELECT supplier_id, site_id, product_type_standardized
      FROM core.supplier_site_bridge
      GROUP BY supplier_id, site_id, product_type_standardized
      HAVING COUNT(*) > 1) d;

-- 11. Verify governed supplier/site control totals
-- EXPECTED: 18 rows; every check_status = 'PASS' and difference = 0.
-- Each expected_value is printed beside its actual_value.
WITH controls AS (
    SELECT 'raw_duplicate_flags' AS check_name, 16::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.raw_tier1_relationships WHERE exact_duplicate_flag = 'Yes')::BIGINT AS actual_value
    UNION ALL
    SELECT 'raw_site_not_audited_annotations' AS check_name, 11::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.raw_tier1_relationships WHERE audit_annotation_raw = 'site not audited')::BIGINT AS actual_value
    UNION ALL
    SELECT 'raw_cannot_find_on_sc_annotations' AS check_name, 5::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.raw_tier1_relationships WHERE audit_annotation_raw = 'can''t find on SC')::BIGINT AS actual_value
    UNION ALL
    SELECT 'sites_missing_female_employees' AS check_name, 11::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE female_employees IS NULL)::BIGINT AS actual_value
    UNION ALL
    SELECT 'sites_missing_male_employees' AS check_name, 11::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE male_employees IS NULL)::BIGINT AS actual_value
    UNION ALL
    SELECT 'sites_missing_total_employees' AS check_name, 11::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE total_employees IS NULL)::BIGINT AS actual_value
    UNION ALL
    SELECT 'physical_review_sites_after_normalization' AS check_name, 10::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE physical_site_review_flag = 1)::BIGINT AS actual_value
    UNION ALL
    SELECT 'documented_two_site_corrections' AS check_name, 2::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE site_id IN ('20221', '24006') AND physical_site_review_flag = 1 AND physical_site_review_status = 'Closed - retained separate')::BIGINT AS actual_value
    UNION ALL
    SELECT 'site_consistency_reviews' AS check_name, 0::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE site_consistency_review_flag = 1)::BIGINT AS actual_value
    UNION ALL
    SELECT 'responsible_sourcing_reviews' AS check_name, 16::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE responsible_sourcing_review_flag = 1)::BIGINT AS actual_value
    UNION ALL
    SELECT 'confirmed_next_owned_sites' AS check_name, 3::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master WHERE site_owner_group = 'NEXT_GROUP' AND site_ownership_status = 'Confirmed group-owned manufacturing operation')::BIGINT AS actual_value
    UNION ALL
    SELECT 'confirmed_next_owned_listed_workers' AS check_name, 2888::BIGINT AS expected_value,
           (SELECT SUM(total_employees) FROM core.site_master WHERE site_owner_group = 'NEXT_GROUP' AND site_ownership_status = 'Confirmed group-owned manufacturing operation')::BIGINT AS actual_value
    UNION ALL
    SELECT 'next_sourcing_supplier_ids' AS check_name, 19::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_entity_map WHERE parent_group_id = 'NEXT_SOURCING_GROUP')::BIGINT AS actual_value
    UNION ALL
    SELECT 'next_sourcing_relationships' AS check_name, 438::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_site_bridge b JOIN core.supplier_entity_map e ON b.supplier_id = e.supplier_id WHERE e.parent_group_id = 'NEXT_SOURCING_GROUP')::BIGINT AS actual_value
    UNION ALL
    SELECT 'next_sourcing_distinct_sites' AS check_name, 383::BIGINT AS expected_value,
           (SELECT COUNT(DISTINCT b.site_id) FROM core.supplier_site_bridge b JOIN core.supplier_entity_map e ON b.supplier_id = e.supplier_id WHERE e.parent_group_id = 'NEXT_SOURCING_GROUP')::BIGINT AS actual_value
    UNION ALL
    SELECT 'shared_sites_source_supplier_definition' AS check_name, 338::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM (SELECT site_id FROM core.supplier_site_bridge GROUP BY site_id HAVING COUNT(DISTINCT supplier_id) > 1) s)::BIGINT AS actual_value
    UNION ALL
    SELECT 'shared_sites_resolved_group_definition' AS check_name, 329::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM (SELECT site_id FROM core.supplier_site_bridge GROUP BY site_id HAVING COUNT(DISTINCT supplier_group_id) > 1) s)::BIGINT AS actual_value
    UNION ALL
    SELECT 'bridge_lineage_observations' AS check_name, 2202::BIGINT AS expected_value,
           (SELECT SUM(source_record_count) FROM core.supplier_site_bridge)::BIGINT AS actual_value
)
SELECT check_name, expected_value, actual_value,
       actual_value - expected_value AS difference,
       CASE WHEN actual_value = expected_value THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM controls
ORDER BY check_name;

-- 12A. Reconcile all fields in dim_commodity
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
        cn8_code,
        hs2_code,
        hs4_code,
        hs6_code,
        description,
        construction,
        fibre,
        basket_role,
        inclusion_status
) AS (
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
FROM staging.wp005_dim_commodity
),
expected_rows AS (
    SELECT
        CAST(cn8_code AS TEXT) AS cn8_code,
        CAST(hs2_code AS TEXT) AS hs2_code,
        CAST(hs4_code AS TEXT) AS hs4_code,
        CAST(hs6_code AS TEXT) AS hs6_code,
        CAST(description AS TEXT) AS description,
        CAST(construction AS TEXT) AS construction,
        CAST(fibre AS TEXT) AS fibre,
        CAST(basket_role AS TEXT) AS basket_role,
        CAST(inclusion_status AS TEXT) AS inclusion_status
    FROM expected_source
),
missing_or_changed AS (
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
    FROM expected_rows
    EXCEPT ALL
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
    FROM core.dim_commodity
),
unexpected_or_changed AS (
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
    FROM core.dim_commodity
    EXCEPT ALL
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
    FROM expected_rows
)
SELECT 'dim_commodity_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'dim_commodity_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 12B. Reconcile all fields in dim_partner_country
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
        partner_country_id,
        country_code_numeric,
        partner_country_iso2,
        partner_country_name,
        hmrc_flow_type_id,
        scope_status,
        geographical_basis
) AS (
    SELECT
    CAST(partner_country_id AS INTEGER),
    country_code_numeric,
    partner_country_iso2,
    partner_country_name,
    CAST(hmrc_flow_type_id AS INTEGER),
    scope_status,
    geographical_basis
FROM staging.wp005_dim_partner_country
),
expected_rows AS (
    SELECT
        CAST(partner_country_id AS INTEGER) AS partner_country_id,
        CAST(country_code_numeric AS TEXT) AS country_code_numeric,
        CAST(partner_country_iso2 AS TEXT) AS partner_country_iso2,
        CAST(partner_country_name AS TEXT) AS partner_country_name,
        CAST(hmrc_flow_type_id AS INTEGER) AS hmrc_flow_type_id,
        CAST(scope_status AS TEXT) AS scope_status,
        CAST(geographical_basis AS TEXT) AS geographical_basis
    FROM expected_source
),
missing_or_changed AS (
    SELECT
        partner_country_id,
        country_code_numeric,
        partner_country_iso2,
        partner_country_name,
        hmrc_flow_type_id,
        scope_status,
        geographical_basis
    FROM expected_rows
    EXCEPT ALL
    SELECT
        partner_country_id,
        country_code_numeric,
        partner_country_iso2,
        partner_country_name,
        hmrc_flow_type_id,
        scope_status,
        geographical_basis
    FROM core.dim_partner_country
),
unexpected_or_changed AS (
    SELECT
        partner_country_id,
        country_code_numeric,
        partner_country_iso2,
        partner_country_name,
        hmrc_flow_type_id,
        scope_status,
        geographical_basis
    FROM core.dim_partner_country
    EXCEPT ALL
    SELECT
        partner_country_id,
        country_code_numeric,
        partner_country_iso2,
        partner_country_name,
        hmrc_flow_type_id,
        scope_status,
        geographical_basis
    FROM expected_rows
)
SELECT 'dim_partner_country_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'dim_partner_country_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 12C. Reconcile all fields in dim_month
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp005_dim_month
),
expected_rows AS (
    SELECT
        CAST(month_id AS INTEGER) AS month_id,
        CAST(month_date AS DATE) AS month_date,
        CAST(calendar_year AS INTEGER) AS calendar_year,
        CAST(month_number AS INTEGER) AS month_number,
        CAST(month_name AS TEXT) AS month_name,
        CAST(calendar_quarter AS TEXT) AS calendar_quarter,
        CAST(half_year AS TEXT) AS half_year,
        CAST(complete_calendar_year_flag AS SMALLINT) AS complete_calendar_year_flag,
        CAST(ytd_2026_flag AS SMALLINT) AS ytd_2026_flag,
        CAST(like_for_like_h1_flag AS SMALLINT) AS like_for_like_h1_flag
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.dim_month
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.dim_month
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'dim_month_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'dim_month_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 13A. Reconcile all fields in raw_partner_monthly
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp005_raw_partner_monthly
),
expected_rows AS (
    SELECT
        CAST(source_query_id AS TEXT) AS source_query_id,
        CAST(source_record_no AS INTEGER) AS source_record_no,
        CAST(month_id AS INTEGER) AS month_id,
        CAST(commodity_id AS TEXT) AS commodity_id,
        CAST(country_id AS INTEGER) AS country_id,
        CAST(flow_type_id AS INTEGER) AS flow_type_id,
        CAST(suppression_index AS INTEGER) AS suppression_index,
        CAST(supp_unit AS NUMERIC(20, 6)) AS supp_unit,
        CAST(net_mass AS NUMERIC(20, 6)) AS net_mass,
        CAST(value_gbp AS NUMERIC(20, 6)) AS value_gbp,
        CAST(source_file AS TEXT) AS source_file
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.raw_partner_monthly
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.raw_partner_monthly
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'raw_partner_monthly_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'raw_partner_monthly_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 13B. Reconcile all fields in raw_world_monthly
-- EXPECTED: two rows; exception_count = 0 in both.
WITH expected_source (
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
) AS (
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
FROM staging.wp005_raw_world_monthly
),
expected_rows AS (
    SELECT
        CAST(source_query_id AS TEXT) AS source_query_id,
        CAST(source_record_no AS INTEGER) AS source_record_no,
        CAST(month_id AS INTEGER) AS month_id,
        CAST(commodity_id AS TEXT) AS commodity_id,
        CAST(flow_type_id AS INTEGER) AS flow_type_id,
        CAST(suppression_index AS INTEGER) AS suppression_index,
        CAST(supp_unit AS NUMERIC(20, 6)) AS supp_unit,
        CAST(net_mass AS NUMERIC(20, 6)) AS net_mass,
        CAST(value_gbp AS NUMERIC(20, 6)) AS value_gbp,
        CAST(source_file AS TEXT) AS source_file
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.raw_world_monthly
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.raw_world_monthly
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'raw_world_monthly_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'raw_world_monthly_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 14. Confirm the complete core inventory and trade diagnostic totals
-- EXPECTED: 24 rows; every check_status = 'PASS' and difference = 0.
-- Each expected_value is printed beside its actual_value.
WITH controls AS (
    SELECT 'dim_commodity_rows' AS check_name, 5::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.dim_commodity)::BIGINT AS actual_value
    UNION ALL
    SELECT 'dim_partner_country_rows' AS check_name, 10::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.dim_partner_country)::BIGINT AS actual_value
    UNION ALL
    SELECT 'dim_month_rows' AS check_name, 90::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.dim_month)::BIGINT AS actual_value
    UNION ALL
    SELECT 'raw_partner_monthly_rows' AS check_name, 3588::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.raw_partner_monthly)::BIGINT AS actual_value
    UNION ALL
    SELECT 'raw_world_monthly_rows' AS check_name, 720::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.raw_world_monthly)::BIGINT AS actual_value
    UNION ALL
    SELECT 'fct_hmrc_world_monthly_rows' AS check_name, 360::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_world_monthly)::BIGINT AS actual_value
    UNION ALL
    SELECT 'fct_hmrc_import_monthly_rows' AS check_name, 3600::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_import_monthly)::BIGINT AS actual_value
    UNION ALL
    SELECT 'supplier_master_rows' AS check_name, 672::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_master)::BIGINT AS actual_value
    UNION ALL
    SELECT 'supplier_group_master_rows' AS check_name, 661::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_group_master)::BIGINT AS actual_value
    UNION ALL
    SELECT 'supplier_resolution_map_rows' AS check_name, 672::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_resolution_map)::BIGINT AS actual_value
    UNION ALL
    SELECT 'supplier_entity_map_rows' AS check_name, 672::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_entity_map)::BIGINT AS actual_value
    UNION ALL
    SELECT 'site_master_rows' AS check_name, 1478::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.site_master)::BIGINT AS actual_value
    UNION ALL
    SELECT 'raw_tier1_relationships_rows' AS check_name, 2202::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.raw_tier1_relationships)::BIGINT AS actual_value
    UNION ALL
    SELECT 'supplier_site_bridge_rows' AS check_name, 2097::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.supplier_site_bridge)::BIGINT AS actual_value
    UNION ALL
    SELECT 'active_core_commodity_codes' AS check_name, 4::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.dim_commodity WHERE inclusion_status = 'Core')::BIGINT AS actual_value
    UNION ALL
    SELECT 'first_month_id' AS check_name, 201901::BIGINT AS expected_value,
           (SELECT MIN(month_id) FROM core.dim_month)::BIGINT AS actual_value
    UNION ALL
    SELECT 'last_month_id' AS check_name, 202606::BIGINT AS expected_value,
           (SELECT MAX(month_id) FROM core.dim_month)::BIGINT AS actual_value
    UNION ALL
    SELECT 'partner_reported_rows' AS check_name, 3588::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_import_monthly WHERE record_status = 'REPORTED')::BIGINT AS actual_value
    UNION ALL
    SELECT 'partner_no_api_rows' AS check_name, 12::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_import_monthly WHERE record_status = 'NO_API_RECORD')::BIGINT AS actual_value
    UNION ALL
    SELECT 'partner_review_rows' AS check_name, 37::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_import_monthly WHERE unit_value_review_flag_2_5x = 'REVIEW')::BIGINT AS actual_value
    UNION ALL
    SELECT 'partner_within_band_rows' AS check_name, 3551::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_import_monthly WHERE unit_value_review_flag_2_5x = 'WITHIN_BAND')::BIGINT AS actual_value
    UNION ALL
    SELECT 'partner_not_applicable_rows' AS check_name, 12::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_import_monthly WHERE unit_value_review_flag_2_5x = 'NOT_APPLICABLE')::BIGINT AS actual_value
    UNION ALL
    SELECT 'world_review_rows' AS check_name, 2::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_world_monthly WHERE unit_value_review_flag_2_5x = 'REVIEW')::BIGINT AS actual_value
    UNION ALL
    SELECT 'world_within_band_rows' AS check_name, 358::BIGINT AS expected_value,
           (SELECT COUNT(*) FROM core.fct_hmrc_world_monthly WHERE unit_value_review_flag_2_5x = 'WITHIN_BAND')::BIGINT AS actual_value
)
SELECT check_name, expected_value, actual_value,
       actual_value - expected_value AS difference,
       CASE WHEN actual_value = expected_value THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM controls
ORDER BY check_name;

-- 15. Recalculate World facts from typed raw observations and reconcile every field
-- EXPECTED: two rows; exception_count = 0 in both.
-- Full-precision ratios and medians are recalculated BEFORE casting to NUMERIC(20,6).
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
),

expected_source (
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
) AS (
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
    ON wr.cn8_code = dc.cn8_code
),
expected_rows AS (
    SELECT
        CAST(world_monthly_key AS TEXT) AS world_monthly_key,
        CAST(month_date AS DATE) AS month_date,
        CAST(month_id AS INTEGER) AS month_id,
        CAST(calendar_year AS INTEGER) AS calendar_year,
        CAST(calendar_month AS INTEGER) AS calendar_month,
        CAST(cn8_code AS TEXT) AS cn8_code,
        CAST(hs4_code AS TEXT) AS hs4_code,
        CAST(eu_import_value_gbp AS NUMERIC(20, 6)) AS eu_import_value_gbp,
        CAST(non_eu_import_value_gbp AS NUMERIC(20, 6)) AS non_eu_import_value_gbp,
        CAST(world_import_value_gbp AS NUMERIC(20, 6)) AS world_import_value_gbp,
        CAST(eu_net_mass_kg AS NUMERIC(20, 6)) AS eu_net_mass_kg,
        CAST(non_eu_net_mass_kg AS NUMERIC(20, 6)) AS non_eu_net_mass_kg,
        CAST(world_net_mass_kg AS NUMERIC(20, 6)) AS world_net_mass_kg,
        CAST(eu_supplementary_quantity AS NUMERIC(20, 6)) AS eu_supplementary_quantity,
        CAST(non_eu_supplementary_quantity AS NUMERIC(20, 6)) AS non_eu_supplementary_quantity,
        CAST(world_supplementary_quantity AS NUMERIC(20, 6)) AS world_supplementary_quantity,
        CAST(unit_value_gbp_per_kg AS NUMERIC(20, 6)) AS unit_value_gbp_per_kg,
        CAST(eu_suppression_index_list AS TEXT) AS eu_suppression_index_list,
        CAST(non_eu_suppression_index_list AS TEXT) AS non_eu_suppression_index_list,
        CAST(suppression_flag AS SMALLINT) AS suppression_flag,
        CAST(source_query_id AS TEXT) AS source_query_id,
        CAST(source_file AS TEXT) AS source_file,
        CAST(reference_median_unit_value_gbp_per_kg AS NUMERIC(20, 6)) AS reference_median_unit_value_gbp_per_kg,
        CAST(unit_value_ratio_to_reference_median AS NUMERIC(20, 6)) AS unit_value_ratio_to_reference_median,
        CAST(unit_value_review_flag_2_5x AS TEXT) AS unit_value_review_flag_2_5x
    FROM expected_source
),
missing_or_changed AS (
    SELECT
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
    FROM expected_rows
    EXCEPT ALL
    SELECT
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
    FROM core.fct_hmrc_world_monthly
),
unexpected_or_changed AS (
    SELECT
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
    FROM core.fct_hmrc_world_monthly
    EXCEPT ALL
    SELECT
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
    FROM expected_rows
)
SELECT 'fct_hmrc_world_monthly_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'fct_hmrc_world_monthly_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- 16. Recalculate partner facts, including NO_API_RECORD placeholders, and reconcile every field
-- EXPECTED: two rows; exception_count = 0 in both.
-- Reuses the governed panel keys; block 18 independently checks panel completeness.
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
),

expected_source (
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
) AS (
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

FROM partner_ratios
),
expected_rows AS (
    SELECT
        CAST(monthly_import_key AS TEXT) AS monthly_import_key,
        CAST(month_date AS DATE) AS month_date,
        CAST(month_id AS INTEGER) AS month_id,
        CAST(calendar_year AS INTEGER) AS calendar_year,
        CAST(calendar_month AS INTEGER) AS calendar_month,
        CAST(cn8_code AS TEXT) AS cn8_code,
        CAST(hs4_code AS TEXT) AS hs4_code,
        CAST(partner_country_id AS INTEGER) AS partner_country_id,
        CAST(partner_country_iso2 AS TEXT) AS partner_country_iso2,
        CAST(partner_country_name AS TEXT) AS partner_country_name,
        CAST(flow AS TEXT) AS flow,
        CAST(flow_type_id AS INTEGER) AS flow_type_id,
        CAST(api_row_present_flag AS SMALLINT) AS api_row_present_flag,
        CAST(record_status AS TEXT) AS record_status,
        CAST(suppression_index_list AS TEXT) AS suppression_index_list,
        CAST(suppression_flag AS SMALLINT) AS suppression_flag,
        CAST(import_value_gbp AS NUMERIC(20, 6)) AS import_value_gbp,
        CAST(net_mass_kg AS NUMERIC(20, 6)) AS net_mass_kg,
        CAST(supplementary_quantity AS NUMERIC(20, 6)) AS supplementary_quantity,
        CAST(mass_status AS TEXT) AS mass_status,
        CAST(unit_value_gbp_per_kg AS NUMERIC(20, 6)) AS unit_value_gbp_per_kg,
        CAST(world_import_value_gbp AS NUMERIC(20, 6)) AS world_import_value_gbp,
        CAST(partner_value_share AS NUMERIC(20, 6)) AS partner_value_share,
        CAST(source_query_id AS TEXT) AS source_query_id,
        CAST(source_file AS TEXT) AS source_file,
        CAST(reference_median_unit_value_gbp_per_kg AS NUMERIC(20, 6)) AS reference_median_unit_value_gbp_per_kg,
        CAST(unit_value_ratio_to_reference_median AS NUMERIC(20, 6)) AS unit_value_ratio_to_reference_median,
        CAST(unit_value_review_flag_2_5x AS TEXT) AS unit_value_review_flag_2_5x
    FROM expected_source
),
missing_or_changed AS (
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
        unit_value_review_flag_2_5x
    FROM expected_rows
    EXCEPT ALL
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
        unit_value_review_flag_2_5x
    FROM core.fct_hmrc_import_monthly
),
unexpected_or_changed AS (
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
        unit_value_review_flag_2_5x
    FROM core.fct_hmrc_import_monthly
    EXCEPT ALL
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
        unit_value_review_flag_2_5x
    FROM expected_rows
)
SELECT 'fct_hmrc_import_monthly_missing_or_changed' AS check_name,
       COUNT(*) AS exception_count
FROM missing_or_changed
UNION ALL
SELECT 'fct_hmrc_import_monthly_unexpected_or_changed', COUNT(*)
FROM unexpected_or_changed;

-- The reference CSVs contain formatted/rounded display values.
-- Money unit values: GBP 0.005001; medians/ratios: 0.000051;
-- shares (fractions): 0.0000505. These are display-rounding tolerances,
-- including stored six-decimal rounding, NOT materiality thresholds.
-- Non-derived measures, keys, statuses and lineage must match exactly.
-- 17. Reconcile governed WP005 reference facts, respecting display precision
-- EXPECTED: 2 rows; every exception_count = 0.
SELECT 'wp005_fct_world_monthly_reference_exceptions' AS check_name, COUNT(*) AS exception_count
FROM staging.wp005_fct_world_monthly s
FULL OUTER JOIN core.fct_hmrc_world_monthly c ON s.world_monthly_key = c.world_monthly_key
WHERE s.world_monthly_key IS NULL
   OR c.world_monthly_key IS NULL
   OR CAST(s.month_date AS DATE) IS DISTINCT FROM c.month_date
   OR CAST(s.month_id AS INTEGER) IS DISTINCT FROM c.month_id
   OR CAST(s.calendar_year AS INTEGER) IS DISTINCT FROM c.calendar_year
   OR CAST(s.calendar_month AS INTEGER) IS DISTINCT FROM c.calendar_month
   OR s.cn8_code IS DISTINCT FROM c.cn8_code
   OR s.hs4_code IS DISTINCT FROM c.hs4_code
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.eu_import_value_gbp), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.eu_import_value_gbp
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.non_eu_import_value_gbp), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.non_eu_import_value_gbp
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.world_import_value_gbp), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.world_import_value_gbp
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.eu_net_mass_kg), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.eu_net_mass_kg
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.non_eu_net_mass_kg), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.non_eu_net_mass_kg
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.world_net_mass_kg), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.world_net_mass_kg
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.eu_supplementary_quantity), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.eu_supplementary_quantity
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.non_eu_supplementary_quantity), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.non_eu_supplementary_quantity
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.world_supplementary_quantity), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.world_supplementary_quantity
   OR (((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) IS NULL) <> (c.unit_value_gbp_per_kg IS NULL) OR ABS((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) - c.unit_value_gbp_per_kg) > 0.005001)
   OR NULLIF(TRIM(s.eu_suppression_index_list), '') IS DISTINCT FROM c.eu_suppression_index_list
   OR NULLIF(TRIM(s.non_eu_suppression_index_list), '') IS DISTINCT FROM c.non_eu_suppression_index_list
   OR CAST(s.suppression_flag AS SMALLINT) IS DISTINCT FROM c.suppression_flag
   OR s.source_query_id IS DISTINCT FROM c.source_query_id
   OR s.source_file IS DISTINCT FROM c.source_file
   OR (((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.reference_median_unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) IS NULL) <> (c.reference_median_unit_value_gbp_per_kg IS NULL) OR ABS((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.reference_median_unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) - c.reference_median_unit_value_gbp_per_kg) > 0.000051)
   OR (((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_ratio_to_reference_median), '[£,%x]', '', 'g'), '') AS NUMERIC)) IS NULL) <> (c.unit_value_ratio_to_reference_median IS NULL) OR ABS((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_ratio_to_reference_median), '[£,%x]', '', 'g'), '') AS NUMERIC)) - c.unit_value_ratio_to_reference_median) > 0.000051)
   OR s.unit_value_review_flag_2_5x IS DISTINCT FROM c.unit_value_review_flag_2_5x
UNION ALL
SELECT 'wp005_fct_partner_monthly_reference_exceptions' AS check_name, COUNT(*) AS exception_count
FROM staging.wp005_fct_partner_monthly s
FULL OUTER JOIN core.fct_hmrc_import_monthly c ON s.monthly_import_key = c.monthly_import_key
WHERE s.monthly_import_key IS NULL
   OR c.monthly_import_key IS NULL
   OR CAST(s.month_date AS DATE) IS DISTINCT FROM c.month_date
   OR CAST(s.month_id AS INTEGER) IS DISTINCT FROM c.month_id
   OR CAST(s.calendar_year AS INTEGER) IS DISTINCT FROM c.calendar_year
   OR CAST(s.calendar_month AS INTEGER) IS DISTINCT FROM c.calendar_month
   OR s.cn8_code IS DISTINCT FROM c.cn8_code
   OR s.hs4_code IS DISTINCT FROM c.hs4_code
   OR CAST(s.partner_country_id AS INTEGER) IS DISTINCT FROM c.partner_country_id
   OR s.partner_country_iso2 IS DISTINCT FROM c.partner_country_iso2
   OR s.partner_country_name IS DISTINCT FROM c.partner_country_name
   OR s.flow IS DISTINCT FROM c.flow
   OR CAST(s.flow_type_id AS INTEGER) IS DISTINCT FROM c.flow_type_id
   OR CAST(s.api_row_present_flag AS SMALLINT) IS DISTINCT FROM c.api_row_present_flag
   OR s.record_status IS DISTINCT FROM c.record_status
   OR NULLIF(TRIM(s.suppression_index_list), '') IS DISTINCT FROM c.suppression_index_list
   OR CAST(s.suppression_flag AS SMALLINT) IS DISTINCT FROM c.suppression_flag
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.import_value_gbp), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.import_value_gbp
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.net_mass_kg), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.net_mass_kg
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.supplementary_quantity), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.supplementary_quantity
   OR s.mass_status IS DISTINCT FROM c.mass_status
   OR (((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) IS NULL) <> (c.unit_value_gbp_per_kg IS NULL) OR ABS((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) - c.unit_value_gbp_per_kg) > 0.005001)
   OR CAST(NULLIF(REGEXP_REPLACE(TRIM(s.world_import_value_gbp), '[£,%x]', '', 'g'), '') AS NUMERIC) IS DISTINCT FROM c.world_import_value_gbp
   OR ((((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.partner_value_share), '[£,%x]', '', 'g'), '') AS NUMERIC) / 100)) IS NULL) <> (c.partner_value_share IS NULL) OR ABS(((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.partner_value_share), '[£,%x]', '', 'g'), '') AS NUMERIC) / 100)) - c.partner_value_share) > 0.0000505)
   OR s.source_query_id IS DISTINCT FROM c.source_query_id
   OR s.source_file IS DISTINCT FROM c.source_file
   OR (((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.reference_median_unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) IS NULL) <> (c.reference_median_unit_value_gbp_per_kg IS NULL) OR ABS((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.reference_median_unit_value_gbp_per_kg), '[£,%x]', '', 'g'), '') AS NUMERIC)) - c.reference_median_unit_value_gbp_per_kg) > 0.000051)
   OR (((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_ratio_to_reference_median), '[£,%x]', '', 'g'), '') AS NUMERIC)) IS NULL) <> (c.unit_value_ratio_to_reference_median IS NULL) OR ABS((CAST(NULLIF(REGEXP_REPLACE(TRIM(s.unit_value_ratio_to_reference_median), '[£,%x]', '', 'g'), '') AS NUMERIC)) - c.unit_value_ratio_to_reference_median) > 0.000051)
   OR s.unit_value_review_flag_2_5x IS DISTINCT FROM c.unit_value_review_flag_2_5x;

-- 18. Independently check complete trade panels, dimensions and placeholders
-- EXPECTED: 7 rows; every exception_count = 0.
WITH expected_partner AS (
    SELECT c.cn8_code, p.partner_country_id, m.month_id
    FROM core.dim_commodity c
    CROSS JOIN core.dim_partner_country p
    CROSS JOIN core.dim_month m
    WHERE c.inclusion_status = 'Core'
),
expected_world AS (
    SELECT c.cn8_code, m.month_id
    FROM core.dim_commodity c CROSS JOIN core.dim_month m
    WHERE c.inclusion_status = 'Core'
),
partner_missing AS (
    SELECT * FROM expected_partner
    EXCEPT ALL
    SELECT cn8_code, partner_country_id, month_id FROM core.fct_hmrc_import_monthly
),
partner_extra AS (
    SELECT cn8_code, partner_country_id, month_id FROM core.fct_hmrc_import_monthly
    EXCEPT ALL
    SELECT * FROM expected_partner
),
world_missing AS (
    SELECT * FROM expected_world
    EXCEPT ALL
    SELECT cn8_code, month_id FROM core.fct_hmrc_world_monthly
),
world_extra AS (
    SELECT cn8_code, month_id FROM core.fct_hmrc_world_monthly
    EXCEPT ALL
    SELECT * FROM expected_world
)
SELECT 'partner_panel_missing_keys' AS check_name, COUNT(*) AS exception_count
FROM partner_missing
UNION ALL
SELECT 'partner_panel_unexpected_keys' AS check_name, COUNT(*) AS exception_count
FROM partner_extra
UNION ALL
SELECT 'world_panel_missing_keys' AS check_name, COUNT(*) AS exception_count
FROM world_missing
UNION ALL
SELECT 'world_panel_unexpected_keys' AS check_name, COUNT(*) AS exception_count
FROM world_extra
UNION ALL
SELECT 'month_dimension_flag_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.dim_month
WHERE month_id IS DISTINCT FROM (calendar_year * 100 + month_number)
   OR month_date IS DISTINCT FROM MAKE_DATE(calendar_year, month_number, 1)
   OR complete_calendar_year_flag IS DISTINCT FROM
      (CASE WHEN calendar_year BETWEEN 2019 AND 2025 THEN 1 ELSE 0 END)::SMALLINT
   OR ytd_2026_flag IS DISTINCT FROM
      (CASE WHEN calendar_year = 2026 AND month_number BETWEEN 1 AND 6 THEN 1 ELSE 0 END)::SMALLINT
   OR like_for_like_h1_flag IS DISTINCT FROM
      (CASE WHEN month_number BETWEEN 1 AND 6 THEN 1 ELSE 0 END)::SMALLINT
UNION ALL
SELECT 'partner_dimension_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.fct_hmrc_import_monthly p
LEFT JOIN core.dim_month m ON p.month_id = m.month_id
LEFT JOIN core.dim_commodity c ON p.cn8_code = c.cn8_code
LEFT JOIN core.dim_partner_country d ON p.partner_country_id = d.partner_country_id
WHERE m.month_id IS NULL OR c.cn8_code IS NULL OR d.partner_country_id IS NULL
   OR p.month_date IS DISTINCT FROM m.month_date
   OR p.calendar_year IS DISTINCT FROM m.calendar_year
   OR p.calendar_month IS DISTINCT FROM m.month_number
   OR p.hs4_code IS DISTINCT FROM c.hs4_code
   OR p.partner_country_iso2 IS DISTINCT FROM d.partner_country_iso2
   OR p.partner_country_name IS DISTINCT FROM d.partner_country_name
   OR p.flow_type_id IS DISTINCT FROM d.hmrc_flow_type_id
UNION ALL
SELECT 'no_api_placeholder_exceptions' AS check_name, COUNT(*) AS exception_count
FROM core.fct_hmrc_import_monthly
WHERE record_status = 'NO_API_RECORD' AND (
    api_row_present_flag IS DISTINCT FROM 0
    OR import_value_gbp IS DISTINCT FROM 0 OR net_mass_kg IS DISTINCT FROM 0
    OR supplementary_quantity IS DISTINCT FROM 0
    OR suppression_index_list IS NOT NULL OR suppression_flag IS DISTINCT FROM 0
    OR mass_status IS DISTINCT FROM 'NO_REPORTED_TRADE'
    OR unit_value_gbp_per_kg IS NOT NULL
    OR reference_median_unit_value_gbp_per_kg IS NOT NULL
    OR unit_value_ratio_to_reference_median IS NOT NULL
    OR unit_value_review_flag_2_5x IS DISTINCT FROM 'NOT_APPLICABLE'
);
