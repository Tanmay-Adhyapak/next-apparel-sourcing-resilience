-- Validate the imported WP003 supplier and site data.
-- Retain documented review annotations and source identities.

SELECT
    'wp003_raw_tier1_relationships' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_raw_tier1_relationships

UNION ALL

SELECT
    'wp003_site_master' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_site_master

UNION ALL

SELECT
    'wp003_supplier_master' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_supplier_master

UNION ALL

SELECT
    'wp003_supplier_site_bridge' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_supplier_site_bridge

UNION ALL

SELECT
    'wp003_supplier_resolution_map' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_supplier_resolution_map

UNION ALL

SELECT
    'wp003_supplier_group_master' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_supplier_group_master

UNION ALL

SELECT
    'wp003_supplier_entity_map' AS table_name,
    COUNT(*) AS actual_row_count
FROM staging.wp003_supplier_entity_map;

SELECT
    'source_record_id' AS key_name,
    source_record_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_raw_tier1_relationships
GROUP BY source_record_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'site_id' AS key_name,
    site_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_site_master
GROUP BY site_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'supplier_master.supplier_id' AS key_name,
    supplier_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_supplier_master
GROUP BY supplier_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'relationship_id' AS key_name,
    relationship_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_supplier_site_bridge
GROUP BY relationship_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'resolution_map.supplier_id' AS key_name,
    supplier_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_supplier_resolution_map
GROUP BY supplier_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'supplier_group_id' AS key_name,
    supplier_group_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_supplier_group_master
GROUP BY supplier_group_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'entity_map.supplier_id' AS key_name,
    supplier_id AS key_value,
    COUNT(*) AS row_count
FROM staging.wp003_supplier_entity_map
GROUP BY supplier_id
HAVING COUNT(*) > 1;

SELECT
    'raw.source_record_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_raw_tier1_relationships
WHERE source_record_id IS NULL OR TRIM(source_record_id) = ''

UNION ALL

SELECT
    'site_master.site_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_site_master
WHERE site_id IS NULL OR TRIM(site_id) = ''

UNION ALL

SELECT
    'supplier_master.supplier_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_supplier_master
WHERE supplier_id IS NULL OR TRIM(supplier_id) = ''

UNION ALL

SELECT
    'bridge.relationship_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_supplier_site_bridge
WHERE relationship_id IS NULL OR TRIM(relationship_id) = ''

UNION ALL

SELECT
    'resolution_map.supplier_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_supplier_resolution_map
WHERE supplier_id IS NULL OR TRIM(supplier_id) = ''

UNION ALL

SELECT
    'group_master.supplier_group_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_supplier_group_master
WHERE supplier_group_id IS NULL OR TRIM(supplier_group_id) = ''

UNION ALL

SELECT
    'entity_map.supplier_id' AS key_name,
    COUNT(*) AS missing_key_count
FROM staging.wp003_supplier_entity_map
WHERE supplier_id IS NULL OR TRIM(supplier_id) = '';

SELECT
    COUNT(*) AS orphan_bridge_row_count
FROM staging.wp003_supplier_site_bridge AS bridge
LEFT JOIN staging.wp003_supplier_master AS supplier
    ON bridge.supplier_id = supplier.supplier_id
LEFT JOIN staging.wp003_site_master AS site
    ON bridge.site_id = site.site_id
LEFT JOIN staging.wp003_supplier_group_master AS supplier_group
    ON bridge.supplier_group_id = supplier_group.supplier_group_id
WHERE
    supplier.supplier_id IS NULL
    OR site.site_id IS NULL
    OR supplier_group.supplier_group_id IS NULL;

SELECT
    'supplier_resolution_map' AS table_name,
    COUNT(*) AS orphan_row_count
FROM staging.wp003_supplier_resolution_map AS resolution
LEFT JOIN staging.wp003_supplier_master AS supplier
    ON resolution.supplier_id = supplier.supplier_id
