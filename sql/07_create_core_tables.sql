-- Create typed core tables, keys and constraints.
-- Run once after staging validation; load the tables with script 08.

CREATE TABLE core.dim_commodity (
    cn8_code TEXT PRIMARY KEY,
    hs2_code TEXT NOT NULL,
    hs4_code TEXT NOT NULL,
    hs6_code TEXT NOT NULL,
    description TEXT NOT NULL,
    construction TEXT NOT NULL,
    fibre TEXT NOT NULL,
    basket_role TEXT NOT NULL,
    inclusion_status TEXT NOT NULL
);

CREATE TABLE core.dim_partner_country (
    partner_country_id INTEGER PRIMARY KEY,
    country_code_numeric TEXT NOT NULL,
    partner_country_iso2 TEXT NOT NULL UNIQUE,
    partner_country_name TEXT NOT NULL,
    hmrc_flow_type_id INTEGER NOT NULL,
    scope_status TEXT NOT NULL,
    geographical_basis TEXT NOT NULL
);

CREATE TABLE core.dim_month (
    month_id INTEGER PRIMARY KEY,
    month_date DATE NOT NULL UNIQUE,
    calendar_year INTEGER NOT NULL,
    month_number INTEGER NOT NULL
        CHECK (month_number BETWEEN 1 AND 12),
    month_name TEXT NOT NULL,
    calendar_quarter TEXT NOT NULL
        CHECK (calendar_quarter IN ('Q1', 'Q2', 'Q3', 'Q4')),
    half_year TEXT NOT NULL
        CHECK (half_year IN ('H1', 'H2')),
    complete_calendar_year_flag SMALLINT NOT NULL
        CHECK (complete_calendar_year_flag IN (0, 1)),
    ytd_2026_flag SMALLINT NOT NULL
        CHECK (ytd_2026_flag IN (0, 1)),
    like_for_like_h1_flag SMALLINT NOT NULL
        CHECK (like_for_like_h1_flag IN (0, 1)),

    CHECK (
        month_date = MAKE_DATE(calendar_year, month_number, 1)
    ),
    CHECK (
        month_id = calendar_year * 100 + month_number
    )
);

CREATE TABLE core.raw_partner_monthly (
    source_query_id TEXT NOT NULL,
    source_record_no INTEGER NOT NULL,
    month_id INTEGER NOT NULL,
    commodity_id TEXT NOT NULL,
    country_id INTEGER NOT NULL,
    flow_type_id INTEGER NOT NULL
        CHECK (flow_type_id = 3),
    suppression_index INTEGER NOT NULL,
    supp_unit NUMERIC(20, 6) NOT NULL,
    net_mass NUMERIC(20, 6) NOT NULL,
    value_gbp NUMERIC(20, 6) NOT NULL,
    source_file TEXT NOT NULL,

    PRIMARY KEY (source_query_id, source_record_no),

    FOREIGN KEY (month_id)
        REFERENCES core.dim_month (month_id),

    FOREIGN KEY (commodity_id)
        REFERENCES core.dim_commodity (cn8_code),

    FOREIGN KEY (country_id)
        REFERENCES core.dim_partner_country (partner_country_id)
);

CREATE TABLE core.raw_world_monthly (
    source_query_id TEXT NOT NULL,
    source_record_no INTEGER NOT NULL,
    month_id INTEGER NOT NULL,
    commodity_id TEXT NOT NULL,
    flow_type_id INTEGER NOT NULL
        CHECK (flow_type_id IN (1, 3)),
    suppression_index INTEGER NOT NULL,
    supp_unit NUMERIC(20, 6) NOT NULL,
    net_mass NUMERIC(20, 6) NOT NULL,
    value_gbp NUMERIC(20, 6) NOT NULL,
    source_file TEXT NOT NULL,

    PRIMARY KEY (source_query_id, source_record_no),

    FOREIGN KEY (month_id)
        REFERENCES core.dim_month (month_id),

    FOREIGN KEY (commodity_id)
        REFERENCES core.dim_commodity (cn8_code)
);

