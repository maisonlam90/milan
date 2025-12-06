-- ============================================================
-- SALE MODULE — Multi-tenant YugabyteDB Schema
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
-- Table: sale_advance_payment_inv
-- ============================================================

CREATE TABLE public.sale_advance_payment_inv (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    currency_id integer,
    company_id integer,
    create_uid integer,
    write_uid integer,
    advance_payment_method character varying NOT NULL,
    fixed_amount numeric,
    deduct_down_payments boolean,
    consolidated_billing boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    amount double precision,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ONLY public.sale_advance_payment_inv
    ADD CONSTRAINT sale_advance_payment_inv_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_advance_payment_inv_tenant 
    ON public.sale_advance_payment_inv(tenant_id);

COMMENT ON COLUMN public.sale_advance_payment_inv.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_advance_payment_inv IS 'Sales Advance Payment Invoice';
COMMENT ON COLUMN public.sale_advance_payment_inv.currency_id IS 'Currency';
COMMENT ON COLUMN public.sale_advance_payment_inv.company_id IS 'Company';
COMMENT ON COLUMN public.sale_advance_payment_inv.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_advance_payment_inv.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_advance_payment_inv.advance_payment_method IS 'Create Invoice';
COMMENT ON COLUMN public.sale_advance_payment_inv.fixed_amount IS 'Down Payment Amount (Fixed)';
COMMENT ON COLUMN public.sale_advance_payment_inv.deduct_down_payments IS 'Deduct down payments';
COMMENT ON COLUMN public.sale_advance_payment_inv.consolidated_billing IS 'Consolidated Billing';
COMMENT ON COLUMN public.sale_advance_payment_inv.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_advance_payment_inv.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.sale_advance_payment_inv.amount IS 'Down Payment';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_sale_advance_payment_inv_company 
    ON public.sale_advance_payment_inv(tenant_id, company_id);
-- ============================================================
-- Table: sale_advance_payment_inv_sale_order_rel
-- ============================================================

CREATE TABLE public.sale_advance_payment_inv_sale_order_rel (
    sale_advance_payment_inv_id UUID NOT NULL,
    sale_order_id UUID NOT NULL
);

ALTER TABLE ONLY public.sale_advance_payment_inv_sale_order_rel
    ADD CONSTRAINT sale_advance_payment_inv_sale_order_rel_pkey PRIMARY KEY (sale_advance_payment_inv_id, sale_order_id);

COMMENT ON TABLE public.sale_advance_payment_inv_sale_order_rel IS 'RELATION BETWEEN sale_advance_payment_inv AND sale_order';

-- ============================================================
-- Table: sale_mass_cancel_orders
-- ============================================================

CREATE TABLE public.sale_mass_cancel_orders (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ONLY public.sale_mass_cancel_orders
    ADD CONSTRAINT sale_mass_cancel_orders_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_mass_cancel_orders_tenant 
    ON public.sale_mass_cancel_orders(tenant_id);

COMMENT ON COLUMN public.sale_mass_cancel_orders.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_mass_cancel_orders IS 'Cancel multiple quotations';
COMMENT ON COLUMN public.sale_mass_cancel_orders.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_mass_cancel_orders.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_mass_cancel_orders.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_mass_cancel_orders.write_date IS 'Last Updated on';

-- ============================================================
-- Table: sale_order
-- ============================================================

CREATE TABLE public.sale_order (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    campaign_id integer,
    source_id integer,
    medium_id integer,
    company_id integer NOT NULL,
    partner_id integer NOT NULL,
    pending_email_template_id integer,
    journal_id integer,
    partner_invoice_id integer NOT NULL,
    partner_shipping_id integer NOT NULL,
    fiscal_position_id integer,
    payment_term_id integer,
    preferred_payment_method_line_id integer,
    pricelist_id integer,
    currency_id integer,
    user_id integer,
    team_id integer,
    create_uid integer,
    write_uid integer,
    access_token character varying,
    name character varying NOT NULL,
    state character varying,
    client_order_ref character varying,
    origin character varying,
    reference character varying,
    signed_by character varying,
    invoice_status character varying,
    validity_date date,
    note text,
    currency_rate numeric,
    amount_untaxed numeric,
    amount_tax numeric,
    amount_total numeric,
    locked boolean,
    require_signature boolean,
    require_payment boolean,
    create_date timestamp without time zone,
    commitment_date timestamp without time zone,
    date_order timestamp without time zone NOT NULL,
    signed_on timestamp without time zone,
    write_date timestamp without time zone,
    prepayment_percent double precision,
    sale_order_template_id UUID,
    customizable_pdf_form_fields jsonb,
    incoterm integer,
    warehouse_id integer,
    incoterm_location character varying,
    picking_policy character varying NOT NULL,
    delivery_status character varying,
    effective_date timestamp without time zone,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
,
    CONSTRAINT sale_order_date_order_conditional_required CHECK (((state = 'sale' AND date_order IS NOT NULL) OR state != 'sale'))
);

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT sale_order_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_order_tenant 
    ON public.sale_order(tenant_id);

COMMENT ON COLUMN public.sale_order.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_order IS 'Sales Order';
COMMENT ON COLUMN public.sale_order.campaign_id IS 'Campaign';
COMMENT ON COLUMN public.sale_order.source_id IS 'Source';
COMMENT ON COLUMN public.sale_order.medium_id IS 'Medium';
COMMENT ON COLUMN public.sale_order.company_id IS 'Company';
COMMENT ON COLUMN public.sale_order.partner_id IS 'Customer';
COMMENT ON COLUMN public.sale_order.pending_email_template_id IS 'Pending Email Template';
COMMENT ON COLUMN public.sale_order.journal_id IS 'Invoicing Journal';
COMMENT ON COLUMN public.sale_order.partner_invoice_id IS 'Invoice Address';
COMMENT ON COLUMN public.sale_order.partner_shipping_id IS 'Delivery Address';
COMMENT ON COLUMN public.sale_order.fiscal_position_id IS 'Fiscal Position';
COMMENT ON COLUMN public.sale_order.payment_term_id IS 'Payment Terms';
COMMENT ON COLUMN public.sale_order.preferred_payment_method_line_id IS 'Payment Method';
COMMENT ON COLUMN public.sale_order.pricelist_id IS 'Pricelist';
COMMENT ON COLUMN public.sale_order.currency_id IS 'Currency';
COMMENT ON COLUMN public.sale_order.user_id IS 'Salesperson';
COMMENT ON COLUMN public.sale_order.team_id IS 'Sales Team';
COMMENT ON COLUMN public.sale_order.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_order.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_order.access_token IS 'Security Token';
COMMENT ON COLUMN public.sale_order.name IS 'Order Reference';
COMMENT ON COLUMN public.sale_order.state IS 'Status';
COMMENT ON COLUMN public.sale_order.client_order_ref IS 'Customer Reference';
COMMENT ON COLUMN public.sale_order.origin IS 'Source Document';
COMMENT ON COLUMN public.sale_order.reference IS 'Payment Ref.';
COMMENT ON COLUMN public.sale_order.signed_by IS 'Signed By';
COMMENT ON COLUMN public.sale_order.invoice_status IS 'Invoice Status';
COMMENT ON COLUMN public.sale_order.validity_date IS 'Expiration';
COMMENT ON COLUMN public.sale_order.note IS 'Terms and conditions';
COMMENT ON COLUMN public.sale_order.currency_rate IS 'Currency Rate';
COMMENT ON COLUMN public.sale_order.amount_untaxed IS 'Untaxed Amount';
COMMENT ON COLUMN public.sale_order.amount_tax IS 'Taxes';
COMMENT ON COLUMN public.sale_order.amount_total IS 'Total';
COMMENT ON COLUMN public.sale_order.locked IS 'Locked';
COMMENT ON COLUMN public.sale_order.require_signature IS 'Online signature';
COMMENT ON COLUMN public.sale_order.require_payment IS 'Online payment';
COMMENT ON COLUMN public.sale_order.create_date IS 'Creation Date';
COMMENT ON COLUMN public.sale_order.commitment_date IS 'Delivery Date';
COMMENT ON COLUMN public.sale_order.date_order IS 'Order Date';
COMMENT ON COLUMN public.sale_order.signed_on IS 'Signed On';
COMMENT ON COLUMN public.sale_order.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.sale_order.prepayment_percent IS 'Prepayment percentage';
COMMENT ON COLUMN public.sale_order.customizable_pdf_form_fields IS 'Customizable PDF Form Fields';
COMMENT ON COLUMN public.sale_order.incoterm IS 'Incoterm';
COMMENT ON COLUMN public.sale_order.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.sale_order.incoterm_location IS 'Incoterm Location';
COMMENT ON COLUMN public.sale_order.picking_policy IS 'Shipping Policy';
COMMENT ON COLUMN public.sale_order.delivery_status IS 'Delivery Status';
COMMENT ON COLUMN public.sale_order.effective_date IS 'Effective Date';

-- Business constraint: Non-negative amounts
ALTER TABLE public.sale_order
    ADD CONSTRAINT check_sale_order_positive_amounts 
    CHECK (
        (amount_untaxed IS NULL OR amount_untaxed >= 0) AND
        (amount_total IS NULL OR amount_total >= 0)
    );

-- Business constraint: Valid states
ALTER TABLE public.sale_order
    ADD CONSTRAINT check_sale_order_valid_state 
    CHECK (state IN ('draft', 'sent', 'sale', 'done', 'cancel'));

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_sale_order_state 
    ON public.sale_order(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_sale_order_partner 
    ON public.sale_order(tenant_id, partner_id);

-- Index: Queries by date range
CREATE INDEX IF NOT EXISTS idx_sale_order_date_order 
    ON public.sale_order(tenant_id, date_order DESC);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_sale_order_company 
    ON public.sale_order(tenant_id, company_id);
-- ============================================================
-- Table: sale_order_discount
-- ============================================================

CREATE TABLE public.sale_order_discount (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sale_order_id UUID NOT NULL,
    create_uid integer,
    write_uid integer,
    discount_type character varying,
    discount_amount numeric,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    discount_percentage double precision,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ONLY public.sale_order_discount
    ADD CONSTRAINT sale_order_discount_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_order_discount_tenant 
    ON public.sale_order_discount(tenant_id);

COMMENT ON COLUMN public.sale_order_discount.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_order_discount IS 'Discount Wizard';
COMMENT ON COLUMN public.sale_order_discount.sale_order_id IS 'Sale Order';
COMMENT ON COLUMN public.sale_order_discount.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_order_discount.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_order_discount.discount_type IS 'Discount Type';
COMMENT ON COLUMN public.sale_order_discount.discount_amount IS 'Amount';
COMMENT ON COLUMN public.sale_order_discount.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_order_discount.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.sale_order_discount.discount_percentage IS 'Percentage';

-- Business constraint: Non-negative amounts
ALTER TABLE public.sale_order_discount
    ADD CONSTRAINT check_sale_order_discount_positive_amounts 
    CHECK (
        (discount_amount IS NULL OR discount_amount >= 0) AND
        (discount_percentage IS NULL OR discount_percentage >= 0)
    );
-- ============================================================
-- Table: sale_order_line
-- ============================================================

CREATE TABLE public.sale_order_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    sequence integer,
    company_id integer,
    currency_id integer,
    order_partner_id integer,
    salesman_id integer,
    product_id integer,
    product_uom_id integer,
    linked_line_id integer,
    combo_item_id integer,
    create_uid integer,
    write_uid integer,
    state character varying,
    display_type character varying,
    virtual_id character varying,
    linked_virtual_id character varying,
    qty_delivered_method character varying,
    invoice_status character varying,
    analytic_distribution jsonb,
    extra_tax_data jsonb,
    name text NOT NULL,
    product_uom_qty numeric NOT NULL,
    price_unit numeric NOT NULL,
    discount numeric,
    tax_rate numeric,
    price_subtotal numeric,
    price_total numeric,
    price_reduce_taxexcl numeric,
    price_reduce_taxinc numeric,
    qty_delivered numeric,
    qty_invoiced numeric,
    qty_to_invoice numeric,
    untaxed_amount_invoiced numeric,
    untaxed_amount_to_invoice numeric,
    is_downpayment boolean,
    is_expense boolean,
    collapse_prices boolean,
    collapse_composition boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    technical_price_unit double precision,
    price_tax double precision,
    customer_lead double precision NOT NULL,
    is_optional boolean,
    warehouse_id integer,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
,
    CONSTRAINT sale_order_line_accountable_required_fields CHECK ((display_type IS NOT NULL) OR is_downpayment OR ((product_id IS NOT NULL) AND (product_uom_id IS NOT NULL))),
    CONSTRAINT sale_order_line_non_accountable_null_fields CHECK ((display_type IS NULL) OR ((product_id IS NULL) AND (price_unit = 0) AND (product_uom_qty = 0) AND (product_uom_id IS NULL)))
);

ALTER TABLE ONLY public.sale_order_line
    ADD CONSTRAINT sale_order_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_order_line_tenant 
    ON public.sale_order_line(tenant_id);

COMMENT ON COLUMN public.sale_order_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_order_line IS 'Sales Order Line';
COMMENT ON COLUMN public.sale_order_line.order_id IS 'Order Reference';
COMMENT ON COLUMN public.sale_order_line.sequence IS 'Sequence';
COMMENT ON COLUMN public.sale_order_line.company_id IS 'Company';
COMMENT ON COLUMN public.sale_order_line.currency_id IS 'Currency';
COMMENT ON COLUMN public.sale_order_line.order_partner_id IS 'Customer';
COMMENT ON COLUMN public.sale_order_line.salesman_id IS 'Salesperson';
COMMENT ON COLUMN public.sale_order_line.product_id IS 'Product';
COMMENT ON COLUMN public.sale_order_line.product_uom_id IS 'Unit';
COMMENT ON COLUMN public.sale_order_line.linked_line_id IS 'Linked Order Line';
COMMENT ON COLUMN public.sale_order_line.combo_item_id IS 'Combo Item';
COMMENT ON COLUMN public.sale_order_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_order_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_order_line.state IS 'Order Status';
COMMENT ON COLUMN public.sale_order_line.display_type IS 'Display Type';
COMMENT ON COLUMN public.sale_order_line.virtual_id IS 'Virtual';
COMMENT ON COLUMN public.sale_order_line.linked_virtual_id IS 'Linked Virtual';
COMMENT ON COLUMN public.sale_order_line.qty_delivered_method IS 'Method to update delivered qty';
COMMENT ON COLUMN public.sale_order_line.invoice_status IS 'Invoice Status';
COMMENT ON COLUMN public.sale_order_line.analytic_distribution IS 'Analytic Distribution';
COMMENT ON COLUMN public.sale_order_line.extra_tax_data IS 'Extra Tax Data';
COMMENT ON COLUMN public.sale_order_line.name IS 'Description';
COMMENT ON COLUMN public.sale_order_line.product_uom_qty IS 'Quantity';
COMMENT ON COLUMN public.sale_order_line.price_unit IS 'Unit Price';
COMMENT ON COLUMN public.sale_order_line.discount IS 'Discount (%)';
COMMENT ON COLUMN public.sale_order_line.tax_rate IS 'Tax Rate (%)';
COMMENT ON COLUMN public.sale_order_line.price_subtotal IS 'Subtotal';
COMMENT ON COLUMN public.sale_order_line.price_total IS 'Total';
COMMENT ON COLUMN public.sale_order_line.price_reduce_taxexcl IS 'Price Reduce Tax excl';
COMMENT ON COLUMN public.sale_order_line.price_reduce_taxinc IS 'Price Reduce Tax incl';
COMMENT ON COLUMN public.sale_order_line.qty_delivered IS 'Delivery Quantity';
COMMENT ON COLUMN public.sale_order_line.qty_invoiced IS 'Invoiced Quantity';
COMMENT ON COLUMN public.sale_order_line.qty_to_invoice IS 'Quantity To Invoice';
COMMENT ON COLUMN public.sale_order_line.untaxed_amount_invoiced IS 'Untaxed Invoiced Amount';
COMMENT ON COLUMN public.sale_order_line.untaxed_amount_to_invoice IS 'Untaxed Amount To Invoice';
COMMENT ON COLUMN public.sale_order_line.is_downpayment IS 'Is a down payment';
COMMENT ON COLUMN public.sale_order_line.is_expense IS 'Is expense';
COMMENT ON COLUMN public.sale_order_line.collapse_prices IS 'Collapse Prices';
COMMENT ON COLUMN public.sale_order_line.collapse_composition IS 'Collapse Composition';
COMMENT ON COLUMN public.sale_order_line.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_order_line.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.sale_order_line.technical_price_unit IS 'Technical Price Unit';
COMMENT ON COLUMN public.sale_order_line.price_tax IS 'Total Tax';
COMMENT ON COLUMN public.sale_order_line.customer_lead IS 'Lead Time';
COMMENT ON COLUMN public.sale_order_line.is_optional IS 'Optional Line';
COMMENT ON COLUMN public.sale_order_line.warehouse_id IS 'Warehouse';

-- Business constraint: Non-negative amounts
ALTER TABLE public.sale_order_line
    ADD CONSTRAINT check_sale_order_line_positive_amounts 
    CHECK (
        (price_subtotal IS NULL OR price_subtotal >= 0) AND
        (price_total IS NULL OR price_total >= 0)
    );

-- Business constraint: Valid tax rate (0-100%)
ALTER TABLE public.sale_order_line
    ADD CONSTRAINT check_sale_order_line_valid_tax_rate 
    CHECK (tax_rate IS NULL OR (tax_rate >= 0 AND tax_rate <= 100));

-- Business constraint: Positive quantities
ALTER TABLE public.sale_order_line
    ADD CONSTRAINT check_sale_order_line_positive_qty 
    CHECK (product_uom_qty IS NULL OR product_uom_qty > 0);

-- Business constraint: Valid states
ALTER TABLE public.sale_order_line
    ADD CONSTRAINT check_sale_order_line_valid_state 
    CHECK (state IN ('draft', 'sent', 'sale', 'done', 'cancel'));

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_sale_order_line_state 
    ON public.sale_order_line(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_sale_order_line_partner 
    ON public.sale_order_line(tenant_id, order_partner_id);

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_sale_order_line_product 
    ON public.sale_order_line(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_sale_order_line_company 
    ON public.sale_order_line(tenant_id, company_id);

-- ============================================================
-- Table: sale_order_line_invoice_rel
-- ============================================================

CREATE TABLE public.sale_order_line_invoice_rel (
    invoice_line_id integer NOT NULL,
    order_line_id integer NOT NULL
);

ALTER TABLE ONLY public.sale_order_line_invoice_rel
    ADD CONSTRAINT sale_order_line_invoice_rel_pkey PRIMARY KEY (invoice_line_id, order_line_id);

COMMENT ON TABLE public.sale_order_line_invoice_rel IS 'RELATION BETWEEN account_move_line AND sale_order_line';

-- ============================================================
-- Table: sale_order_line_product_document_rel
-- ============================================================

CREATE TABLE public.sale_order_line_product_document_rel (
    sale_order_line_id integer NOT NULL,
    product_document_id integer NOT NULL
);

ALTER TABLE ONLY public.sale_order_line_product_document_rel
    ADD CONSTRAINT sale_order_line_product_document_rel_pkey PRIMARY KEY (sale_order_line_id, product_document_id);

COMMENT ON TABLE public.sale_order_line_product_document_rel IS 'RELATION BETWEEN sale_order_line AND product_document';

-- ============================================================
-- Table: sale_order_line_stock_route_rel
-- ============================================================

CREATE TABLE public.sale_order_line_stock_route_rel (
    sale_order_line_id integer NOT NULL,
    stock_route_id integer NOT NULL
);

ALTER TABLE ONLY public.sale_order_line_stock_route_rel
    ADD CONSTRAINT sale_order_line_stock_route_rel_pkey PRIMARY KEY (sale_order_line_id, stock_route_id);

COMMENT ON TABLE public.sale_order_line_stock_route_rel IS 'RELATION BETWEEN sale_order_line AND stock_route';

-- ============================================================
-- Table: sale_order_mass_cancel_wizard_rel
-- ============================================================

CREATE TABLE public.sale_order_mass_cancel_wizard_rel (
    sale_mass_cancel_orders_id UUID NOT NULL,
    sale_order_id UUID NOT NULL
);

ALTER TABLE ONLY public.sale_order_mass_cancel_wizard_rel
    ADD CONSTRAINT sale_order_mass_cancel_wizard_rel_pkey PRIMARY KEY (sale_mass_cancel_orders_id, sale_order_id);

COMMENT ON TABLE public.sale_order_mass_cancel_wizard_rel IS 'RELATION BETWEEN sale_mass_cancel_orders AND sale_order';

-- ============================================================
-- Table: sale_order_tag_rel
-- ============================================================

CREATE TABLE public.sale_order_tag_rel (
    order_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE ONLY public.sale_order_tag_rel
    ADD CONSTRAINT sale_order_tag_rel_pkey PRIMARY KEY (order_id, tag_id);

COMMENT ON TABLE public.sale_order_tag_rel IS 'RELATION BETWEEN sale_order AND crm_tag';

-- ============================================================
-- Table: sale_order_template
-- ============================================================

CREATE TABLE public.sale_order_template (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    company_id integer,
    sequence integer,
    mail_template_id integer,
    number_of_days integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    note jsonb,
    journal_id jsonb,
    active boolean,
    require_signature boolean,
    require_payment boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    prepayment_percent double precision,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ONLY public.sale_order_template
    ADD CONSTRAINT sale_order_template_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_order_template_tenant 
    ON public.sale_order_template(tenant_id);

COMMENT ON COLUMN public.sale_order_template.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_order_template IS 'Quotation Template';
COMMENT ON COLUMN public.sale_order_template.company_id IS 'Company';
COMMENT ON COLUMN public.sale_order_template.sequence IS 'Sequence';
COMMENT ON COLUMN public.sale_order_template.mail_template_id IS 'Confirmation Mail';
COMMENT ON COLUMN public.sale_order_template.number_of_days IS 'Quotation Duration';
COMMENT ON COLUMN public.sale_order_template.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_order_template.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_order_template.name IS 'Quotation Template';
COMMENT ON COLUMN public.sale_order_template.note IS 'Terms and conditions';
COMMENT ON COLUMN public.sale_order_template.journal_id IS 'Invoicing Journal';
COMMENT ON COLUMN public.sale_order_template.active IS 'Active';
COMMENT ON COLUMN public.sale_order_template.require_signature IS 'Online Signature';
COMMENT ON COLUMN public.sale_order_template.require_payment IS 'Online Payment';
COMMENT ON COLUMN public.sale_order_template.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_order_template.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.sale_order_template.prepayment_percent IS 'Prepayment percentage';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_sale_order_template_company 
    ON public.sale_order_template(tenant_id, company_id);
-- ============================================================
-- Table: sale_order_template_line
-- ============================================================

CREATE TABLE public.sale_order_template_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sale_order_template_id UUID NOT NULL,
    sequence integer,
    company_id integer,
    product_id integer,
    product_uom_id integer,
    create_uid integer,
    write_uid integer,
    display_type character varying,
    name jsonb,
    product_uom_qty numeric NOT NULL,
    is_optional boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
,
    CONSTRAINT sale_order_template_line_accountable_product_id_required CHECK ((display_type IS NOT NULL) OR ((product_id IS NOT NULL) AND (product_uom_id IS NOT NULL))),
    CONSTRAINT sale_order_template_line_non_accountable_fields_null CHECK ((display_type IS NULL) OR ((product_id IS NULL) AND (product_uom_qty = 0) AND (product_uom_id IS NULL)))
);

ALTER TABLE ONLY public.sale_order_template_line
    ADD CONSTRAINT sale_order_template_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_order_template_line_tenant 
    ON public.sale_order_template_line(tenant_id);

COMMENT ON COLUMN public.sale_order_template_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_order_template_line IS 'Quotation Template Line';
COMMENT ON COLUMN public.sale_order_template_line.sale_order_template_id IS 'Quotation Template Reference';
COMMENT ON COLUMN public.sale_order_template_line.sequence IS 'Sequence';
COMMENT ON COLUMN public.sale_order_template_line.company_id IS 'Company';
COMMENT ON COLUMN public.sale_order_template_line.product_id IS 'Product';
COMMENT ON COLUMN public.sale_order_template_line.product_uom_id IS 'Unit';
COMMENT ON COLUMN public.sale_order_template_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_order_template_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_order_template_line.display_type IS 'Display Type';
COMMENT ON COLUMN public.sale_order_template_line.name IS 'Description';
COMMENT ON COLUMN public.sale_order_template_line.product_uom_qty IS 'Quantity';
COMMENT ON COLUMN public.sale_order_template_line.is_optional IS 'Optional Line';
COMMENT ON COLUMN public.sale_order_template_line.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_order_template_line.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_sale_order_template_line_product 
    ON public.sale_order_template_line(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_sale_order_template_line_company 
    ON public.sale_order_template_line(tenant_id, company_id);

-- ============================================================
-- Table: sale_order_transaction_rel
-- ============================================================

CREATE TABLE public.sale_order_transaction_rel (
    transaction_id UUID NOT NULL,
    sale_order_id UUID NOT NULL
);

ALTER TABLE ONLY public.sale_order_transaction_rel
    ADD CONSTRAINT sale_order_transaction_rel_pkey PRIMARY KEY (transaction_id, sale_order_id);

COMMENT ON TABLE public.sale_order_transaction_rel IS 'RELATION BETWEEN payment_transaction AND sale_order';

-- ============================================================
-- Table: sale_pdf_form_field
-- ============================================================

CREATE TABLE public.sale_pdf_form_field (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    document_type character varying NOT NULL,
    path character varying,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    created_by UUID,
    assignee_id UUID,
    shared_with UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ONLY public.sale_pdf_form_field
    ADD CONSTRAINT sale_pdf_form_field_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_sale_pdf_form_field_tenant 
    ON public.sale_pdf_form_field(tenant_id);

COMMENT ON COLUMN public.sale_pdf_form_field.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.sale_pdf_form_field IS 'Form fields of inside quotation documents.';
COMMENT ON COLUMN public.sale_pdf_form_field.create_uid IS 'Created by';
COMMENT ON COLUMN public.sale_pdf_form_field.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.sale_pdf_form_field.name IS 'Form Field Name';
COMMENT ON COLUMN public.sale_pdf_form_field.document_type IS 'Document Type';
COMMENT ON COLUMN public.sale_pdf_form_field.path IS 'Path';
COMMENT ON COLUMN public.sale_pdf_form_field.create_date IS 'Created on';
COMMENT ON COLUMN public.sale_pdf_form_field.write_date IS 'Last Updated on';

-- ============================================================
-- Triggers for updated_at
-- ============================================================

-- Touch-up triggers for updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_order_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_order_updated_at BEFORE UPDATE ON sale_order
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_order_line_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_order_line_updated_at BEFORE UPDATE ON sale_order_line
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_order_discount_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_order_discount_updated_at BEFORE UPDATE ON sale_order_discount
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_order_template_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_order_template_updated_at BEFORE UPDATE ON sale_order_template
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_order_template_line_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_order_template_line_updated_at BEFORE UPDATE ON sale_order_template_line
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_advance_payment_inv_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_advance_payment_inv_updated_at BEFORE UPDATE ON sale_advance_payment_inv
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_mass_cancel_orders_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_mass_cancel_orders_updated_at BEFORE UPDATE ON sale_mass_cancel_orders
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_sale_pdf_form_field_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_sale_pdf_form_field_updated_at BEFORE UPDATE ON sale_pdf_form_field
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

-- ============================================================
