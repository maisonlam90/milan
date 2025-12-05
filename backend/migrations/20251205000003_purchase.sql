-- ============================================================
-- PURCHASE MODULE — Multi-tenant YugabyteDB Schema
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
-- Table: purchase_order
-- ============================================================

CREATE TABLE public.purchase_order (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    partner_id integer NOT NULL,
    dest_address_id integer,
    currency_id integer NOT NULL,
    invoice_count integer,
    fiscal_position_id integer,
    payment_term_id integer,
    incoterm_id integer,
    user_id integer,
    company_id integer NOT NULL,
    reminder_date_before_receipt integer,
    create_uid integer,
    write_uid integer,
    access_token character varying,
    name character varying NOT NULL,
    priority character varying,
    origin character varying,
    partner_ref character varying,
    state character varying,
    invoice_status character varying,
    note text,
    amount_untaxed numeric,
    amount_tax numeric,
    amount_total numeric,
    amount_total_cc numeric,
    currency_rate numeric,
    locked boolean,
    acknowledged boolean,
    receipt_reminder_email boolean,
    date_order timestamp without time zone NOT NULL,
    date_approve timestamp without time zone,
    date_planned timestamp without time zone,
    date_calendar_start timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    picking_type_id integer NOT NULL,
    incoterm_location character varying,
    receipt_status character varying,
    effective_date timestamp without time zone
);

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_purchase_order_tenant 
    ON public.purchase_order(tenant_id);

COMMENT ON COLUMN public.purchase_order.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.purchase_order IS 'Purchase Order';
COMMENT ON COLUMN public.purchase_order.partner_id IS 'Vendor';
COMMENT ON COLUMN public.purchase_order.dest_address_id IS 'Dropship Address';
COMMENT ON COLUMN public.purchase_order.currency_id IS 'Currency';
COMMENT ON COLUMN public.purchase_order.invoice_count IS 'Bill Count';
COMMENT ON COLUMN public.purchase_order.fiscal_position_id IS 'Fiscal Position';
COMMENT ON COLUMN public.purchase_order.payment_term_id IS 'Payment Terms';
COMMENT ON COLUMN public.purchase_order.incoterm_id IS 'Incoterm';
COMMENT ON COLUMN public.purchase_order.user_id IS 'Buyer';
COMMENT ON COLUMN public.purchase_order.company_id IS 'Company';
COMMENT ON COLUMN public.purchase_order.reminder_date_before_receipt IS 'Days Before Receipt';
COMMENT ON COLUMN public.purchase_order.create_uid IS 'Created by';
COMMENT ON COLUMN public.purchase_order.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.purchase_order.access_token IS 'Security Token';
COMMENT ON COLUMN public.purchase_order.name IS 'Order Reference';
COMMENT ON COLUMN public.purchase_order.priority IS 'Priority';
COMMENT ON COLUMN public.purchase_order.origin IS 'Source';
COMMENT ON COLUMN public.purchase_order.partner_ref IS 'Vendor Reference';
COMMENT ON COLUMN public.purchase_order.state IS 'Status';
COMMENT ON COLUMN public.purchase_order.invoice_status IS 'Billing Status';
COMMENT ON COLUMN public.purchase_order.note IS 'Terms and Conditions';
COMMENT ON COLUMN public.purchase_order.amount_untaxed IS 'Untaxed Amount';
COMMENT ON COLUMN public.purchase_order.amount_tax IS 'Taxes';
COMMENT ON COLUMN public.purchase_order.amount_total IS 'Total';
COMMENT ON COLUMN public.purchase_order.amount_total_cc IS 'Total in currency';
COMMENT ON COLUMN public.purchase_order.currency_rate IS 'Currency Rate';
COMMENT ON COLUMN public.purchase_order.locked IS 'Locked';
COMMENT ON COLUMN public.purchase_order.acknowledged IS 'Acknowledged';
COMMENT ON COLUMN public.purchase_order.receipt_reminder_email IS 'Receipt Reminder Email';
COMMENT ON COLUMN public.purchase_order.date_order IS 'Order Deadline';
COMMENT ON COLUMN public.purchase_order.date_approve IS 'Confirmation Date';
COMMENT ON COLUMN public.purchase_order.date_planned IS 'Expected Arrival';
COMMENT ON COLUMN public.purchase_order.date_calendar_start IS 'Date Calendar Start';
COMMENT ON COLUMN public.purchase_order.create_date IS 'Created on';
COMMENT ON COLUMN public.purchase_order.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.purchase_order.picking_type_id IS 'Deliver To';
COMMENT ON COLUMN public.purchase_order.incoterm_location IS 'Incoterm Location';
COMMENT ON COLUMN public.purchase_order.receipt_status IS 'Receipt Status';
COMMENT ON COLUMN public.purchase_order.effective_date IS 'Arrival';