CREATE TABLE core.fct_hmrc_world_monthly (
    world_monthly_key TEXT PRIMARY KEY,
    month_date DATE NOT NULL,
    month_id INTEGER NOT NULL,
    calendar_year INTEGER NOT NULL,
    calendar_month INTEGER NOT NULL
        CHECK (calendar_month BETWEEN 1 AND 12),
    cn8_code TEXT NOT NULL,
    hs4_code TEXT NOT NULL,
    eu_import_value_gbp NUMERIC(20, 6) NOT NULL,
    non_eu_import_value_gbp NUMERIC(20, 6) NOT NULL,
    world_import_value_gbp NUMERIC(20, 6) NOT NULL,
    eu_net_mass_kg NUMERIC(20, 6) NOT NULL,
    non_eu_net_mass_kg NUMERIC(20, 6) NOT NULL,
    world_net_mass_kg NUMERIC(20, 6) NOT NULL,
    eu_supplementary_quantity NUMERIC(20, 6) NOT NULL,
    non_eu_supplementary_quantity NUMERIC(20, 6) NOT NULL,
    world_supplementary_quantity NUMERIC(20, 6) NOT NULL,
    unit_value_gbp_per_kg NUMERIC(20, 6),
    eu_suppression_index_list TEXT,
    non_eu_suppression_index_list TEXT,
    suppression_flag SMALLINT NOT NULL
        CHECK (suppression_flag IN (0, 1)),
    source_query_id TEXT NOT NULL,
    source_file TEXT NOT NULL,
    reference_median_unit_value_gbp_per_kg NUMERIC(20, 6),
    unit_value_ratio_to_reference_median NUMERIC(20, 6),
    unit_value_review_flag_2_5x TEXT NOT NULL
        CHECK (
            unit_value_review_flag_2_5x IN (
                'WITHIN_BAND', 'REVIEW', 'NOT_APPLICABLE'
            )
        ),

    UNIQUE (cn8_code, month_id),

    FOREIGN KEY (month_id)
        REFERENCES core.dim_month (month_id),

    FOREIGN KEY (cn8_code)
        REFERENCES core.dim_commodity (cn8_code),

    CHECK (
        month_date = MAKE_DATE(calendar_year, calendar_month, 1)
    ),
    CHECK (
        month_id = calendar_year * 100 + calendar_month
    )
);

