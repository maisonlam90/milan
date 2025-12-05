-- ============================================================
-- PRODUCT MODULE — Multi-tenant YugabyteDB Schema
-- ============================================================
-- Converted from Odoo SQL to Milan Finance architecture
-- Date: 2025-12-04 16:37:47
-- 
-- Architecture:
-- - Multi-tenant with tenant_id in PRIMARY KEY
-- - Tenant-based sharding for horizontal scalability
-- - Compatible with YugabyteDB distributed SQL
--
-- Key changes:
-- ✓ Added tenant_id to main business tables
-- ✓ Updated PRIMARY KEYs to include tenant_id
-- ✓ Added tenant sharding indexes
-- ✓ Preserved all column definitions and comments
-- ============================================================

-- ============================================================
-- Table: product_attr_exclusion_value_ids_rel
-- ============================================================

CREATE TABLE public.product_attr_exclusion_value_ids_rel (
    product_template_attribute_exclusion_id integer NOT NULL,
    product_template_attribute_value_id integer NOT NULL
);

ALTER TABLE ONLY public.product_attr_exclusion_value_ids_rel
    ADD CONSTRAINT product_attr_exclusion_value_ids_rel_pkey PRIMARY KEY (product_template_attribute_exclusion_id, product_template_attribute_value_id);

COMMENT ON TABLE public.product_attr_exclusion_value_ids_rel IS 'RELATION BETWEEN product_template_attribute_exclusion AND product_template_attribute_value';

-- ============================================================
-- Table: product_attribute
-- ============================================================

CREATE TABLE public.product_attribute (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    create_uid integer,
    write_uid integer,
    create_variant character varying NOT NULL,
    display_type character varying NOT NULL,
    name jsonb NOT NULL,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    CONSTRAINT product_attribute_check_multi_checkbox_no_variant CHECK ((display_type <> 'multi' OR create_variant = 'no_variant'))
);

ALTER TABLE ONLY public.product_attribute
    ADD CONSTRAINT product_attribute_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_attribute_tenant 
    ON public.product_attribute(tenant_id);

COMMENT ON COLUMN public.product_attribute.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_attribute IS 'Product Attribute';
COMMENT ON COLUMN public.product_attribute.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_attribute.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_attribute.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_attribute.create_variant IS 'Variant Creation';
COMMENT ON COLUMN public.product_attribute.display_type IS 'Display Type';
COMMENT ON COLUMN public.product_attribute.name IS 'Attribute';
COMMENT ON COLUMN public.product_attribute.active IS 'Active';
COMMENT ON COLUMN public.product_attribute.create_date IS 'Created on';
COMMENT ON COLUMN public.product_attribute.write_date IS 'Last Updated on';

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_attribute_name_search 
    ON public.product_attribute USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- ============================================================
-- Table: product_attribute_custom_value
-- ============================================================

CREATE TABLE public.product_attribute_custom_value (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    custom_product_template_attribute_value_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    custom_value character varying,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    sale_order_line_id integer
);

ALTER TABLE ONLY public.product_attribute_custom_value
    ADD CONSTRAINT product_attribute_custom_value_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_attribute_custom_value_tenant 
    ON public.product_attribute_custom_value(tenant_id);

COMMENT ON COLUMN public.product_attribute_custom_value.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_attribute_custom_value IS 'Product Attribute Custom Value';
COMMENT ON COLUMN public.product_attribute_custom_value.custom_product_template_attribute_value_id IS 'Attribute Value';
COMMENT ON COLUMN public.product_attribute_custom_value.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_attribute_custom_value.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_attribute_custom_value.custom_value IS 'Custom Value';
COMMENT ON COLUMN public.product_attribute_custom_value.create_date IS 'Created on';
COMMENT ON COLUMN public.product_attribute_custom_value.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_attribute_custom_value.sale_order_line_id IS 'Sales Order Line';

-- ============================================================
-- Table: product_attribute_product_template_rel
-- ============================================================

CREATE TABLE public.product_attribute_product_template_rel (
    product_attribute_id integer NOT NULL,
    product_template_id integer NOT NULL
);

ALTER TABLE ONLY public.product_attribute_product_template_rel
    ADD CONSTRAINT product_attribute_product_template_rel_pkey PRIMARY KEY (product_attribute_id, product_template_id);

COMMENT ON TABLE public.product_attribute_product_template_rel IS 'RELATION BETWEEN product_attribute AND product_template';

-- ============================================================
-- Table: product_attribute_value
-- ============================================================

CREATE TABLE public.product_attribute_value (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    attribute_id integer NOT NULL,
    color integer,
    create_uid integer,
    write_uid integer,
    html_color character varying,
    name jsonb NOT NULL,
    is_custom boolean,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    default_extra_price double precision
);

ALTER TABLE ONLY public.product_attribute_value
    ADD CONSTRAINT product_attribute_value_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_attribute_value_tenant 
    ON public.product_attribute_value(tenant_id);

COMMENT ON COLUMN public.product_attribute_value.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_attribute_value IS 'Attribute Value';
COMMENT ON COLUMN public.product_attribute_value.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_attribute_value.attribute_id IS 'Attribute';
COMMENT ON COLUMN public.product_attribute_value.color IS 'Color Index';
COMMENT ON COLUMN public.product_attribute_value.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_attribute_value.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_attribute_value.html_color IS 'Color';
COMMENT ON COLUMN public.product_attribute_value.name IS 'Value';
COMMENT ON COLUMN public.product_attribute_value.is_custom IS 'Free text';
COMMENT ON COLUMN public.product_attribute_value.active IS 'Active';
COMMENT ON COLUMN public.product_attribute_value.create_date IS 'Created on';
COMMENT ON COLUMN public.product_attribute_value.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_attribute_value.default_extra_price IS 'Default Extra Price';

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_attribute_value_name_search 
    ON public.product_attribute_value USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- Index: Text search on name
-- ============================================================
-- Table: product_attribute_value_product_template_attribute_line_rel
-- ============================================================

