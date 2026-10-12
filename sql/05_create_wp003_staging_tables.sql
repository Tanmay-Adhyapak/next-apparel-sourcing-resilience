-- Create text staging tables for the seven WP003 CSV inputs.
-- Import the mapped Inputs/ files before running script 06.

CREATE TABLE staging.wp003_raw_tier1_relationships (
    source_record_id TEXT,
    source_id TEXT,
    source_file TEXT,
    source_page TEXT,
    source_row_on_page TEXT,
    pdf_table_row TEXT,
    site_id_raw TEXT,
    country_raw TEXT,
    supplier_name_raw TEXT,
    site_name_raw TEXT,
    address_raw TEXT,
    product_type_raw TEXT,
    female_employees_raw TEXT,
    male_employees_raw TEXT,
    trade_union_raw TEXT,
    workers_committee_raw TEXT,
    extraction_status TEXT,
    extraction_note TEXT,
    exact_duplicate_group_count TEXT,
    exact_duplicate_flag TEXT,
    supplier_id TEXT,
    supplier_name_canonical TEXT,
    audit_annotation_raw TEXT
);

CREATE TABLE staging.wp003_site_master (
    site_id TEXT,
    country_raw TEXT,
    country_standardized TEXT,
    country_variants TEXT,
    site_name_canonical TEXT,
    site_name_variants TEXT,
    address_canonical TEXT,
    address_variants TEXT,
    product_type_standardized TEXT,
    female_employees TEXT,
    male_employees TEXT,
    total_employees TEXT,
    employee_data_status TEXT,
    trade_union_flag TEXT,
    workers_committee_flag TEXT,
    supplier_count TEXT,
    source_record_count TEXT,
    site_consistency_flag TEXT,
    source_record_ids TEXT,
    source_id TEXT,
    snapshot_month TEXT,
    apparel_site_flag TEXT,
    home_site_flag TEXT,
    mixed_product_site_flag TEXT,
    employee_available_site_flag TEXT,
    trade_union_yes_site_flag TEXT,
    workers_committee_yes_site_flag TEXT,
    shared_site_flag TEXT,
    site_consistency_review_flag TEXT,
    audit_annotation_raw TEXT,
    site_audit_status TEXT,
    responsible_sourcing_review_flag TEXT,
    physical_site_review_flag TEXT,
    physical_site_review_status TEXT,
    physical_site_group_id TEXT,
    site_owner_group TEXT,
    site_ownership_status TEXT,
    site_ownership_evidence_source_id TEXT,
    site_ownership_evidence_reference TEXT,
    site_ownership_confidence TEXT
);

CREATE TABLE staging.wp003_supplier_master (
    supplier_id TEXT,
    supplier_name_canonical TEXT,
    supplier_name_variants TEXT,
    raw_name_variant_count TEXT,
    distinct_site_count TEXT,
    distinct_country_count TEXT,
    relationship_count TEXT,
    product_types TEXT,
    source_id TEXT,
    snapshot_month TEXT
);

CREATE TABLE staging.wp003_supplier_site_bridge (
    relationship_id TEXT,
    supplier_id TEXT,
    supplier_name_canonical TEXT,
    site_id TEXT,
    country_raw TEXT,
    product_type_standardized TEXT,
    source_record_id TEXT,
    source_record_ids TEXT,
    source_record_count TEXT,
    exact_duplicate_removed TEXT,
    relationship_review_status TEXT,
    source_id TEXT,
    snapshot_month TEXT,
    country_supplier_key TEXT,
    country_supplier_first_flag TEXT,
    parent_group_id TEXT,
    parent_group_site_first_flag TEXT,
    declared_channel_type TEXT,
    supplier_group_id TEXT,
    supplier_group_name_canonical TEXT
);

CREATE TABLE staging.wp003_supplier_resolution_map (
    supplier_id TEXT,
    supplier_name_source_canonical TEXT,
    supplier_group_id TEXT,
    supplier_group_name_canonical TEXT,
    resolution_rule TEXT,
    review_status TEXT,
    match_confidence TEXT,
    evidence_note TEXT,
    source_id TEXT,
    snapshot_month TEXT
);

CREATE TABLE staging.wp003_supplier_group_master (
    supplier_group_id TEXT,
    supplier_group_name_canonical TEXT,
    member_supplier_ids TEXT,
    member_supplier_names TEXT,
    source_supplier_id_count TEXT,
    distinct_site_count TEXT,
    distinct_country_count TEXT,
    relationship_count TEXT,
    product_types TEXT,
    parent_group_ids TEXT,
    source_id TEXT,
    snapshot_month TEXT
);

CREATE TABLE staging.wp003_supplier_entity_map (
    supplier_id TEXT,
    supplier_name_canonical TEXT,
    entity_role TEXT,
    parent_group_id TEXT,
    ownership_status TEXT,
    relationship_count TEXT,
    distinct_site_count TEXT,
    parent_group_relationship_count TEXT,
    parent_group_first_flag TEXT,
    parent_group_hhi_contribution TEXT,
    evidence_source_id TEXT,
    evidence_reference TEXT,
    classification_confidence TEXT,
    review_status TEXT,
    classification_note TEXT
);