-- Business constraint: Valid states
ALTER TABLE public.purchase_order
    ADD CONSTRAINT check_purchase_order_valid_state 
    CHECK (state IN ('draft', 'sent', 'to approve', 'purchase', 'done', 'cancel'));

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_purchase_order_state 
    ON public.purchase_order(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_purchase_order_partner 
    ON public.purchase_order(tenant_id, partner_id);

-- Index: Queries by date range
CREATE INDEX IF NOT EXISTS idx_purchase_order_date_order 
    ON public.purchase_order(tenant_id, date_order DESC);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_purchase_order_company 
    ON public.purchase_order(tenant_id, company_id);
-- ============================================================
-- Table: purchase_order_line
-- ============================================================

CREATE TABLE public.purchase_order_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    product_uom_id integer,
    product_id integer,
    order_id integer NOT NULL,
    company_id integer,
    partner_id integer,
    create_uid integer,
    write_uid integer,
    qty_received_method character varying,
    display_type character varying,
    analytic_distribution jsonb,
    name text NOT NULL,
    product_qty numeric NOT NULL,
    discount numeric,
    price_unit numeric NOT NULL,
    price_subtotal numeric,
    price_total numeric,
    qty_invoiced numeric,
    qty_received numeric,
    qty_received_manual numeric,
    qty_to_invoice numeric,
    is_downpayment boolean,
    date_planned timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    product_uom_qty double precision,
    price_tax double precision,
    technical_price_unit double precision,
    sale_line_id integer,
    orderpoint_id integer,
    location_final_id integer,
    product_description_variants character varying,
    propagate_cancel boolean
,
    CONSTRAINT purchase_order_line_accountable_required_fields CHECK ((display_type IS NOT NULL) OR is_downpayment OR ((product_id IS NOT NULL) AND (product_uom_id IS NOT NULL) AND (date_planned IS NOT NULL))),
    CONSTRAINT purchase_order_line_non_accountable_null_fields CHECK ((display_type IS NULL) OR ((product_id IS NULL) AND (price_unit = 0) AND (product_uom_qty = 0) AND (product_uom_id IS NULL) AND (date_planned IS NULL)))
);

ALTER TABLE ONLY public.purchase_order_line
    ADD CONSTRAINT purchase_order_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_purchase_order_line_tenant 
    ON public.purchase_order_line(tenant_id);

COMMENT ON COLUMN public.purchase_order_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.purchase_order_line IS 'Purchase Order Line';
COMMENT ON COLUMN public.purchase_order_line.sequence IS 'Sequence';
COMMENT ON COLUMN public.purchase_order_line.product_uom_id IS 'Unit';
COMMENT ON COLUMN public.purchase_order_line.product_id IS 'Product';
COMMENT ON COLUMN public.purchase_order_line.order_id IS 'Order Reference';
COMMENT ON COLUMN public.purchase_order_line.company_id IS 'Company';
COMMENT ON COLUMN public.purchase_order_line.partner_id IS 'Partner';
COMMENT ON COLUMN public.purchase_order_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.purchase_order_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.purchase_order_line.qty_received_method IS 'Received Qty Method';
COMMENT ON COLUMN public.purchase_order_line.display_type IS 'Display Type';
COMMENT ON COLUMN public.purchase_order_line.analytic_distribution IS 'Analytic Distribution';
COMMENT ON COLUMN public.purchase_order_line.name IS 'Description';
COMMENT ON COLUMN public.purchase_order_line.product_qty IS 'Quantity';
COMMENT ON COLUMN public.purchase_order_line.discount IS 'Discount (%)';
COMMENT ON COLUMN public.purchase_order_line.price_unit IS 'Unit Price';
COMMENT ON COLUMN public.purchase_order_line.price_subtotal IS 'Subtotal';
COMMENT ON COLUMN public.purchase_order_line.price_total IS 'Total';
COMMENT ON COLUMN public.purchase_order_line.qty_invoiced IS 'Billed Qty';
COMMENT ON COLUMN public.purchase_order_line.qty_received IS 'Received Qty';
COMMENT ON COLUMN public.purchase_order_line.qty_received_manual IS 'Manual Received Qty';
COMMENT ON COLUMN public.purchase_order_line.qty_to_invoice IS 'To Invoice Quantity';
COMMENT ON COLUMN public.purchase_order_line.is_downpayment IS 'Is Downpayment';
COMMENT ON COLUMN public.purchase_order_line.date_planned IS 'Expected Arrival';
COMMENT ON COLUMN public.purchase_order_line.create_date IS 'Created on';
COMMENT ON COLUMN public.purchase_order_line.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.purchase_order_line.product_uom_qty IS 'Total Quantity';
COMMENT ON COLUMN public.purchase_order_line.price_tax IS 'Tax';
COMMENT ON COLUMN public.purchase_order_line.technical_price_unit IS 'Technical Price Unit';
COMMENT ON COLUMN public.purchase_order_line.sale_line_id IS 'Origin Sale Item';
COMMENT ON COLUMN public.purchase_order_line.orderpoint_id IS 'Orderpoint';
COMMENT ON COLUMN public.purchase_order_line.location_final_id IS 'Location from procurement';
COMMENT ON COLUMN public.purchase_order_line.product_description_variants IS 'Custom Description';
COMMENT ON COLUMN public.purchase_order_line.propagate_cancel IS 'Propagate cancellation';

-- Business constraint: Positive quantities
ALTER TABLE public.purchase_order_line
    ADD CONSTRAINT check_purchase_order_line_positive_qty 
    CHECK (product_uom_qty IS NULL OR product_uom_qty > 0);

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_purchase_order_line_partner 
    ON public.purchase_order_line(tenant_id, partner_id);

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_purchase_order_line_product 
    ON public.purchase_order_line(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_purchase_order_line_company 
    ON public.purchase_order_line(tenant_id, company_id);

-- ============================================================
-- Table: purchase_order_stock_picking_rel
-- ============================================================

CREATE TABLE public.purchase_order_stock_picking_rel (
    purchase_order_id integer NOT NULL,
    stock_picking_id integer NOT NULL
);

ALTER TABLE ONLY public.purchase_order_stock_picking_rel
    ADD CONSTRAINT purchase_order_stock_picking_rel_pkey PRIMARY KEY (purchase_order_id, stock_picking_id);

COMMENT ON TABLE public.purchase_order_stock_picking_rel IS 'RELATION BETWEEN purchase_order AND stock_picking';

-- ============================================================