CREATE TABLE core.fct_hmrc_import_monthly (
    monthly_import_key TEXT PRIMARY KEY,
    month_date DATE NOT NULL,
    month_id INTEGER NOT NULL,
    calendar_year INTEGER NOT NULL,
    calendar_month INTEGER NOT NULL
        CHECK (calendar_month BETWEEN 1 AND 12),
    cn8_code TEXT NOT NULL,
    hs4_code TEXT NOT NULL,
    partner_country_id INTEGER NOT NULL,
    partner_country_iso2 TEXT NOT NULL,
    partner_country_name TEXT NOT NULL,
    flow TEXT NOT NULL
        CHECK (flow = 'IMPORT'),
    flow_type_id INTEGER NOT NULL
        CHECK (flow_type_id = 3),
    api_row_present_flag SMALLINT NOT NULL
        CHECK (api_row_present_flag IN (0, 1)),
    record_status TEXT NOT NULL
        CHECK (record_status IN ('REPORTED', 'NO_API_RECORD')),
    suppression_index_list TEXT,
    suppression_flag SMALLINT NOT NULL
        CHECK (suppression_flag IN (0, 1)),
    import_value_gbp NUMERIC(20, 6) NOT NULL,
    net_mass_kg NUMERIC(20, 6) NOT NULL,
    supplementary_quantity NUMERIC(20, 6) NOT NULL,
    mass_status TEXT NOT NULL
        CHECK (
            mass_status IN (
                'USABLE',
                'VALUE_WITHOUT_MASS',
                'NO_REPORTED_TRADE'
            )
        ),
    unit_value_gbp_per_kg NUMERIC(20, 6),
    world_import_value_gbp NUMERIC(20, 6) NOT NULL,
    partner_value_share NUMERIC(20, 6),
    source_query_id TEXT NOT NULL,
    source_file TEXT NOT NULL,
    reference_median_unit_value_gbp_per_kg NUMERIC(20, 6),
    unit_value_ratio_to_reference_median NUMERIC(20, 6),
    unit_value_review_flag_2_5x TEXT NOT NULL
        CHECK (
            unit_value_review_flag_2_5x IN (
                'WITHIN_BAND', 'REVIEW', 'NOT_APPLICABLE'
            )
        ),

    UNIQUE (cn8_code, partner_country_id, month_id, flow),

    FOREIGN KEY (month_id)
        REFERENCES core.dim_month (month_id),

    FOREIGN KEY (cn8_code)
        REFERENCES core.dim_commodity (cn8_code),

    FOREIGN KEY (partner_country_id)
        REFERENCES core.dim_partner_country (partner_country_id),

    FOREIGN KEY (cn8_code, month_id)
        REFERENCES core.fct_hmrc_world_monthly (cn8_code, month_id),

    CHECK (
        month_date = MAKE_DATE(calendar_year, calendar_month, 1)
    ),
    CHECK (
        month_id = calendar_year * 100 + calendar_month
    ),
    CHECK (
        (api_row_present_flag = 1 AND record_status = 'REPORTED')
        OR
        (api_row_present_flag = 0 AND record_status = 'NO_API_RECORD')
    )
);

CREATE TABLE core.supplier_master (
    supplier_id TEXT PRIMARY KEY,
    supplier_name_canonical TEXT NOT NULL,
    supplier_name_variants TEXT NOT NULL,
    raw_name_variant_count INTEGER NOT NULL
        CHECK (raw_name_variant_count >= 0),
    distinct_site_count INTEGER NOT NULL
        CHECK (distinct_site_count >= 0),
    distinct_country_count INTEGER NOT NULL
        CHECK (distinct_country_count >= 0),
    relationship_count INTEGER NOT NULL
        CHECK (relationship_count >= 0),
    product_types TEXT NOT NULL,
    source_id TEXT NOT NULL,
    snapshot_month TEXT NOT NULL
);

CREATE TABLE core.supplier_group_master (
    supplier_group_id TEXT PRIMARY KEY,
    supplier_group_name_canonical TEXT NOT NULL,
    member_supplier_ids TEXT NOT NULL,
    member_supplier_names TEXT NOT NULL,
    source_supplier_id_count INTEGER NOT NULL
        CHECK (source_supplier_id_count >= 1),
    distinct_site_count INTEGER NOT NULL
        CHECK (distinct_site_count >= 0),
    distinct_country_count INTEGER NOT NULL
        CHECK (distinct_country_count >= 0),
    relationship_count INTEGER NOT NULL
        CHECK (relationship_count >= 0),
    product_types TEXT NOT NULL,
    parent_group_ids TEXT NOT NULL,
    source_id TEXT NOT NULL,
    snapshot_month TEXT NOT NULL
);

CREATE TABLE core.supplier_resolution_map (
    supplier_id TEXT PRIMARY KEY,
    supplier_name_source_canonical TEXT NOT NULL,
    supplier_group_id TEXT NOT NULL,
    supplier_group_name_canonical TEXT NOT NULL,
    resolution_rule TEXT NOT NULL,
    review_status TEXT NOT NULL,
    match_confidence NUMERIC NOT NULL
        CHECK (match_confidence BETWEEN 0 AND 1),
    evidence_note TEXT NOT NULL,
    source_id TEXT NOT NULL,
    snapshot_month TEXT NOT NULL,

    UNIQUE (supplier_id, supplier_group_id),

    FOREIGN KEY (supplier_id)
        REFERENCES core.supplier_master (supplier_id),

    FOREIGN KEY (supplier_group_id)
        REFERENCES core.supplier_group_master (supplier_group_id)
);