CREATE TABLE public.product_attribute_value_product_template_attribute_line_rel (
    product_attribute_value_id integer NOT NULL,
    product_template_attribute_line_id integer NOT NULL
);

ALTER TABLE ONLY public.product_attribute_value_product_template_attribute_line_rel
    ADD CONSTRAINT product_attribute_value_product_template_attribute_line_rel_pkey PRIMARY KEY (product_attribute_value_id, product_template_attribute_line_id);

COMMENT ON TABLE public.product_attribute_value_product_template_attribute_line_rel IS 'RELATION BETWEEN product_attribute_value AND product_template_attribute_line';

-- ============================================================
-- Table: product_category
-- ============================================================

CREATE TABLE public.product_category (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    parent_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    complete_name character varying,
    parent_path character varying,
    product_properties_definition jsonb,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    property_account_income_categ_id jsonb,
    property_account_expense_categ_id jsonb,
    removal_strategy_id integer,
    packaging_reserve_method character varying,
    property_valuation jsonb,
    property_cost_method jsonb,
    property_stock_journal jsonb,
    property_stock_valuation_account_id jsonb,
    property_price_difference_account_id jsonb
);

ALTER TABLE ONLY public.product_category
    ADD CONSTRAINT product_category_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_category_tenant 
    ON public.product_category(tenant_id);

COMMENT ON COLUMN public.product_category.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_category IS 'Product Category';
COMMENT ON COLUMN public.product_category.parent_id IS 'Parent Category';
COMMENT ON COLUMN public.product_category.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_category.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_category.name IS 'Name';
COMMENT ON COLUMN public.product_category.complete_name IS 'Complete Name';
COMMENT ON COLUMN public.product_category.parent_path IS 'Parent Path';
COMMENT ON COLUMN public.product_category.product_properties_definition IS 'Product Properties';
COMMENT ON COLUMN public.product_category.create_date IS 'Created on';
COMMENT ON COLUMN public.product_category.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_category.property_account_income_categ_id IS 'Income Account';
COMMENT ON COLUMN public.product_category.property_account_expense_categ_id IS 'Expense Account';
COMMENT ON COLUMN public.product_category.removal_strategy_id IS 'Force Removal Strategy';
COMMENT ON COLUMN public.product_category.packaging_reserve_method IS 'Reserve Packagings';
COMMENT ON COLUMN public.product_category.property_valuation IS 'Inventory Valuation';
COMMENT ON COLUMN public.product_category.property_cost_method IS 'Costing Method';
COMMENT ON COLUMN public.product_category.property_stock_journal IS 'Stock Journal';
COMMENT ON COLUMN public.product_category.property_stock_valuation_account_id IS 'Stock Valuation Account';
COMMENT ON COLUMN public.product_category.property_price_difference_account_id IS 'Price Difference Account';

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_category_name_search 
    ON public.product_category USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- Index: Text search on name
-- ============================================================
-- Table: product_combo
-- ============================================================