LEFT JOIN staging.wp003_supplier_group_master AS supplier_group
    ON resolution.supplier_group_id = supplier_group.supplier_group_id
WHERE
    supplier.supplier_id IS NULL
    OR supplier_group.supplier_group_id IS NULL

UNION ALL

SELECT
    'supplier_entity_map' AS table_name,
    COUNT(*) AS orphan_row_count
FROM staging.wp003_supplier_entity_map AS entity_map
LEFT JOIN staging.wp003_supplier_master AS supplier
    ON entity_map.supplier_id = supplier.supplier_id
WHERE
    supplier.supplier_id IS NULL;

SELECT
    COUNT(*) AS resolution_row_count,
    COUNT(DISTINCT supplier_id) AS distinct_supplier_count,
    COUNT(DISTINCT supplier_group_id) AS distinct_supplier_group_count
FROM staging.wp003_supplier_resolution_map;

SELECT
    supplier_group_id,
    COUNT(*) AS source_supplier_count
FROM staging.wp003_supplier_resolution_map
GROUP BY supplier_group_id
HAVING COUNT(*) > 1
ORDER BY
    source_supplier_count DESC,
    supplier_group_id;

SELECT
    exact_duplicate_flag,
    COUNT(*) AS row_count
FROM staging.wp003_raw_tier1_relationships
GROUP BY exact_duplicate_flag
ORDER BY exact_duplicate_flag;

SELECT
    audit_annotation_raw,
    COUNT(*) AS row_count
FROM staging.wp003_raw_tier1_relationships
WHERE
    audit_annotation_raw IS NOT NULL
    AND TRIM(audit_annotation_raw) <> ''
GROUP BY audit_annotation_raw
ORDER BY
    row_count DESC,
    audit_annotation_raw;

SELECT
    COUNT(*) AS orphan_raw_relationship_count
FROM staging.wp003_raw_tier1_relationships AS raw
LEFT JOIN staging.wp003_supplier_master AS supplier
    ON raw.supplier_id = supplier.supplier_id
LEFT JOIN staging.wp003_site_master AS site
    ON raw.site_id_raw = site.site_id
WHERE
    supplier.supplier_id IS NULL
    OR site.site_id IS NULL;

SELECT
    COUNT(*) AS bridge_row_count,
    COUNT(DISTINCT relationship_id) AS distinct_relationship_count,
    COUNT(DISTINCT supplier_id) AS distinct_supplier_count,
    COUNT(DISTINCT supplier_group_id) AS distinct_supplier_group_count,
    COUNT(DISTINCT site_id) AS distinct_site_count
FROM staging.wp003_supplier_site_bridge;

WITH supplier_site_counts AS (
    SELECT
        site_id,
        COUNT(DISTINCT supplier_group_id) AS supplier_group_count
    FROM staging.wp003_supplier_site_bridge
    GROUP BY site_id
    HAVING COUNT(DISTINCT supplier_group_id) > 1
)

SELECT
    COUNT(*) AS shared_site_count
FROM supplier_site_counts;

WITH source_supplier_shared_sites AS (
    SELECT
        site_id
    FROM staging.wp003_supplier_site_bridge
    GROUP BY site_id
    HAVING COUNT(DISTINCT supplier_id) > 1
),

resolved_group_shared_sites AS (
    SELECT
        site_id
    FROM staging.wp003_supplier_site_bridge
    GROUP BY site_id
    HAVING COUNT(DISTINCT supplier_group_id) > 1
)

SELECT
    'source_supplier_id' AS sharing_definition,
    COUNT(*) AS shared_site_count
FROM source_supplier_shared_sites

UNION ALL

SELECT
    'resolved_supplier_group' AS sharing_definition,
    COUNT(*) AS shared_site_count
FROM resolved_group_shared_sites;

SELECT
    'missing_required_fields' AS check_name,
    COUNT(*) AS exception_count