CREATE TABLE core.supplier_entity_map (
    supplier_id TEXT PRIMARY KEY,
    supplier_name_canonical TEXT NOT NULL,
    entity_role TEXT NOT NULL,
    parent_group_id TEXT NOT NULL,
    ownership_status TEXT NOT NULL,
    relationship_count INTEGER NOT NULL
        CHECK (relationship_count >= 0),
    distinct_site_count INTEGER NOT NULL
        CHECK (distinct_site_count >= 0),
    parent_group_relationship_count INTEGER NOT NULL
        CHECK (parent_group_relationship_count >= 0),
    parent_group_first_flag SMALLINT NOT NULL
        CHECK (parent_group_first_flag IN (0, 1)),
    parent_group_hhi_contribution NUMERIC NOT NULL
        CHECK (parent_group_hhi_contribution >= 0),
    evidence_source_id TEXT NOT NULL,
    evidence_reference TEXT NOT NULL,
    classification_confidence TEXT NOT NULL,
    review_status TEXT NOT NULL,
    classification_note TEXT NOT NULL,

    FOREIGN KEY (supplier_id)
        REFERENCES core.supplier_master (supplier_id)
);

CREATE TABLE core.site_master (
    site_id TEXT PRIMARY KEY,
    country_raw TEXT NOT NULL,
    country_standardized TEXT NOT NULL,
    country_variants TEXT NOT NULL,
    site_name_canonical TEXT NOT NULL,
    site_name_variants TEXT NOT NULL,
    address_canonical TEXT NOT NULL,
    address_variants TEXT NOT NULL,
    product_type_standardized TEXT NOT NULL,

    female_employees INTEGER
        CHECK (female_employees >= 0),
    male_employees INTEGER
        CHECK (male_employees >= 0),
    total_employees INTEGER
        CHECK (total_employees >= 0),

    employee_data_status TEXT NOT NULL,
    trade_union_flag TEXT NOT NULL
        CHECK (trade_union_flag IN ('Yes', 'No', 'Unknown')),
    workers_committee_flag TEXT NOT NULL
        CHECK (workers_committee_flag IN ('Yes', 'No', 'Unknown')),

    supplier_count INTEGER NOT NULL
        CHECK (supplier_count >= 1),
    source_record_count INTEGER NOT NULL
        CHECK (source_record_count >= 1),
    site_consistency_flag TEXT NOT NULL,
    source_record_ids TEXT NOT NULL,
    source_id TEXT NOT NULL,
    snapshot_month TEXT NOT NULL,

    apparel_site_flag SMALLINT NOT NULL
        CHECK (apparel_site_flag IN (0, 1)),
    home_site_flag SMALLINT NOT NULL
        CHECK (home_site_flag IN (0, 1)),
    mixed_product_site_flag SMALLINT NOT NULL
        CHECK (mixed_product_site_flag IN (0, 1)),
    employee_available_site_flag SMALLINT NOT NULL
        CHECK (employee_available_site_flag IN (0, 1)),
    trade_union_yes_site_flag SMALLINT NOT NULL
        CHECK (trade_union_yes_site_flag IN (0, 1)),
    workers_committee_yes_site_flag SMALLINT NOT NULL
        CHECK (workers_committee_yes_site_flag IN (0, 1)),
    shared_site_flag SMALLINT NOT NULL
        CHECK (shared_site_flag IN (0, 1)),
    site_consistency_review_flag SMALLINT NOT NULL
        CHECK (site_consistency_review_flag IN (0, 1)),

    audit_annotation_raw TEXT,
    site_audit_status TEXT NOT NULL,
    responsible_sourcing_review_flag SMALLINT NOT NULL
        CHECK (responsible_sourcing_review_flag IN (0, 1)),

    -- Derived during loading using the documented exception rule.
    physical_site_review_flag SMALLINT NOT NULL
        CHECK (physical_site_review_flag IN (0, 1)),
    physical_site_review_status TEXT,
    physical_site_group_id TEXT,

    site_owner_group TEXT,
    site_ownership_status TEXT,
    site_ownership_evidence_source_id TEXT,
    site_ownership_evidence_reference TEXT,
    site_ownership_confidence TEXT
);