CREATE TABLE public.product_combo (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    company_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_combo
    ADD CONSTRAINT product_combo_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_combo_tenant 
    ON public.product_combo(tenant_id);

COMMENT ON COLUMN public.product_combo.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_combo IS 'Product Combo';
COMMENT ON COLUMN public.product_combo.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_combo.company_id IS 'Company';
COMMENT ON COLUMN public.product_combo.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_combo.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_combo.name IS 'Name';
COMMENT ON COLUMN public.product_combo.create_date IS 'Created on';
COMMENT ON COLUMN public.product_combo.write_date IS 'Last Updated on';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_combo_company 
    ON public.product_combo(tenant_id, company_id);

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_combo_name_search 
    ON public.product_combo USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- Index: Queries by company

-- Index: Text search on name
-- ============================================================
-- Table: product_combo_item
-- ============================================================

CREATE TABLE public.product_combo_item (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    company_id integer,
    combo_id integer NOT NULL,
    product_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    extra_price numeric,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_combo_item
    ADD CONSTRAINT product_combo_item_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_combo_item_tenant 
    ON public.product_combo_item(tenant_id);

COMMENT ON COLUMN public.product_combo_item.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_combo_item IS 'Product Combo Item';
COMMENT ON COLUMN public.product_combo_item.company_id IS 'Company';
COMMENT ON COLUMN public.product_combo_item.combo_id IS 'Combo';
COMMENT ON COLUMN public.product_combo_item.product_id IS 'Options';
COMMENT ON COLUMN public.product_combo_item.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_combo_item.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_combo_item.extra_price IS 'Extra Price';
COMMENT ON COLUMN public.product_combo_item.create_date IS 'Created on';
COMMENT ON COLUMN public.product_combo_item.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_combo_item_product 
    ON public.product_combo_item(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_combo_item_company 
    ON public.product_combo_item(tenant_id, company_id);

-- Index: Queries by product

-- Index: Queries by company

-- ============================================================
-- Table: product_combo_product_template_rel
-- ============================================================

CREATE TABLE public.product_combo_product_template_rel (
    product_template_id integer NOT NULL,
    product_combo_id integer NOT NULL
);

ALTER TABLE ONLY public.product_combo_product_template_rel
    ADD CONSTRAINT product_combo_product_template_rel_pkey PRIMARY KEY (product_template_id, product_combo_id);

COMMENT ON TABLE public.product_combo_product_template_rel IS 'RELATION BETWEEN product_template AND product_combo';

-- ============================================================
-- Table: product_document
-- ============================================================

CREATE TABLE public.product_document (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    ir_attachment_id integer NOT NULL,
    sequence integer,
    create_uid integer,
    write_uid integer,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    attached_on_sale character varying NOT NULL
);

ALTER TABLE ONLY public.product_document
    ADD CONSTRAINT product_document_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_document_tenant 
    ON public.product_document(tenant_id);

COMMENT ON COLUMN public.product_document.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_document IS 'Product Document';
COMMENT ON COLUMN public.product_document.ir_attachment_id IS 'Related attachment';
COMMENT ON COLUMN public.product_document.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_document.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_document.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_document.active IS 'Active';
COMMENT ON COLUMN public.product_document.create_date IS 'Created on';
COMMENT ON COLUMN public.product_document.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_document.attached_on_sale IS 'Sale : Visible at';

-- ============================================================
-- Table: product_document_sale_pdf_form_field_rel
-- ============================================================

CREATE TABLE public.product_document_sale_pdf_form_field_rel (
    product_document_id integer NOT NULL,
    sale_pdf_form_field_id integer NOT NULL
);

ALTER TABLE ONLY public.product_document_sale_pdf_form_field_rel
    ADD CONSTRAINT product_document_sale_pdf_form_field_rel_pkey PRIMARY KEY (product_document_id, sale_pdf_form_field_id);

COMMENT ON TABLE public.product_document_sale_pdf_form_field_rel IS 'RELATION BETWEEN product_document AND sale_pdf_form_field';

-- ============================================================
-- Table: product_label_layout
-- ============================================================

CREATE TABLE public.product_label_layout (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    custom_quantity integer NOT NULL,
    pricelist_id integer,
    create_uid integer,
    write_uid integer,
    print_format character varying NOT NULL,
    extra_html text,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    move_quantity character varying NOT NULL,
    zpl_template character varying NOT NULL
);

ALTER TABLE ONLY public.product_label_layout
    ADD CONSTRAINT product_label_layout_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_label_layout_tenant 
    ON public.product_label_layout(tenant_id);

COMMENT ON COLUMN public.product_label_layout.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_label_layout IS 'Choose the sheet layout to print the labels';
COMMENT ON COLUMN public.product_label_layout.custom_quantity IS 'Copies';
COMMENT ON COLUMN public.product_label_layout.pricelist_id IS 'Pricelist';
COMMENT ON COLUMN public.product_label_layout.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_label_layout.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_label_layout.print_format IS 'Format';
COMMENT ON COLUMN public.product_label_layout.extra_html IS 'Extra Content';
COMMENT ON COLUMN public.product_label_layout.create_date IS 'Created on';
COMMENT ON COLUMN public.product_label_layout.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_label_layout.move_quantity IS 'Quantity to print';
COMMENT ON COLUMN public.product_label_layout.zpl_template IS 'ZPL Template';

-- ============================================================
-- Table: product_label_layout_product_product_rel
-- ============================================================

CREATE TABLE public.product_label_layout_product_product_rel (
    product_label_layout_id integer NOT NULL,
    product_product_id integer NOT NULL
);

ALTER TABLE ONLY public.product_label_layout_product_product_rel
    ADD CONSTRAINT product_label_layout_product_product_rel_pkey PRIMARY KEY (product_label_layout_id, product_product_id);

COMMENT ON TABLE public.product_label_layout_product_product_rel IS 'RELATION BETWEEN product_label_layout AND product_product';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_label_layout_product_product_rel_product 
    ON public.product_label_layout_product_product_rel(product_product_id);

-- Index: Queries by product

-- ============================================================
-- Table: product_label_layout_product_template_rel
-- ============================================================

CREATE TABLE public.product_label_layout_product_template_rel (
    product_label_layout_id integer NOT NULL,
    product_template_id integer NOT NULL
);

ALTER TABLE ONLY public.product_label_layout_product_template_rel
    ADD CONSTRAINT product_label_layout_product_template_rel_pkey PRIMARY KEY (product_label_layout_id, product_template_id);

COMMENT ON TABLE public.product_label_layout_product_template_rel IS 'RELATION BETWEEN product_label_layout AND product_template';

-- ============================================================
-- Table: product_label_layout_stock_move_rel
-- ============================================================

CREATE TABLE public.product_label_layout_stock_move_rel (
    product_label_layout_id integer NOT NULL,
    stock_move_id integer NOT NULL
);

ALTER TABLE ONLY public.product_label_layout_stock_move_rel
    ADD CONSTRAINT product_label_layout_stock_move_rel_pkey PRIMARY KEY (product_label_layout_id, stock_move_id);

COMMENT ON TABLE public.product_label_layout_stock_move_rel IS 'RELATION BETWEEN product_label_layout AND stock_move';

-- ============================================================
-- Table: product_optional_rel
-- ============================================================

CREATE TABLE public.product_optional_rel (
    src_id integer NOT NULL,
    dest_id integer NOT NULL
);

ALTER TABLE ONLY public.product_optional_rel
    ADD CONSTRAINT product_optional_rel_pkey PRIMARY KEY (src_id, dest_id);

COMMENT ON TABLE public.product_optional_rel IS 'RELATION BETWEEN product_template AND product_template';

-- ============================================================
-- Table: product_pricelist
-- ============================================================

CREATE TABLE public.product_pricelist (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    currency_id integer NOT NULL,
    company_id integer,
    create_uid integer,
    write_uid integer,
    name jsonb NOT NULL,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_pricelist
    ADD CONSTRAINT product_pricelist_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_pricelist_tenant 
    ON public.product_pricelist(tenant_id);

COMMENT ON COLUMN public.product_pricelist.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_pricelist IS 'Pricelist';
COMMENT ON COLUMN public.product_pricelist.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_pricelist.currency_id IS 'Currency';
COMMENT ON COLUMN public.product_pricelist.company_id IS 'Company';
COMMENT ON COLUMN public.product_pricelist.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_pricelist.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_pricelist.name IS 'Pricelist Name';
COMMENT ON COLUMN public.product_pricelist.active IS 'Active';
COMMENT ON COLUMN public.product_pricelist.create_date IS 'Created on';
COMMENT ON COLUMN public.product_pricelist.write_date IS 'Last Updated on';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_pricelist_company 
    ON public.product_pricelist(tenant_id, company_id);

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_pricelist_name_search 
    ON public.product_pricelist USING gin(to_tsvector('english', COALESCE(name::text, '')));
-- ============================================================
-- Table: product_pricelist_item
-- ============================================================

CREATE TABLE public.product_pricelist_item (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    pricelist_id integer,
    company_id integer,
    currency_id integer,
    categ_id integer,
    product_tmpl_id integer,
    product_id integer,
    base_pricelist_id integer,
    create_uid integer,
    write_uid integer,
    applied_on character varying NOT NULL,
    display_applied_on character varying NOT NULL,
    base character varying NOT NULL,
    compute_price character varying NOT NULL,
    min_quantity numeric,
    fixed_price numeric,
    price_discount numeric,
    price_round numeric,
    price_surcharge numeric,
    price_markup numeric,
    price_min_margin numeric,
    price_max_margin numeric,
    date_start timestamp without time zone,
    date_end timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    percent_price double precision
);

ALTER TABLE ONLY public.product_pricelist_item
    ADD CONSTRAINT product_pricelist_item_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_pricelist_item_tenant 
    ON public.product_pricelist_item(tenant_id);

COMMENT ON COLUMN public.product_pricelist_item.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_pricelist_item IS 'Pricelist Rule';
COMMENT ON COLUMN public.product_pricelist_item.pricelist_id IS 'Pricelist';
COMMENT ON COLUMN public.product_pricelist_item.company_id IS 'Company';
COMMENT ON COLUMN public.product_pricelist_item.currency_id IS 'Currency';
COMMENT ON COLUMN public.product_pricelist_item.categ_id IS 'Category';
COMMENT ON COLUMN public.product_pricelist_item.product_tmpl_id IS 'Product';
COMMENT ON COLUMN public.product_pricelist_item.product_id IS 'Variant';
COMMENT ON COLUMN public.product_pricelist_item.base_pricelist_id IS 'Other Pricelist';
COMMENT ON COLUMN public.product_pricelist_item.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_pricelist_item.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_pricelist_item.applied_on IS 'Apply On';
COMMENT ON COLUMN public.product_pricelist_item.display_applied_on IS 'Display Applied On';
COMMENT ON COLUMN public.product_pricelist_item.base IS 'Based on';
COMMENT ON COLUMN public.product_pricelist_item.compute_price IS 'Compute Price';
COMMENT ON COLUMN public.product_pricelist_item.min_quantity IS 'Min. Quantity';
COMMENT ON COLUMN public.product_pricelist_item.fixed_price IS 'Fixed Price';
COMMENT ON COLUMN public.product_pricelist_item.price_discount IS 'Price Discount';
COMMENT ON COLUMN public.product_pricelist_item.price_round IS 'Price Rounding';
COMMENT ON COLUMN public.product_pricelist_item.price_surcharge IS 'Extra Fee';
COMMENT ON COLUMN public.product_pricelist_item.price_markup IS 'Markup';
COMMENT ON COLUMN public.product_pricelist_item.price_min_margin IS 'Min. Price Margin';
COMMENT ON COLUMN public.product_pricelist_item.price_max_margin IS 'Max. Price Margin';
COMMENT ON COLUMN public.product_pricelist_item.date_start IS 'Start Date';
COMMENT ON COLUMN public.product_pricelist_item.date_end IS 'End Date';
COMMENT ON COLUMN public.product_pricelist_item.create_date IS 'Created on';
COMMENT ON COLUMN public.product_pricelist_item.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_pricelist_item.percent_price IS 'Percentage Price';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_pricelist_item_product 
    ON public.product_pricelist_item(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_pricelist_item_company 
    ON public.product_pricelist_item(tenant_id, company_id);

-- Index: Queries by category
CREATE INDEX IF NOT EXISTS idx_product_pricelist_item_category 
    ON public.product_pricelist_item(tenant_id, categ_id);

-- ============================================================
-- Table: product_product
-- ============================================================

CREATE TABLE public.product_product (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_tmpl_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    default_code character varying,
    barcode character varying,
    combination_indices character varying,
    standard_price jsonb,
    volume numeric,
    weight numeric,
    active boolean,
    can_image_variant_1024_be_zoomed boolean,
    is_favorite boolean,
    is_in_selected_section_of_order boolean,
    write_date timestamp without time zone,
    create_date timestamp without time zone,
    lot_properties_definition jsonb
);

ALTER TABLE ONLY public.product_product
    ADD CONSTRAINT product_product_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_product_tenant 
    ON public.product_product(tenant_id);

COMMENT ON COLUMN public.product_product.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_product IS 'Product Variant';
COMMENT ON COLUMN public.product_product.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.product_product.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_product.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_product.default_code IS 'Internal Reference';
COMMENT ON COLUMN public.product_product.barcode IS 'Barcode';
COMMENT ON COLUMN public.product_product.combination_indices IS 'Combination Indices';
COMMENT ON COLUMN public.product_product.standard_price IS 'Cost';
COMMENT ON COLUMN public.product_product.volume IS 'Volume';
COMMENT ON COLUMN public.product_product.weight IS 'Weight';
COMMENT ON COLUMN public.product_product.active IS 'Active';
COMMENT ON COLUMN public.product_product.can_image_variant_1024_be_zoomed IS 'Can Variant Image 1024 be zoomed';
COMMENT ON COLUMN public.product_product.is_favorite IS 'Favorite';
COMMENT ON COLUMN public.product_product.is_in_selected_section_of_order IS 'Is In Selected Section Of Order';
COMMENT ON COLUMN public.product_product.write_date IS 'Write Date';
COMMENT ON COLUMN public.product_product.create_date IS 'Created on';
COMMENT ON COLUMN public.product_product.lot_properties_definition IS 'Lot Properties';

-- ============================================================
-- Table: product_removal
-- ============================================================

CREATE TABLE public.product_removal (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    name jsonb NOT NULL,
    method jsonb NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_removal
    ADD CONSTRAINT product_removal_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_removal_tenant 
    ON public.product_removal(tenant_id);

COMMENT ON COLUMN public.product_removal.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_removal IS 'Removal Strategy';
COMMENT ON COLUMN public.product_removal.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_removal.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_removal.name IS 'Name';
COMMENT ON COLUMN public.product_removal.method IS 'Method';
COMMENT ON COLUMN public.product_removal.create_date IS 'Created on';
COMMENT ON COLUMN public.product_removal.write_date IS 'Last Updated on';

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_removal_name_search 
    ON public.product_removal USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- Index: Text search on name
-- ============================================================
-- Table: product_replenish
-- ============================================================

CREATE TABLE public.product_replenish (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    route_id integer,
    product_id integer NOT NULL,
    product_tmpl_id integer NOT NULL,
    product_uom_id integer NOT NULL,
    warehouse_id integer NOT NULL,
    company_id integer,
    create_uid integer,
    write_uid integer,
    product_has_variants boolean NOT NULL,
    date_planned timestamp without time zone NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    quantity double precision NOT NULL,
    supplier_id integer
);

ALTER TABLE ONLY public.product_replenish
    ADD CONSTRAINT product_replenish_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_replenish_tenant 
    ON public.product_replenish(tenant_id);

COMMENT ON COLUMN public.product_replenish.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_replenish IS 'Product Replenish';
COMMENT ON COLUMN public.product_replenish.route_id IS 'Preferred Route';
COMMENT ON COLUMN public.product_replenish.product_id IS 'Product';
COMMENT ON COLUMN public.product_replenish.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.product_replenish.product_uom_id IS 'Unity of measure';
COMMENT ON COLUMN public.product_replenish.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.product_replenish.company_id IS 'Company';
COMMENT ON COLUMN public.product_replenish.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_replenish.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_replenish.product_has_variants IS 'Has variants';
COMMENT ON COLUMN public.product_replenish.date_planned IS 'Scheduled Date';
COMMENT ON COLUMN public.product_replenish.create_date IS 'Created on';
COMMENT ON COLUMN public.product_replenish.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_replenish.quantity IS 'Quantity';
COMMENT ON COLUMN public.product_replenish.supplier_id IS 'Vendor';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_replenish_product 
    ON public.product_replenish(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_replenish_company 
    ON public.product_replenish(tenant_id, company_id);

-- Index: Queries by product

-- Index: Queries by company

-- ============================================================
-- Table: product_supplier_taxes_rel
-- ============================================================

CREATE TABLE public.product_supplier_taxes_rel (
    prod_id integer NOT NULL,
    tax_id integer NOT NULL
);

ALTER TABLE ONLY public.product_supplier_taxes_rel
    ADD CONSTRAINT product_supplier_taxes_rel_pkey PRIMARY KEY (prod_id, tax_id);

COMMENT ON TABLE public.product_supplier_taxes_rel IS 'RELATION BETWEEN product_template AND account_tax';

-- ============================================================
-- Table: product_supplierinfo
-- ============================================================

CREATE TABLE public.product_supplierinfo (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    partner_id integer NOT NULL,
    sequence integer,
    product_uom_id integer NOT NULL,
    company_id integer,
    currency_id integer NOT NULL,
    product_id integer,
    product_tmpl_id integer NOT NULL,
    delay integer NOT NULL,
    create_uid integer,
    write_uid integer,
    product_name character varying,
    product_code character varying,
    date_start date,
    date_end date,
    min_qty numeric NOT NULL,
    price numeric,
    discount numeric,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_supplierinfo
    ADD CONSTRAINT product_supplierinfo_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_supplierinfo_tenant 
    ON public.product_supplierinfo(tenant_id);

COMMENT ON COLUMN public.product_supplierinfo.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_supplierinfo IS 'Supplier Pricelist';
COMMENT ON COLUMN public.product_supplierinfo.partner_id IS 'Vendor';
COMMENT ON COLUMN public.product_supplierinfo.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_supplierinfo.product_uom_id IS 'Unit';
COMMENT ON COLUMN public.product_supplierinfo.company_id IS 'Company';
COMMENT ON COLUMN public.product_supplierinfo.currency_id IS 'Currency';
COMMENT ON COLUMN public.product_supplierinfo.product_id IS 'Product Variant';
COMMENT ON COLUMN public.product_supplierinfo.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.product_supplierinfo.delay IS 'Lead Time';
COMMENT ON COLUMN public.product_supplierinfo.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_supplierinfo.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_supplierinfo.product_name IS 'Vendor Product Name';
COMMENT ON COLUMN public.product_supplierinfo.product_code IS 'Vendor Product Code';
COMMENT ON COLUMN public.product_supplierinfo.date_start IS 'Start Date';
COMMENT ON COLUMN public.product_supplierinfo.date_end IS 'End Date';
COMMENT ON COLUMN public.product_supplierinfo.min_qty IS 'Quantity';
COMMENT ON COLUMN public.product_supplierinfo.price IS 'Unit Price';
COMMENT ON COLUMN public.product_supplierinfo.discount IS 'Discount (%)';
COMMENT ON COLUMN public.product_supplierinfo.create_date IS 'Created on';
COMMENT ON COLUMN public.product_supplierinfo.write_date IS 'Last Updated on';

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_product_supplierinfo_partner 
    ON public.product_supplierinfo(tenant_id, partner_id);

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_supplierinfo_product 
    ON public.product_supplierinfo(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_supplierinfo_company 
    ON public.product_supplierinfo(tenant_id, company_id);

-- Index: Text search on product_name
CREATE INDEX IF NOT EXISTS idx_product_supplierinfo_name_search 
    ON public.product_supplierinfo USING gin(to_tsvector('english', COALESCE(product_name::text, '')));

-- ============================================================
-- Table: product_supplierinfo_stock_replenishment_info_rel
-- ============================================================

CREATE TABLE public.product_supplierinfo_stock_replenishment_info_rel (
    stock_replenishment_info_id integer NOT NULL,
    product_supplierinfo_id integer NOT NULL
);

ALTER TABLE ONLY public.product_supplierinfo_stock_replenishment_info_rel
    ADD CONSTRAINT product_supplierinfo_stock_replenishment_info_rel_pkey PRIMARY KEY (stock_replenishment_info_id, product_supplierinfo_id);

COMMENT ON TABLE public.product_supplierinfo_stock_replenishment_info_rel IS 'RELATION BETWEEN stock_replenishment_info AND product_supplierinfo';

-- ============================================================
-- Table: product_tag
-- ============================================================

CREATE TABLE public.product_tag (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    create_uid integer,
    write_uid integer,
    color character varying,
    name jsonb NOT NULL,
    visible_to_customers boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_tag
    ADD CONSTRAINT product_tag_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_tag_tenant 
    ON public.product_tag(tenant_id);

COMMENT ON COLUMN public.product_tag.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_tag IS 'Product Tag';
COMMENT ON COLUMN public.product_tag.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_tag.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_tag.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_tag.color IS 'Color';
COMMENT ON COLUMN public.product_tag.name IS 'Name';
COMMENT ON COLUMN public.product_tag.visible_to_customers IS 'Visible to customers';
COMMENT ON COLUMN public.product_tag.create_date IS 'Created on';
COMMENT ON COLUMN public.product_tag.write_date IS 'Last Updated on';

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_tag_name_search 
    ON public.product_tag USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- Index: Text search on name
-- ============================================================
-- Table: product_tag_product_product_rel
-- ============================================================

CREATE TABLE public.product_tag_product_product_rel (
    product_product_id integer NOT NULL,
    product_tag_id integer NOT NULL
);

ALTER TABLE ONLY public.product_tag_product_product_rel
    ADD CONSTRAINT product_tag_product_product_rel_pkey PRIMARY KEY (product_product_id, product_tag_id);

COMMENT ON TABLE public.product_tag_product_product_rel IS 'RELATION BETWEEN product_product AND product_tag';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_tag_product_product_rel_product 
    ON public.product_tag_product_product_rel(product_product_id);

-- Index: Queries by product

-- ============================================================
-- Table: product_tag_product_template_rel
-- ============================================================

CREATE TABLE public.product_tag_product_template_rel (
    product_template_id integer NOT NULL,
    product_tag_id integer NOT NULL
);

ALTER TABLE ONLY public.product_tag_product_template_rel
    ADD CONSTRAINT product_tag_product_template_rel_pkey PRIMARY KEY (product_template_id, product_tag_id);

COMMENT ON TABLE public.product_tag_product_template_rel IS 'RELATION BETWEEN product_template AND product_tag';

-- ============================================================
-- Table: product_taxes_rel
-- ============================================================

CREATE TABLE public.product_taxes_rel (
    prod_id integer NOT NULL,
    tax_id integer NOT NULL
);

ALTER TABLE ONLY public.product_taxes_rel
    ADD CONSTRAINT product_taxes_rel_pkey PRIMARY KEY (prod_id, tax_id);

COMMENT ON TABLE public.product_taxes_rel IS 'RELATION BETWEEN product_template AND account_tax';

-- ============================================================
-- Table: product_template
-- ============================================================

CREATE TABLE public.product_template (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    categ_id integer,
    uom_id integer NOT NULL,
    company_id integer,
    color integer,
    create_uid integer,
    write_uid integer,
    type character varying NOT NULL,
    service_tracking character varying NOT NULL,
    default_code character varying,
    name jsonb NOT NULL,
    description jsonb,
    description_purchase jsonb,
    description_sale jsonb,
    product_properties jsonb,
    list_price numeric,
    volume numeric,
    weight numeric,
    sale_ok boolean,
    purchase_ok boolean,
    active boolean,
    can_image_1024_be_zoomed boolean,
    has_configurable_attributes boolean,
    is_favorite boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    property_account_income_id jsonb,
    property_account_expense_id jsonb,
    service_type character varying,
    expense_policy character varying,
    invoice_policy character varying,
    sale_line_warn_msg text,
    purchase_method character varying,
    purchase_line_warn_msg text,
    service_to_purchase jsonb,
    sale_delay integer,
    lot_sequence_id integer,
    tracking character varying NOT NULL,
    responsible_id jsonb,
    property_stock_production jsonb,
    property_stock_inventory jsonb,
    description_picking jsonb,
    description_pickingout jsonb,
    description_pickingin jsonb,
    is_storable boolean,
    property_price_difference_account_id jsonb,
    lot_valuated boolean
);

ALTER TABLE ONLY public.product_template
    ADD CONSTRAINT product_template_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_template_tenant 
    ON public.product_template(tenant_id);

COMMENT ON COLUMN public.product_template.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_template IS 'Product';
COMMENT ON COLUMN public.product_template.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_template.categ_id IS 'Product Category';
COMMENT ON COLUMN public.product_template.uom_id IS 'Unit';
COMMENT ON COLUMN public.product_template.company_id IS 'Company';
COMMENT ON COLUMN public.product_template.color IS 'Color Index';
COMMENT ON COLUMN public.product_template.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_template.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_template.type IS 'Product Type';
COMMENT ON COLUMN public.product_template.service_tracking IS 'Create on Order';
COMMENT ON COLUMN public.product_template.default_code IS 'Internal Reference';
COMMENT ON COLUMN public.product_template.name IS 'Name';
COMMENT ON COLUMN public.product_template.description IS 'Description';
COMMENT ON COLUMN public.product_template.description_purchase IS 'Purchase Description';
COMMENT ON COLUMN public.product_template.description_sale IS 'Sales Description';
COMMENT ON COLUMN public.product_template.product_properties IS 'Properties';
COMMENT ON COLUMN public.product_template.list_price IS 'Sales Price';
COMMENT ON COLUMN public.product_template.volume IS 'Volume';
COMMENT ON COLUMN public.product_template.weight IS 'Weight';
COMMENT ON COLUMN public.product_template.sale_ok IS 'Sales';
COMMENT ON COLUMN public.product_template.purchase_ok IS 'Purchase';
COMMENT ON COLUMN public.product_template.active IS 'Active';
COMMENT ON COLUMN public.product_template.can_image_1024_be_zoomed IS 'Can Image 1024 be zoomed';
COMMENT ON COLUMN public.product_template.has_configurable_attributes IS 'Is a configurable product';
COMMENT ON COLUMN public.product_template.is_favorite IS 'Favorite';
COMMENT ON COLUMN public.product_template.create_date IS 'Created on';
COMMENT ON COLUMN public.product_template.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.product_template.property_account_income_id IS 'Income Account';
COMMENT ON COLUMN public.product_template.property_account_expense_id IS 'Expense Account';
COMMENT ON COLUMN public.product_template.service_type IS 'Track Service';
COMMENT ON COLUMN public.product_template.expense_policy IS 'Re-Invoice Costs';
COMMENT ON COLUMN public.product_template.invoice_policy IS 'Invoicing Policy';
COMMENT ON COLUMN public.product_template.sale_line_warn_msg IS 'Sales Order Line Warning';
COMMENT ON COLUMN public.product_template.purchase_method IS 'Control Policy';
COMMENT ON COLUMN public.product_template.purchase_line_warn_msg IS 'Message for Purchase Order Line';
COMMENT ON COLUMN public.product_template.service_to_purchase IS 'Subcontract Service';
COMMENT ON COLUMN public.product_template.sale_delay IS 'Customer Lead Time';
COMMENT ON COLUMN public.product_template.lot_sequence_id IS 'Serial/Lot Numbers Sequence';
COMMENT ON COLUMN public.product_template.tracking IS 'Tracking';
COMMENT ON COLUMN public.product_template.responsible_id IS 'Responsible';
COMMENT ON COLUMN public.product_template.property_stock_production IS 'Production Location';
COMMENT ON COLUMN public.product_template.property_stock_inventory IS 'Inventory Location';
COMMENT ON COLUMN public.product_template.description_picking IS 'Description on Picking';
COMMENT ON COLUMN public.product_template.description_pickingout IS 'Description on Delivery Orders';
COMMENT ON COLUMN public.product_template.description_pickingin IS 'Description on Receptions';
COMMENT ON COLUMN public.product_template.is_storable IS 'Track Inventory';
COMMENT ON COLUMN public.product_template.property_price_difference_account_id IS 'Price Difference Account';
COMMENT ON COLUMN public.product_template.lot_valuated IS 'Valuation by Lot/Serial';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_template_company 
    ON public.product_template(tenant_id, company_id);

-- Index: Queries by category
CREATE INDEX IF NOT EXISTS idx_product_template_category 
    ON public.product_template(tenant_id, categ_id);

-- Index: Text search on name
CREATE INDEX IF NOT EXISTS idx_product_template_name_search 
    ON public.product_template USING gin(to_tsvector('english', COALESCE(name::text, '')));

-- Index: Queries by company

-- Index: Queries by category

-- Index: Text search on name

-- ============================================================
-- Table: product_template_attribute_exclusion
-- ============================================================

CREATE TABLE public.product_template_attribute_exclusion (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_template_attribute_value_id integer,
    product_tmpl_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_template_attribute_exclusion
    ADD CONSTRAINT product_template_attribute_exclusion_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_template_attribute_exclusion_tenant 
    ON public.product_template_attribute_exclusion(tenant_id);

COMMENT ON COLUMN public.product_template_attribute_exclusion.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_template_attribute_exclusion IS 'Product Template Attribute Exclusion';
COMMENT ON COLUMN public.product_template_attribute_exclusion.product_template_attribute_value_id IS 'Attribute Value';
COMMENT ON COLUMN public.product_template_attribute_exclusion.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.product_template_attribute_exclusion.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_template_attribute_exclusion.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_template_attribute_exclusion.create_date IS 'Created on';
COMMENT ON COLUMN public.product_template_attribute_exclusion.write_date IS 'Last Updated on';

-- ============================================================
-- Table: product_template_attribute_line
-- ============================================================

CREATE TABLE public.product_template_attribute_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_tmpl_id integer NOT NULL,
    sequence integer,
    attribute_id integer NOT NULL,
    value_count integer,
    create_uid integer,
    write_uid integer,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_template_attribute_line
    ADD CONSTRAINT product_template_attribute_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_template_attribute_line_tenant 
    ON public.product_template_attribute_line(tenant_id);

COMMENT ON COLUMN public.product_template_attribute_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_template_attribute_line IS 'Product Template Attribute Line';
COMMENT ON COLUMN public.product_template_attribute_line.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.product_template_attribute_line.sequence IS 'Sequence';
COMMENT ON COLUMN public.product_template_attribute_line.attribute_id IS 'Attribute';
COMMENT ON COLUMN public.product_template_attribute_line.value_count IS 'Value Count';
COMMENT ON COLUMN public.product_template_attribute_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_template_attribute_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_template_attribute_line.active IS 'Active';
COMMENT ON COLUMN public.product_template_attribute_line.create_date IS 'Created on';
COMMENT ON COLUMN public.product_template_attribute_line.write_date IS 'Last Updated on';

-- ============================================================
-- Table: product_template_attribute_value
-- ============================================================

CREATE TABLE public.product_template_attribute_value (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_attribute_value_id integer NOT NULL,
    attribute_line_id integer NOT NULL,
    product_tmpl_id integer,
    attribute_id integer,
    color integer,
    create_uid integer,
    write_uid integer,
    price_extra numeric,
    ptav_active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_template_attribute_value
    ADD CONSTRAINT product_template_attribute_value_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_template_attribute_value_tenant 
    ON public.product_template_attribute_value(tenant_id);

COMMENT ON COLUMN public.product_template_attribute_value.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_template_attribute_value IS 'Product Template Attribute Value';
COMMENT ON COLUMN public.product_template_attribute_value.product_attribute_value_id IS 'Attribute Value';
COMMENT ON COLUMN public.product_template_attribute_value.attribute_line_id IS 'Attribute Line';
COMMENT ON COLUMN public.product_template_attribute_value.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.product_template_attribute_value.attribute_id IS 'Attribute';
COMMENT ON COLUMN public.product_template_attribute_value.color IS 'Color';
COMMENT ON COLUMN public.product_template_attribute_value.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_template_attribute_value.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_template_attribute_value.price_extra IS 'Extra Price';
COMMENT ON COLUMN public.product_template_attribute_value.ptav_active IS 'Active';
COMMENT ON COLUMN public.product_template_attribute_value.create_date IS 'Created on';
COMMENT ON COLUMN public.product_template_attribute_value.write_date IS 'Last Updated on';

-- ============================================================
-- Table: product_template_attribute_value_purchase_order_line_rel
-- ============================================================

CREATE TABLE public.product_template_attribute_value_purchase_order_line_rel (
    purchase_order_line_id integer NOT NULL,
    product_template_attribute_value_id integer NOT NULL
);

ALTER TABLE ONLY public.product_template_attribute_value_purchase_order_line_rel
    ADD CONSTRAINT product_template_attribute_value_purchase_order_line_rel_pkey PRIMARY KEY (purchase_order_line_id, product_template_attribute_value_id);

COMMENT ON TABLE public.product_template_attribute_value_purchase_order_line_rel IS 'RELATION BETWEEN purchase_order_line AND product_template_attribute_value';

-- ============================================================
-- Table: product_template_attribute_value_sale_order_line_rel
-- ============================================================

CREATE TABLE public.product_template_attribute_value_sale_order_line_rel (
    sale_order_line_id integer NOT NULL,
    product_template_attribute_value_id integer NOT NULL
);

ALTER TABLE ONLY public.product_template_attribute_value_sale_order_line_rel
    ADD CONSTRAINT product_template_attribute_value_sale_order_line_rel_pkey PRIMARY KEY (sale_order_line_id, product_template_attribute_value_id);

COMMENT ON TABLE public.product_template_attribute_value_sale_order_line_rel IS 'RELATION BETWEEN sale_order_line AND product_template_attribute_value';

-- ============================================================
-- Table: product_template_uom_uom_rel
-- ============================================================

CREATE TABLE public.product_template_uom_uom_rel (
    product_template_id integer NOT NULL,
    uom_uom_id integer NOT NULL
);

ALTER TABLE ONLY public.product_template_uom_uom_rel
    ADD CONSTRAINT product_template_uom_uom_rel_pkey PRIMARY KEY (product_template_id, uom_uom_id);

COMMENT ON TABLE public.product_template_uom_uom_rel IS 'RELATION BETWEEN product_template AND uom_uom';

-- ============================================================
-- Table: product_uom
-- ============================================================

CREATE TABLE public.product_uom (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    uom_id integer NOT NULL,
    product_id integer NOT NULL,
    company_id integer,
    create_uid integer,
    write_uid integer,
    barcode character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_uom
    ADD CONSTRAINT product_uom_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_uom_tenant 
    ON public.product_uom(tenant_id);

COMMENT ON COLUMN public.product_uom.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_uom IS 'Link between products and their UoMs';
COMMENT ON COLUMN public.product_uom.uom_id IS 'Unit';
COMMENT ON COLUMN public.product_uom.product_id IS 'Product';
COMMENT ON COLUMN public.product_uom.company_id IS 'Company';
COMMENT ON COLUMN public.product_uom.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_uom.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_uom.barcode IS 'Barcode';
COMMENT ON COLUMN public.product_uom.create_date IS 'Created on';
COMMENT ON COLUMN public.product_uom.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_uom_product 
    ON public.product_uom(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_uom_company 
    ON public.product_uom(tenant_id, company_id);

-- Index: Queries by product

-- Index: Queries by company

-- ============================================================
-- Table: product_value
-- ============================================================

CREATE TABLE public.product_value (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer,
    lot_id integer,
    move_id integer,
    company_id integer NOT NULL,
    user_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    description character varying,
    value numeric NOT NULL,
    date timestamp without time zone NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.product_value
    ADD CONSTRAINT product_value_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_value_tenant 
    ON public.product_value(tenant_id);

COMMENT ON COLUMN public.product_value.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_value IS 'Product Value';
COMMENT ON COLUMN public.product_value.product_id IS 'Product';
COMMENT ON COLUMN public.product_value.lot_id IS 'Lot';
COMMENT ON COLUMN public.product_value.move_id IS 'Move';
COMMENT ON COLUMN public.product_value.company_id IS 'Company';
COMMENT ON COLUMN public.product_value.user_id IS 'User';
COMMENT ON COLUMN public.product_value.create_uid IS 'Created by';
COMMENT ON COLUMN public.product_value.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.product_value.description IS 'Description';
COMMENT ON COLUMN public.product_value.value IS 'Value';
COMMENT ON COLUMN public.product_value.date IS 'Date';
COMMENT ON COLUMN public.product_value.create_date IS 'Created on';
COMMENT ON COLUMN public.product_value.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_value_product 
    ON public.product_value(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_product_value_company 
    ON public.product_value(tenant_id, company_id);

-- Index: Queries by product

-- Index: Queries by company

-- ============================================================
-- Table: product_variant_combination
-- ============================================================

CREATE TABLE public.product_variant_combination (
    tenant_id UUID NOT NULL,
    product_product_id integer NOT NULL,
    product_template_attribute_value_id integer NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_product_variant_combination_tenant 
    ON public.product_variant_combination(tenant_id);

COMMENT ON COLUMN public.product_variant_combination.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.product_variant_combination IS 'RELATION BETWEEN product_product AND product_template_attribute_value';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_product_variant_combination_product 
    ON public.product_variant_combination(tenant_id, product_product_id);

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_variant_combination_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_product_variant_combination_updated_at
    BEFORE UPDATE ON public.product_variant_combination
    FOR EACH ROW
    EXECUTE FUNCTION update_product_variant_combination_timestamp();

-- ============================================================