FROM staging.wp003_raw_tier1_relationships
WHERE
    site_id_raw IS NULL OR TRIM(site_id_raw) = ''
    OR country_raw IS NULL OR TRIM(country_raw) = ''
    OR supplier_name_raw IS NULL OR TRIM(supplier_name_raw) = ''
    OR site_name_raw IS NULL OR TRIM(site_name_raw) = ''
    OR address_raw IS NULL OR TRIM(address_raw) = ''
    OR product_type_raw IS NULL OR TRIM(product_type_raw) = ''

UNION ALL

SELECT
    'invalid_site_id_format' AS check_name,
    COUNT(*) AS exception_count
FROM staging.wp003_raw_tier1_relationships
WHERE
    site_id_raw IS NULL
    OR TRIM(site_id_raw) !~ '^[0-9]+$'

UNION ALL

SELECT
    'unexpected_product_type' AS check_name,
    COUNT(*) AS exception_count
FROM staging.wp003_raw_tier1_relationships
WHERE
    product_type_raw IS NULL
    OR TRIM(product_type_raw) NOT IN ('APPAREL', 'HOME')

UNION ALL

SELECT
    'non_complete_extraction' AS check_name,
    COUNT(*) AS exception_count
FROM staging.wp003_raw_tier1_relationships
WHERE
    extraction_status IS NULL
    OR TRIM(extraction_status) <> 'Complete';

SELECT
    'site_consistency_review' AS check_name,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
WHERE site_consistency_review_flag = '1'

UNION ALL

SELECT
    'responsible_sourcing_review' AS check_name,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
WHERE responsible_sourcing_review_flag = '1'

UNION ALL

SELECT
    'physical_site_review' AS check_name,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
WHERE physical_site_review_flag = '1'

UNION ALL

SELECT
    'confirmed_next_owned' AS check_name,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
WHERE site_owner_group = 'NEXT_GROUP';

SELECT
    site_audit_status,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
GROUP BY site_audit_status
ORDER BY site_audit_status;

SELECT
    physical_site_review_status,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
WHERE physical_site_review_flag = '1'
GROUP BY physical_site_review_status
ORDER BY physical_site_review_status;

SELECT
    physical_site_review_flag,
    physical_site_review_status,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
GROUP BY
    physical_site_review_flag,
    physical_site_review_status
ORDER BY
    physical_site_review_flag,
    physical_site_review_status;

SELECT
    COUNT(*) AS reviewed_physical_site_count
FROM staging.wp003_site_master
WHERE
    physical_site_review_status IS NOT NULL
    AND TRIM(physical_site_review_status) <> '';

SELECT
    COUNT(*) AS owned_site_count,
    SUM(
        CAST(REPLACE(total_employees, ',', '') AS INTEGER)
    ) AS listed_worker_count
FROM staging.wp003_site_master
WHERE site_owner_group = 'NEXT_GROUP';

SELECT
    site_ownership_status,
    site_owner_group,
    COUNT(*) AS site_count
FROM staging.wp003_site_master
WHERE
    site_ownership_status IS NOT NULL
    AND TRIM(site_ownership_status) <> ''
GROUP BY
    site_ownership_status,
    site_owner_group
ORDER BY
    site_ownership_status,
    site_owner_group;

SELECT
    COUNT(*) AS confirmed_next_owned_site_count,
    SUM(
        CAST(
            REPLACE(total_employees, ',', '')
            AS NUMERIC
        )
    ) AS listed_worker_count
FROM staging.wp003_site_master
WHERE
    site_ownership_status IS NOT NULL
    AND TRIM(site_ownership_status) <> '';

SELECT
    COUNT(DISTINCT entity.supplier_id) AS next_sourcing_supplier_id_count,
    COUNT(*) AS next_sourcing_relationship_count,
    COUNT(DISTINCT bridge.site_id) AS next_sourcing_distinct_site_count
FROM staging.wp003_supplier_site_bridge AS bridge
INNER JOIN staging.wp003_supplier_entity_map AS entity
    ON bridge.supplier_id = entity.supplier_id
WHERE entity.parent_group_id = 'NEXT_SOURCING_GROUP';