CREATE TABLE core.raw_tier1_relationships (
    source_record_id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_page INTEGER NOT NULL
        CHECK (source_page >= 1),
    source_row_on_page INTEGER NOT NULL
        CHECK (source_row_on_page >= 1),
    pdf_table_row INTEGER NOT NULL
        CHECK (pdf_table_row >= 1),

    site_id_raw TEXT NOT NULL,
    country_raw TEXT NOT NULL,
    supplier_name_raw TEXT NOT NULL,
    site_name_raw TEXT NOT NULL,
    address_raw TEXT NOT NULL,
    product_type_raw TEXT NOT NULL
        CHECK (product_type_raw IN ('APPAREL', 'HOME')),

    female_employees_raw TEXT,
    male_employees_raw TEXT,
    trade_union_raw TEXT,
    workers_committee_raw TEXT,

    extraction_status TEXT NOT NULL,
    extraction_note TEXT,
    exact_duplicate_group_count INTEGER NOT NULL
        CHECK (exact_duplicate_group_count >= 1),
    exact_duplicate_flag TEXT NOT NULL
        CHECK (exact_duplicate_flag IN ('Yes', 'No')),

    supplier_id TEXT NOT NULL,
    supplier_name_canonical TEXT NOT NULL,
    audit_annotation_raw TEXT,

    FOREIGN KEY (supplier_id)
        REFERENCES core.supplier_master (supplier_id),

    FOREIGN KEY (site_id_raw)
        REFERENCES core.site_master (site_id)
);

CREATE TABLE core.supplier_site_bridge (
    relationship_id TEXT PRIMARY KEY,
    supplier_id TEXT NOT NULL,
    supplier_name_canonical TEXT NOT NULL,
    site_id TEXT NOT NULL,
    country_raw TEXT NOT NULL,
    product_type_standardized TEXT NOT NULL
        CHECK (product_type_standardized IN ('APPAREL', 'HOME')),

    source_record_id TEXT NOT NULL,
    source_record_ids TEXT NOT NULL,
    source_record_count INTEGER NOT NULL
        CHECK (source_record_count >= 1),
    exact_duplicate_removed TEXT NOT NULL
        CHECK (exact_duplicate_removed IN ('Yes', 'No')),
    relationship_review_status TEXT NOT NULL,
    source_id TEXT NOT NULL,
    snapshot_month TEXT NOT NULL,

    country_supplier_key TEXT NOT NULL,
    country_supplier_first_flag SMALLINT NOT NULL
        CHECK (country_supplier_first_flag IN (0, 1)),
    parent_group_id TEXT NOT NULL,
    parent_group_site_first_flag SMALLINT NOT NULL
        CHECK (parent_group_site_first_flag IN (0, 1)),
    declared_channel_type TEXT NOT NULL,

    supplier_group_id TEXT NOT NULL,
    supplier_group_name_canonical TEXT NOT NULL,

    UNIQUE (supplier_id, site_id, product_type_standardized),

    FOREIGN KEY (supplier_id)
        REFERENCES core.supplier_master (supplier_id),

    FOREIGN KEY (site_id)
        REFERENCES core.site_master (site_id),

    FOREIGN KEY (source_record_id)
        REFERENCES core.raw_tier1_relationships (source_record_id),

    FOREIGN KEY (supplier_id, supplier_group_id)
        REFERENCES core.supplier_resolution_map
            (supplier_id, supplier_group_id)
);
