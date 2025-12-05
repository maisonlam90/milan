-- ============================================================
-- STOCK MODULE — Multi-tenant YugabyteDB Schema
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
-- Table: stock_location
-- ============================================================

CREATE TABLE public.stock_location (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    location_id integer,
    company_id integer,
    removal_strategy_id integer,
    cyclic_inventory_frequency integer,
    warehouse_id integer,
    storage_category_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    complete_name character varying,
    usage character varying NOT NULL,
    parent_path character varying,
    barcode character varying,
    last_inventory_date date,
    next_inventory_date date,
    active boolean,
    replenish_location boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    valuation_account_id integer
,
    CONSTRAINT stock_location_inventory_freq_nonneg CHECK (cyclic_inventory_frequency >= 0)
);

ALTER TABLE ONLY public.stock_location
    ADD CONSTRAINT stock_location_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_location_tenant 
    ON public.stock_location(tenant_id);

COMMENT ON COLUMN public.stock_location.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_location IS 'Inventory Locations';
COMMENT ON COLUMN public.stock_location.location_id IS 'Parent Location';
COMMENT ON COLUMN public.stock_location.company_id IS 'Company';
COMMENT ON COLUMN public.stock_location.removal_strategy_id IS 'Removal Strategy';
COMMENT ON COLUMN public.stock_location.cyclic_inventory_frequency IS 'Inventory Frequency';
COMMENT ON COLUMN public.stock_location.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.stock_location.storage_category_id IS 'Storage Category';
COMMENT ON COLUMN public.stock_location.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_location.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_location.name IS 'Location Name';
COMMENT ON COLUMN public.stock_location.complete_name IS 'Full Location Name';
COMMENT ON COLUMN public.stock_location.usage IS 'Location Type';
COMMENT ON COLUMN public.stock_location.parent_path IS 'Parent Path';
COMMENT ON COLUMN public.stock_location.barcode IS 'Barcode';
COMMENT ON COLUMN public.stock_location.last_inventory_date IS 'Last Inventory';
COMMENT ON COLUMN public.stock_location.next_inventory_date IS 'Next Expected';
COMMENT ON COLUMN public.stock_location.active IS 'Active';
COMMENT ON COLUMN public.stock_location.replenish_location IS 'Replenishments';
COMMENT ON COLUMN public.stock_location.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_location.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_location.valuation_account_id IS 'Stock Valuation Account';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_location_company 
    ON public.stock_location(tenant_id, company_id);

-- ============================================================
-- Table: stock_move
-- ============================================================

CREATE TABLE public.stock_move (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    company_id integer NOT NULL,
    product_id integer NOT NULL,
    product_uom integer NOT NULL,
    location_id integer NOT NULL,
    location_dest_id integer NOT NULL,
    location_final_id integer,
    partner_id integer,
    picking_id integer,
    scrap_id integer,
    rule_id integer,
    picking_type_id integer,
    origin_returned_move_id integer,
    restrict_partner_id integer,
    warehouse_id integer,
    next_serial_count integer,
    orderpoint_id integer,
    packaging_uom_id integer,
    create_uid integer,
    write_uid integer,
    priority character varying,
    state character varying,
    origin character varying,
    procure_method character varying NOT NULL,
    inventory_name character varying,
    reference character varying,
    next_serial character varying,
    reservation_date date,
    description_picking_manual text,
    product_qty numeric,
    product_uom_qty numeric NOT NULL,
    quantity numeric,
    picked boolean,
    propagate_cancel boolean,
    is_inventory boolean,
    additional boolean,
    date timestamp without time zone NOT NULL,
    date_deadline timestamp without time zone,
    delay_alert_date timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    price_unit double precision,
    packaging_uom_qty double precision,
    account_move_id integer,
    value numeric,
    to_refund boolean,
    is_in boolean,
    is_out boolean,
    is_dropship boolean,
    purchase_line_id integer,
    sale_line_id integer
);

ALTER TABLE ONLY public.stock_move
    ADD CONSTRAINT stock_move_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_move_tenant 
    ON public.stock_move(tenant_id);

COMMENT ON COLUMN public.stock_move.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_move IS 'Stock Move';
COMMENT ON COLUMN public.stock_move.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_move.company_id IS 'Company';
COMMENT ON COLUMN public.stock_move.product_id IS 'Product';
COMMENT ON COLUMN public.stock_move.product_uom IS 'Unit';
COMMENT ON COLUMN public.stock_move.location_id IS 'Source Location';
COMMENT ON COLUMN public.stock_move.location_dest_id IS 'Intermediate Location';
COMMENT ON COLUMN public.stock_move.location_final_id IS 'Final Location';
COMMENT ON COLUMN public.stock_move.partner_id IS 'Destination Address ';
COMMENT ON COLUMN public.stock_move.picking_id IS 'Transfer';
COMMENT ON COLUMN public.stock_move.scrap_id IS 'Scrap operation';
COMMENT ON COLUMN public.stock_move.rule_id IS 'Stock Rule';
COMMENT ON COLUMN public.stock_move.picking_type_id IS 'Operation Type';
COMMENT ON COLUMN public.stock_move.origin_returned_move_id IS 'Origin return move';
COMMENT ON COLUMN public.stock_move.restrict_partner_id IS 'Owner ';
COMMENT ON COLUMN public.stock_move.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.stock_move.next_serial_count IS 'Number of SN/Lots';
COMMENT ON COLUMN public.stock_move.orderpoint_id IS 'Original Reordering Rule';
COMMENT ON COLUMN public.stock_move.packaging_uom_id IS 'Packaging';
COMMENT ON COLUMN public.stock_move.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_move.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_move.priority IS 'Priority';
COMMENT ON COLUMN public.stock_move.state IS 'Status';
COMMENT ON COLUMN public.stock_move.origin IS 'Source Document';
COMMENT ON COLUMN public.stock_move.procure_method IS 'Supply Method';
COMMENT ON COLUMN public.stock_move.inventory_name IS 'Inventory Name';
COMMENT ON COLUMN public.stock_move.reference IS 'Reference';
COMMENT ON COLUMN public.stock_move.next_serial IS 'First SN/Lot';
COMMENT ON COLUMN public.stock_move.reservation_date IS 'Date to Reserve';
COMMENT ON COLUMN public.stock_move.description_picking_manual IS 'Description Picking Manual';
COMMENT ON COLUMN public.stock_move.product_qty IS 'Real Quantity';
COMMENT ON COLUMN public.stock_move.product_uom_qty IS 'Demand';
COMMENT ON COLUMN public.stock_move.quantity IS 'Quantity';
COMMENT ON COLUMN public.stock_move.picked IS 'Picked';
COMMENT ON COLUMN public.stock_move.propagate_cancel IS 'Propagate cancel and split';
COMMENT ON COLUMN public.stock_move.is_inventory IS 'Inventory';
COMMENT ON COLUMN public.stock_move.additional IS 'Whether the move was added after the picking''s confirmation';
COMMENT ON COLUMN public.stock_move.date IS 'Date Scheduled';
COMMENT ON COLUMN public.stock_move.date_deadline IS 'Deadline';
COMMENT ON COLUMN public.stock_move.delay_alert_date IS 'Delay Alert Date';
COMMENT ON COLUMN public.stock_move.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_move.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_move.price_unit IS 'Unit Price';
COMMENT ON COLUMN public.stock_move.packaging_uom_qty IS 'Packaging Quantity';
COMMENT ON COLUMN public.stock_move.account_move_id IS 'stock_move_id';
COMMENT ON COLUMN public.stock_move.value IS 'Value';
COMMENT ON COLUMN public.stock_move.to_refund IS 'Update quantities on SO/PO';
COMMENT ON COLUMN public.stock_move.is_in IS 'Is Incoming (valued)';
COMMENT ON COLUMN public.stock_move.is_out IS 'Is Outgoing (valued)';
COMMENT ON COLUMN public.stock_move.is_dropship IS 'Is Dropship';
COMMENT ON COLUMN public.stock_move.purchase_line_id IS 'Purchase Order Line';
COMMENT ON COLUMN public.stock_move.sale_line_id IS 'Sale Line';

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_stock_move_state 
    ON public.stock_move(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_stock_move_partner 
    ON public.stock_move(tenant_id, partner_id);

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_move_product 
    ON public.stock_move(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_move_company 
    ON public.stock_move(tenant_id, company_id);

-- ============================================================
-- Table: stock_quant
-- ============================================================

CREATE TABLE public.stock_quant (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer NOT NULL,
    company_id integer,
    location_id integer NOT NULL,
    lot_id integer,
    package_id integer,
    owner_id integer,
    user_id integer,
    create_uid integer,
    write_uid integer,
    inventory_date date,
    quantity numeric,
    reserved_quantity numeric NOT NULL,
    inventory_quantity numeric,
    inventory_diff_quantity numeric,
    inventory_quantity_set boolean,
    in_date timestamp without time zone NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    accounting_date date
);

ALTER TABLE ONLY public.stock_quant
    ADD CONSTRAINT stock_quant_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_quant_tenant 
    ON public.stock_quant(tenant_id);

COMMENT ON COLUMN public.stock_quant.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_quant IS 'Quants';
COMMENT ON COLUMN public.stock_quant.product_id IS 'Product';
COMMENT ON COLUMN public.stock_quant.company_id IS 'Company';
COMMENT ON COLUMN public.stock_quant.location_id IS 'Location';
COMMENT ON COLUMN public.stock_quant.lot_id IS 'Lot/Serial Number';
COMMENT ON COLUMN public.stock_quant.package_id IS 'Package';
COMMENT ON COLUMN public.stock_quant.owner_id IS 'Owner';
COMMENT ON COLUMN public.stock_quant.user_id IS 'Assigned To';
COMMENT ON COLUMN public.stock_quant.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_quant.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_quant.inventory_date IS 'Scheduled';
COMMENT ON COLUMN public.stock_quant.quantity IS 'Quantity';
COMMENT ON COLUMN public.stock_quant.reserved_quantity IS 'Reserved Quantity';
COMMENT ON COLUMN public.stock_quant.inventory_quantity IS 'Counted';
COMMENT ON COLUMN public.stock_quant.inventory_diff_quantity IS 'Difference';
COMMENT ON COLUMN public.stock_quant.inventory_quantity_set IS 'Inventory Quantity Set';
COMMENT ON COLUMN public.stock_quant.in_date IS 'Incoming Date';
COMMENT ON COLUMN public.stock_quant.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_quant.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_quant.accounting_date IS 'Accounting Date';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_quant_product 
    ON public.stock_quant(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_quant_company 
    ON public.stock_quant(tenant_id, company_id);

-- ============================================================
-- Table: stock_warehouse
-- ============================================================

CREATE TABLE public.stock_warehouse (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    company_id integer NOT NULL,
    partner_id integer,
    view_location_id integer NOT NULL,
    lot_stock_id integer NOT NULL,
    wh_input_stock_loc_id integer,
    wh_qc_stock_loc_id integer,
    wh_output_stock_loc_id integer,
    wh_pack_stock_loc_id integer,
    mto_pull_id integer,
    pick_type_id integer,
    pack_type_id integer,
    out_type_id integer,
    in_type_id integer,
    int_type_id integer,
    qc_type_id integer,
    store_type_id integer,
    xdock_type_id integer,
    reception_route_id integer,
    delivery_route_id integer,
    sequence integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    code character varying(5) NOT NULL,
    reception_steps character varying NOT NULL,
    delivery_steps character varying NOT NULL,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    buy_pull_id integer
);

ALTER TABLE ONLY public.stock_warehouse
    ADD CONSTRAINT stock_warehouse_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_warehouse_tenant 
    ON public.stock_warehouse(tenant_id);

COMMENT ON COLUMN public.stock_warehouse.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_warehouse IS 'Warehouse';
COMMENT ON COLUMN public.stock_warehouse.company_id IS 'Company';
COMMENT ON COLUMN public.stock_warehouse.partner_id IS 'Address';
COMMENT ON COLUMN public.stock_warehouse.view_location_id IS 'View Location';
COMMENT ON COLUMN public.stock_warehouse.lot_stock_id IS 'Location Stock';
COMMENT ON COLUMN public.stock_warehouse.wh_input_stock_loc_id IS 'Input Location';
COMMENT ON COLUMN public.stock_warehouse.wh_qc_stock_loc_id IS 'Quality Control Location';
COMMENT ON COLUMN public.stock_warehouse.wh_output_stock_loc_id IS 'Output Location';
COMMENT ON COLUMN public.stock_warehouse.wh_pack_stock_loc_id IS 'Packing Location';
COMMENT ON COLUMN public.stock_warehouse.mto_pull_id IS 'MTO rule';
COMMENT ON COLUMN public.stock_warehouse.pick_type_id IS 'Pick Type';
COMMENT ON COLUMN public.stock_warehouse.pack_type_id IS 'Pack Type';
COMMENT ON COLUMN public.stock_warehouse.out_type_id IS 'Out Type';
COMMENT ON COLUMN public.stock_warehouse.in_type_id IS 'In Type';
COMMENT ON COLUMN public.stock_warehouse.int_type_id IS 'Internal Type';
COMMENT ON COLUMN public.stock_warehouse.qc_type_id IS 'Quality Control Type';
COMMENT ON COLUMN public.stock_warehouse.store_type_id IS 'Storage Type';
COMMENT ON COLUMN public.stock_warehouse.xdock_type_id IS 'Cross Dock Type';
COMMENT ON COLUMN public.stock_warehouse.reception_route_id IS 'Receipt Route';
COMMENT ON COLUMN public.stock_warehouse.delivery_route_id IS 'Delivery Route';
COMMENT ON COLUMN public.stock_warehouse.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_warehouse.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_warehouse.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_warehouse.name IS 'Warehouse';
COMMENT ON COLUMN public.stock_warehouse.code IS 'Short Name';
COMMENT ON COLUMN public.stock_warehouse.reception_steps IS 'Incoming Shipments';
COMMENT ON COLUMN public.stock_warehouse.delivery_steps IS 'Outgoing Shipments';
COMMENT ON COLUMN public.stock_warehouse.active IS 'Active';
COMMENT ON COLUMN public.stock_warehouse.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_warehouse.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_warehouse.buy_pull_id IS 'Buy rule';

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_stock_warehouse_partner 
    ON public.stock_warehouse(tenant_id, partner_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_warehouse_company 
    ON public.stock_warehouse(tenant_id, company_id);

-- ============================================================
-- Table: stock_picking
-- ============================================================

CREATE TABLE public.stock_picking (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    backorder_id integer,
    return_id integer,
    location_id integer NOT NULL,
    location_dest_id integer NOT NULL,
    picking_type_id integer NOT NULL,
    partner_id integer,
    company_id integer,
    user_id integer,
    owner_id integer,
    create_uid integer,
    write_uid integer,
    name character varying,
    origin character varying,
    move_type character varying NOT NULL,
    state character varying,
    priority character varying,
    picking_properties jsonb,
    note text,
    shipping_weight numeric,
    has_deadline_issue boolean,
    printed boolean,
    is_locked boolean,
    scheduled_date timestamp without time zone,
    date_deadline timestamp without time zone,
    date_done timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    sale_id integer
);

ALTER TABLE ONLY public.stock_picking
    ADD CONSTRAINT stock_picking_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_picking_tenant 
    ON public.stock_picking(tenant_id);

COMMENT ON COLUMN public.stock_picking.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_picking IS 'Transfer';
COMMENT ON COLUMN public.stock_picking.backorder_id IS 'Back Order of';
COMMENT ON COLUMN public.stock_picking.return_id IS 'Return of';
COMMENT ON COLUMN public.stock_picking.location_id IS 'Source Location';
COMMENT ON COLUMN public.stock_picking.location_dest_id IS 'Destination Location';
COMMENT ON COLUMN public.stock_picking.picking_type_id IS 'Operation Type';
COMMENT ON COLUMN public.stock_picking.partner_id IS 'Contact';
COMMENT ON COLUMN public.stock_picking.company_id IS 'Company';
COMMENT ON COLUMN public.stock_picking.user_id IS 'Responsible';
COMMENT ON COLUMN public.stock_picking.owner_id IS 'Assign Owner';
COMMENT ON COLUMN public.stock_picking.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_picking.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_picking.name IS 'Reference';
COMMENT ON COLUMN public.stock_picking.origin IS 'Source Document';
COMMENT ON COLUMN public.stock_picking.move_type IS 'Shipping Policy';
COMMENT ON COLUMN public.stock_picking.state IS 'Status';
COMMENT ON COLUMN public.stock_picking.priority IS 'Priority';
COMMENT ON COLUMN public.stock_picking.picking_properties IS 'Properties';
COMMENT ON COLUMN public.stock_picking.note IS 'Notes';
COMMENT ON COLUMN public.stock_picking.shipping_weight IS 'Weight for Shipping';
COMMENT ON COLUMN public.stock_picking.has_deadline_issue IS 'Is late';
COMMENT ON COLUMN public.stock_picking.printed IS 'Printed';
COMMENT ON COLUMN public.stock_picking.is_locked IS 'Is Locked';
COMMENT ON COLUMN public.stock_picking.scheduled_date IS 'Scheduled Date';
COMMENT ON COLUMN public.stock_picking.date_deadline IS 'Deadline';
COMMENT ON COLUMN public.stock_picking.date_done IS 'Date of Transfer';
COMMENT ON COLUMN public.stock_picking.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_picking.write_date IS 'Last Updated on';

-- Business constraint: Valid states
ALTER TABLE public.stock_picking
    ADD CONSTRAINT check_stock_picking_valid_state 
    CHECK (state IN ('draft', 'waiting', 'confirmed', 'assigned', 'done', 'cancel'));

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_stock_picking_state 
    ON public.stock_picking(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by partner
CREATE INDEX IF NOT EXISTS idx_stock_picking_partner 
    ON public.stock_picking(tenant_id, partner_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_picking_company 
    ON public.stock_picking(tenant_id, company_id);

-- ============================================================
-- Table: stock_backorder_confirmation
-- ============================================================

CREATE TABLE public.stock_backorder_confirmation (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    show_transfers boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_backorder_confirmation
    ADD CONSTRAINT stock_backorder_confirmation_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_backorder_confirmation_tenant 
    ON public.stock_backorder_confirmation(tenant_id);

COMMENT ON COLUMN public.stock_backorder_confirmation.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_backorder_confirmation IS 'Backorder Confirmation';
COMMENT ON COLUMN public.stock_backorder_confirmation.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_backorder_confirmation.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_backorder_confirmation.show_transfers IS 'Show Transfers';
COMMENT ON COLUMN public.stock_backorder_confirmation.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_backorder_confirmation.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_backorder_confirmation_line
-- ============================================================

CREATE TABLE public.stock_backorder_confirmation_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    backorder_confirmation_id integer,
    picking_id integer,
    create_uid integer,
    write_uid integer,
    to_backorder boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_backorder_confirmation_line
    ADD CONSTRAINT stock_backorder_confirmation_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_backorder_confirmation_line_tenant 
    ON public.stock_backorder_confirmation_line(tenant_id);

COMMENT ON COLUMN public.stock_backorder_confirmation_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_backorder_confirmation_line IS 'Backorder Confirmation Line';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.backorder_confirmation_id IS 'Immediate Transfer';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.picking_id IS 'Transfer';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.to_backorder IS 'To Backorder';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_backorder_confirmation_line.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_conflict_quant_rel
-- ============================================================

CREATE TABLE public.stock_conflict_quant_rel (
    stock_inventory_conflict_id integer NOT NULL,
    stock_quant_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_conflict_quant_rel
    ADD CONSTRAINT stock_conflict_quant_rel_pkey PRIMARY KEY (stock_inventory_conflict_id, stock_quant_id);

COMMENT ON TABLE public.stock_conflict_quant_rel IS 'RELATION BETWEEN stock_inventory_conflict AND stock_quant';

-- ============================================================
-- Table: stock_inventory_adjustment_name
-- ============================================================

CREATE TABLE public.stock_inventory_adjustment_name (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    inventory_adjustment_name character varying,
    counting_date timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    accounting_date date
);

ALTER TABLE ONLY public.stock_inventory_adjustment_name
    ADD CONSTRAINT stock_inventory_adjustment_name_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_inventory_adjustment_name_tenant 
    ON public.stock_inventory_adjustment_name(tenant_id);

COMMENT ON COLUMN public.stock_inventory_adjustment_name.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_inventory_adjustment_name IS 'Inventory Adjustment Reference / Reason';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.inventory_adjustment_name IS 'Inventory Reason';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.counting_date IS 'Counting Date';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_inventory_adjustment_name.accounting_date IS 'Accounting Date';

-- ============================================================
-- Table: stock_inventory_adjustment_name_stock_quant_rel
-- ============================================================

CREATE TABLE public.stock_inventory_adjustment_name_stock_quant_rel (
    stock_inventory_adjustment_name_id integer NOT NULL,
    stock_quant_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_inventory_adjustment_name_stock_quant_rel
    ADD CONSTRAINT stock_inventory_adjustment_name_stock_quant_rel_pkey PRIMARY KEY (stock_inventory_adjustment_name_id, stock_quant_id);

COMMENT ON TABLE public.stock_inventory_adjustment_name_stock_quant_rel IS 'RELATION BETWEEN stock_inventory_adjustment_name AND stock_quant';

-- ============================================================
-- Table: stock_inventory_conflict
-- ============================================================

CREATE TABLE public.stock_inventory_conflict (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_inventory_conflict
    ADD CONSTRAINT stock_inventory_conflict_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_inventory_conflict_tenant 
    ON public.stock_inventory_conflict(tenant_id);

COMMENT ON COLUMN public.stock_inventory_conflict.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_inventory_conflict IS 'Conflict in Inventory';
COMMENT ON COLUMN public.stock_inventory_conflict.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_inventory_conflict.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_inventory_conflict.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_inventory_conflict.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_inventory_conflict_stock_quant_rel
-- ============================================================

CREATE TABLE public.stock_inventory_conflict_stock_quant_rel (
    stock_inventory_conflict_id integer NOT NULL,
    stock_quant_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_inventory_conflict_stock_quant_rel
    ADD CONSTRAINT stock_inventory_conflict_stock_quant_rel_pkey PRIMARY KEY (stock_inventory_conflict_id, stock_quant_id);

COMMENT ON TABLE public.stock_inventory_conflict_stock_quant_rel IS 'RELATION BETWEEN stock_inventory_conflict AND stock_quant';

-- ============================================================
-- Table: stock_inventory_warning
-- ============================================================

CREATE TABLE public.stock_inventory_warning (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_inventory_warning
    ADD CONSTRAINT stock_inventory_warning_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_inventory_warning_tenant 
    ON public.stock_inventory_warning(tenant_id);

COMMENT ON COLUMN public.stock_inventory_warning.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_inventory_warning IS 'Inventory Adjustment Warning';
COMMENT ON COLUMN public.stock_inventory_warning.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_inventory_warning.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_inventory_warning.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_inventory_warning.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_inventory_warning_stock_quant_rel
-- ============================================================

CREATE TABLE public.stock_inventory_warning_stock_quant_rel (
    stock_inventory_warning_id integer NOT NULL,
    stock_quant_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_inventory_warning_stock_quant_rel
    ADD CONSTRAINT stock_inventory_warning_stock_quant_rel_pkey PRIMARY KEY (stock_inventory_warning_id, stock_quant_id);

COMMENT ON TABLE public.stock_inventory_warning_stock_quant_rel IS 'RELATION BETWEEN stock_inventory_warning AND stock_quant';

-- ============================================================
-- Table: stock_lot
-- ============================================================

CREATE TABLE public.stock_lot (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer NOT NULL,
    company_id integer,
    location_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    ref character varying,
    lot_properties jsonb,
    note text,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    standard_price jsonb,
    avg_cost numeric
);

ALTER TABLE ONLY public.stock_lot
    ADD CONSTRAINT stock_lot_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_lot_tenant 
    ON public.stock_lot(tenant_id);

COMMENT ON COLUMN public.stock_lot.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_lot IS 'Lot/Serial';
COMMENT ON COLUMN public.stock_lot.product_id IS 'Product';
COMMENT ON COLUMN public.stock_lot.company_id IS 'Company';
COMMENT ON COLUMN public.stock_lot.location_id IS 'Location';
COMMENT ON COLUMN public.stock_lot.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_lot.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_lot.name IS 'Lot/Serial Number';
COMMENT ON COLUMN public.stock_lot.ref IS 'Internal Reference';
COMMENT ON COLUMN public.stock_lot.lot_properties IS 'Properties';
COMMENT ON COLUMN public.stock_lot.note IS 'Description';
COMMENT ON COLUMN public.stock_lot.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_lot.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_lot.standard_price IS 'Cost';
COMMENT ON COLUMN public.stock_lot.avg_cost IS 'Average Cost';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_lot_product 
    ON public.stock_lot(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_lot_company 
    ON public.stock_lot(tenant_id, company_id);

-- ============================================================
-- Table: stock_move_created_purchase_line_rel
-- ============================================================

CREATE TABLE public.stock_move_created_purchase_line_rel (
    created_purchase_line_id integer NOT NULL,
    move_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_move_created_purchase_line_rel
    ADD CONSTRAINT stock_move_created_purchase_line_rel_pkey PRIMARY KEY (created_purchase_line_id, move_id);

COMMENT ON TABLE public.stock_move_created_purchase_line_rel IS 'RELATION BETWEEN purchase_order_line AND stock_move';

-- ============================================================
-- Table: stock_move_line
-- ============================================================

CREATE TABLE public.stock_move_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    picking_id integer,
    move_id integer,
    company_id integer NOT NULL,
    product_id integer,
    product_uom_id integer NOT NULL,
    package_id integer,
    lot_id integer,
    result_package_id integer,
    package_history_id integer,
    owner_id integer,
    location_id integer NOT NULL,
    location_dest_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    lot_name character varying,
    state character varying,
    quantity numeric,
    quantity_product_uom numeric,
    picked boolean,
    is_entire_pack boolean,
    date timestamp without time zone NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_move_line
    ADD CONSTRAINT stock_move_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_move_line_tenant 
    ON public.stock_move_line(tenant_id);

COMMENT ON COLUMN public.stock_move_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_move_line IS 'Product Moves (Stock Move Line)';
COMMENT ON COLUMN public.stock_move_line.picking_id IS 'Transfer';
COMMENT ON COLUMN public.stock_move_line.move_id IS 'Stock Operation';
COMMENT ON COLUMN public.stock_move_line.company_id IS 'Company';
COMMENT ON COLUMN public.stock_move_line.product_id IS 'Product';
COMMENT ON COLUMN public.stock_move_line.product_uom_id IS 'Unit';
COMMENT ON COLUMN public.stock_move_line.package_id IS 'Source Package';
COMMENT ON COLUMN public.stock_move_line.lot_id IS 'Lot/Serial Number';
COMMENT ON COLUMN public.stock_move_line.result_package_id IS 'Destination Package';
COMMENT ON COLUMN public.stock_move_line.package_history_id IS 'Package History';
COMMENT ON COLUMN public.stock_move_line.owner_id IS 'From Owner';
COMMENT ON COLUMN public.stock_move_line.location_id IS 'From';
COMMENT ON COLUMN public.stock_move_line.location_dest_id IS 'To';
COMMENT ON COLUMN public.stock_move_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_move_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_move_line.lot_name IS 'Lot/Serial Number Name';
COMMENT ON COLUMN public.stock_move_line.state IS 'Status';
COMMENT ON COLUMN public.stock_move_line.quantity IS 'Quantity';
COMMENT ON COLUMN public.stock_move_line.quantity_product_uom IS 'Quantity in Product UoM';
COMMENT ON COLUMN public.stock_move_line.picked IS 'Picked';
COMMENT ON COLUMN public.stock_move_line.is_entire_pack IS 'Is added through entire package';
COMMENT ON COLUMN public.stock_move_line.date IS 'Date';
COMMENT ON COLUMN public.stock_move_line.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_move_line.write_date IS 'Last Updated on';

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_stock_move_line_state 
    ON public.stock_move_line(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_move_line_product 
    ON public.stock_move_line(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_move_line_company 
    ON public.stock_move_line(tenant_id, company_id);

-- ============================================================
-- Table: stock_move_line_consume_rel
-- ============================================================

CREATE TABLE public.stock_move_line_consume_rel (
    consume_line_id integer NOT NULL,
    produce_line_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_move_line_consume_rel
    ADD CONSTRAINT stock_move_line_consume_rel_pkey PRIMARY KEY (consume_line_id, produce_line_id);

COMMENT ON TABLE public.stock_move_line_consume_rel IS 'RELATION BETWEEN stock_move_line AND stock_move_line';

-- ============================================================
-- Table: stock_move_line_stock_put_in_pack_rel
-- ============================================================

CREATE TABLE public.stock_move_line_stock_put_in_pack_rel (
    stock_put_in_pack_id integer NOT NULL,
    stock_move_line_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_move_line_stock_put_in_pack_rel
    ADD CONSTRAINT stock_move_line_stock_put_in_pack_rel_pkey PRIMARY KEY (stock_put_in_pack_id, stock_move_line_id);

COMMENT ON TABLE public.stock_move_line_stock_put_in_pack_rel IS 'RELATION BETWEEN stock_put_in_pack AND stock_move_line';

-- ============================================================
-- Table: stock_move_move_rel
-- ============================================================

CREATE TABLE public.stock_move_move_rel (
    move_orig_id integer NOT NULL,
    move_dest_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_move_move_rel
    ADD CONSTRAINT stock_move_move_rel_pkey PRIMARY KEY (move_orig_id, move_dest_id);

COMMENT ON TABLE public.stock_move_move_rel IS 'RELATION BETWEEN stock_move AND stock_move';

-- ============================================================
-- Table: stock_orderpoint_snooze
-- ============================================================

CREATE TABLE public.stock_orderpoint_snooze (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    predefined_date character varying,
    snoozed_until date,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_orderpoint_snooze
    ADD CONSTRAINT stock_orderpoint_snooze_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_orderpoint_snooze_tenant 
    ON public.stock_orderpoint_snooze(tenant_id);

COMMENT ON COLUMN public.stock_orderpoint_snooze.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_orderpoint_snooze IS 'Snooze Orderpoint';
COMMENT ON COLUMN public.stock_orderpoint_snooze.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_orderpoint_snooze.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_orderpoint_snooze.predefined_date IS 'Snooze for';
COMMENT ON COLUMN public.stock_orderpoint_snooze.snoozed_until IS 'Snooze Date';
COMMENT ON COLUMN public.stock_orderpoint_snooze.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_orderpoint_snooze.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_orderpoint_snooze_stock_warehouse_orderpoint_rel
-- ============================================================

CREATE TABLE public.stock_orderpoint_snooze_stock_warehouse_orderpoint_rel (
    stock_orderpoint_snooze_id integer NOT NULL,
    stock_warehouse_orderpoint_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_orderpoint_snooze_stock_warehouse_orderpoint_rel
    ADD CONSTRAINT stock_orderpoint_snooze_stock_warehouse_orderpoint_rel_pkey PRIMARY KEY (stock_orderpoint_snooze_id, stock_warehouse_orderpoint_id);

COMMENT ON TABLE public.stock_orderpoint_snooze_stock_warehouse_orderpoint_rel IS 'RELATION BETWEEN stock_orderpoint_snooze AND stock_warehouse_orderpoint';

-- ============================================================
-- Table: stock_package
-- ============================================================

CREATE TABLE public.stock_package (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    package_type_id integer,
    location_id integer,
    company_id integer,
    parent_package_id integer,
    package_dest_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    complete_name character varying,
    parent_path character varying,
    pack_date date,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    shipping_weight double precision
);

ALTER TABLE ONLY public.stock_package
    ADD CONSTRAINT stock_package_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_package_tenant 
    ON public.stock_package(tenant_id);

COMMENT ON COLUMN public.stock_package.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_package IS 'Package';
COMMENT ON COLUMN public.stock_package.package_type_id IS 'Package Type';
COMMENT ON COLUMN public.stock_package.location_id IS 'Location';
COMMENT ON COLUMN public.stock_package.company_id IS 'Company';
COMMENT ON COLUMN public.stock_package.parent_package_id IS 'Container';
COMMENT ON COLUMN public.stock_package.package_dest_id IS 'Destination Container';
COMMENT ON COLUMN public.stock_package.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_package.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_package.name IS 'Package Reference';
COMMENT ON COLUMN public.stock_package.complete_name IS 'Full Package Name';
COMMENT ON COLUMN public.stock_package.parent_path IS 'Parent Path';
COMMENT ON COLUMN public.stock_package.pack_date IS 'Pack Date';
COMMENT ON COLUMN public.stock_package.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_package.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_package.shipping_weight IS 'Shipping Weight';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_package_company 
    ON public.stock_package(tenant_id, company_id);

-- ============================================================
-- Table: stock_package_destination
-- ============================================================

CREATE TABLE public.stock_package_destination (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    location_dest_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_package_destination
    ADD CONSTRAINT stock_package_destination_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_package_destination_tenant 
    ON public.stock_package_destination(tenant_id);

COMMENT ON COLUMN public.stock_package_destination.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_package_destination IS 'Stock Package Destination';
COMMENT ON COLUMN public.stock_package_destination.location_dest_id IS 'Destination location';
COMMENT ON COLUMN public.stock_package_destination.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_package_destination.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_package_destination.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_package_destination.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_package_history
-- ============================================================

CREATE TABLE public.stock_package_history (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    company_id integer NOT NULL,
    location_id integer,
    location_dest_id integer,
    package_id integer NOT NULL,
    parent_orig_id integer,
    parent_dest_id integer,
    outermost_dest_id integer,
    create_uid integer,
    write_uid integer,
    package_name character varying NOT NULL,
    parent_orig_name character varying,
    parent_dest_name character varying,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_package_history
    ADD CONSTRAINT stock_package_history_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_package_history_tenant 
    ON public.stock_package_history(tenant_id);

COMMENT ON COLUMN public.stock_package_history.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_package_history IS 'Stock Package History';
COMMENT ON COLUMN public.stock_package_history.company_id IS 'Company';
COMMENT ON COLUMN public.stock_package_history.location_id IS 'Origin Location';
COMMENT ON COLUMN public.stock_package_history.location_dest_id IS 'Destination Location';
COMMENT ON COLUMN public.stock_package_history.package_id IS 'Package';
COMMENT ON COLUMN public.stock_package_history.parent_orig_id IS 'Origin Container';
COMMENT ON COLUMN public.stock_package_history.parent_dest_id IS 'Destination Container';
COMMENT ON COLUMN public.stock_package_history.outermost_dest_id IS 'Outermost Destination Container';
COMMENT ON COLUMN public.stock_package_history.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_package_history.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_package_history.package_name IS 'Package Name';
COMMENT ON COLUMN public.stock_package_history.parent_orig_name IS 'Origin Container Name';
COMMENT ON COLUMN public.stock_package_history.parent_dest_name IS 'Destination Container Name';
COMMENT ON COLUMN public.stock_package_history.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_package_history.write_date IS 'Last Updated on';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_package_history_company 
    ON public.stock_package_history(tenant_id, company_id);

-- ============================================================
-- Table: stock_package_history_stock_picking_rel
-- ============================================================

CREATE TABLE public.stock_package_history_stock_picking_rel (
    stock_picking_id integer NOT NULL,
    stock_package_history_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_package_history_stock_picking_rel
    ADD CONSTRAINT stock_package_history_stock_picking_rel_pkey PRIMARY KEY (stock_picking_id, stock_package_history_id);

COMMENT ON TABLE public.stock_package_history_stock_picking_rel IS 'RELATION BETWEEN stock_picking AND stock_package_history';

-- ============================================================
-- Table: stock_package_stock_put_in_pack_rel
-- ============================================================

CREATE TABLE public.stock_package_stock_put_in_pack_rel (
    stock_put_in_pack_id integer NOT NULL,
    stock_package_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_package_stock_put_in_pack_rel
    ADD CONSTRAINT stock_package_stock_put_in_pack_rel_pkey PRIMARY KEY (stock_put_in_pack_id, stock_package_id);

COMMENT ON TABLE public.stock_package_stock_put_in_pack_rel IS 'RELATION BETWEEN stock_put_in_pack AND stock_package';

-- ============================================================
-- Table: stock_package_type
-- ============================================================

CREATE TABLE public.stock_package_type (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    sequence_id integer,
    company_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    barcode character varying,
    package_use character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    height double precision,
    width double precision,
    packaging_length double precision,
    base_weight double precision,
    max_weight double precision
,
    CONSTRAINT stock_package_type_positive_height CHECK (height >= 0.0),
    CONSTRAINT stock_package_type_positive_length CHECK (packaging_length >= 0.0),
    CONSTRAINT stock_package_type_positive_max_weight CHECK (max_weight >= 0.0),
    CONSTRAINT stock_package_type_positive_width CHECK (width >= 0.0)
);

ALTER TABLE ONLY public.stock_package_type
    ADD CONSTRAINT stock_package_type_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_package_type_tenant 
    ON public.stock_package_type(tenant_id);

COMMENT ON COLUMN public.stock_package_type.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_package_type IS 'Stock package type';
COMMENT ON COLUMN public.stock_package_type.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_package_type.sequence_id IS 'Reference Sequence';
COMMENT ON COLUMN public.stock_package_type.company_id IS 'Company';
COMMENT ON COLUMN public.stock_package_type.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_package_type.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_package_type.name IS 'Package Type';
COMMENT ON COLUMN public.stock_package_type.barcode IS 'Barcode';
COMMENT ON COLUMN public.stock_package_type.package_use IS 'Package Use';
COMMENT ON COLUMN public.stock_package_type.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_package_type.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_package_type.height IS 'Height';
COMMENT ON COLUMN public.stock_package_type.width IS 'Width';
COMMENT ON COLUMN public.stock_package_type.packaging_length IS 'Length';
COMMENT ON COLUMN public.stock_package_type.base_weight IS 'Weight';
COMMENT ON COLUMN public.stock_package_type.max_weight IS 'Max Weight';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_package_type_company 
    ON public.stock_package_type(tenant_id, company_id);
-- ============================================================
-- Table: stock_package_type_stock_putaway_rule_rel
-- ============================================================

CREATE TABLE public.stock_package_type_stock_putaway_rule_rel (
    stock_putaway_rule_id integer NOT NULL,
    stock_package_type_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_package_type_stock_putaway_rule_rel
    ADD CONSTRAINT stock_package_type_stock_putaway_rule_rel_pkey PRIMARY KEY (stock_putaway_rule_id, stock_package_type_id);

COMMENT ON TABLE public.stock_package_type_stock_putaway_rule_rel IS 'RELATION BETWEEN stock_putaway_rule AND stock_package_type';

-- ============================================================
-- Table: stock_package_type_stock_route_rel
-- ============================================================

CREATE TABLE public.stock_package_type_stock_route_rel (
    stock_package_type_id integer NOT NULL,
    stock_route_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_package_type_stock_route_rel
    ADD CONSTRAINT stock_package_type_stock_route_rel_pkey PRIMARY KEY (stock_package_type_id, stock_route_id);

COMMENT ON TABLE public.stock_package_type_stock_route_rel IS 'RELATION BETWEEN stock_package_type AND stock_route';

-- ============================================================
-- Table: stock_picking_backorder_rel
-- ============================================================

CREATE TABLE public.stock_picking_backorder_rel (
    stock_backorder_confirmation_id integer NOT NULL,
    stock_picking_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_picking_backorder_rel
    ADD CONSTRAINT stock_picking_backorder_rel_pkey PRIMARY KEY (stock_backorder_confirmation_id, stock_picking_id);

COMMENT ON TABLE public.stock_picking_backorder_rel IS 'RELATION BETWEEN stock_backorder_confirmation AND stock_picking';

-- ============================================================
-- Table: stock_picking_sms_rel
-- ============================================================

CREATE TABLE public.stock_picking_sms_rel (
    confirm_stock_sms_id integer NOT NULL,
    stock_picking_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_picking_sms_rel
    ADD CONSTRAINT stock_picking_sms_rel_pkey PRIMARY KEY (confirm_stock_sms_id, stock_picking_id);

COMMENT ON TABLE public.stock_picking_sms_rel IS 'RELATION BETWEEN confirm_stock_sms AND stock_picking';

-- ============================================================
-- Table: stock_picking_type
-- ============================================================

CREATE TABLE public.stock_picking_type (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    color integer,
    sequence integer,
    sequence_id integer,
    default_location_src_id integer NOT NULL,
    default_location_dest_id integer NOT NULL,
    return_picking_type_id integer,
    warehouse_id integer,
    reservation_days_before integer,
    reservation_days_before_priority integer,
    company_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    sequence_code character varying NOT NULL,
    code character varying NOT NULL,
    reservation_method character varying NOT NULL,
    product_label_format character varying,
    lot_label_format character varying,
    package_label_to_print character varying,
    barcode character varying,
    create_backorder character varying NOT NULL,
    move_type character varying NOT NULL,
    name jsonb NOT NULL,
    picking_properties_definition jsonb,
    show_entire_packs boolean,
    set_package_type boolean,
    active boolean,
    use_create_lots boolean,
    use_existing_lots boolean,
    print_label boolean,
    show_operations boolean,
    auto_show_reception_report boolean,
    auto_print_delivery_slip boolean,
    auto_print_return_slip boolean,
    auto_print_product_labels boolean,
    auto_print_lot_labels boolean,
    auto_print_reception_report boolean,
    auto_print_reception_report_labels boolean,
    auto_print_packages boolean,
    auto_print_package_label boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_picking_type
    ADD CONSTRAINT stock_picking_type_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_picking_type_tenant 
    ON public.stock_picking_type(tenant_id);

COMMENT ON COLUMN public.stock_picking_type.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_picking_type IS 'Picking Type';
COMMENT ON COLUMN public.stock_picking_type.color IS 'Color';
COMMENT ON COLUMN public.stock_picking_type.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_picking_type.sequence_id IS 'Reference Sequence';
COMMENT ON COLUMN public.stock_picking_type.default_location_src_id IS 'Source Location';
COMMENT ON COLUMN public.stock_picking_type.default_location_dest_id IS 'Destination Location';
COMMENT ON COLUMN public.stock_picking_type.return_picking_type_id IS 'Operation Type for Returns';
COMMENT ON COLUMN public.stock_picking_type.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.stock_picking_type.reservation_days_before IS 'Days';
COMMENT ON COLUMN public.stock_picking_type.reservation_days_before_priority IS 'Days when starred';
COMMENT ON COLUMN public.stock_picking_type.company_id IS 'Company';
COMMENT ON COLUMN public.stock_picking_type.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_picking_type.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_picking_type.sequence_code IS 'Sequence Prefix';
COMMENT ON COLUMN public.stock_picking_type.code IS 'Type of Operation';
COMMENT ON COLUMN public.stock_picking_type.reservation_method IS 'Reservation Method';
COMMENT ON COLUMN public.stock_picking_type.product_label_format IS 'Product Label Format to auto-print';
COMMENT ON COLUMN public.stock_picking_type.lot_label_format IS 'Lot Label Format to auto-print';
COMMENT ON COLUMN public.stock_picking_type.package_label_to_print IS 'Package Label to Print';
COMMENT ON COLUMN public.stock_picking_type.barcode IS 'Barcode';
COMMENT ON COLUMN public.stock_picking_type.create_backorder IS 'Create Backorder';
COMMENT ON COLUMN public.stock_picking_type.move_type IS 'Shipping Policy';
COMMENT ON COLUMN public.stock_picking_type.name IS 'Operation Type';
COMMENT ON COLUMN public.stock_picking_type.picking_properties_definition IS 'Picking Properties';
COMMENT ON COLUMN public.stock_picking_type.show_entire_packs IS 'Move Entire Packages';
COMMENT ON COLUMN public.stock_picking_type.set_package_type IS 'Set Package Type';
COMMENT ON COLUMN public.stock_picking_type.active IS 'Active';
COMMENT ON COLUMN public.stock_picking_type.use_create_lots IS 'Create New Lots/Serial Numbers';
COMMENT ON COLUMN public.stock_picking_type.use_existing_lots IS 'Use Existing Lots/Serial Numbers';
COMMENT ON COLUMN public.stock_picking_type.print_label IS 'Generate Shipping Labels';
COMMENT ON COLUMN public.stock_picking_type.show_operations IS 'Show Detailed Operations';
COMMENT ON COLUMN public.stock_picking_type.auto_show_reception_report IS 'Show Reception Report at Validation';
COMMENT ON COLUMN public.stock_picking_type.auto_print_delivery_slip IS 'Auto Print Delivery Slip';
COMMENT ON COLUMN public.stock_picking_type.auto_print_return_slip IS 'Auto Print Return Slip';
COMMENT ON COLUMN public.stock_picking_type.auto_print_product_labels IS 'Auto Print Product Labels';
COMMENT ON COLUMN public.stock_picking_type.auto_print_lot_labels IS 'Auto Print Lot/SN Labels';
COMMENT ON COLUMN public.stock_picking_type.auto_print_reception_report IS 'Auto Print Reception Report';
COMMENT ON COLUMN public.stock_picking_type.auto_print_reception_report_labels IS 'Auto Print Reception Report Labels';
COMMENT ON COLUMN public.stock_picking_type.auto_print_packages IS 'Auto Print Packages';
COMMENT ON COLUMN public.stock_picking_type.auto_print_package_label IS 'Auto Print Package Label';
COMMENT ON COLUMN public.stock_picking_type.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_picking_type.write_date IS 'Last Updated on';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_picking_type_company 
    ON public.stock_picking_type(tenant_id, company_id);
-- ============================================================
-- Table: stock_put_in_pack
-- ============================================================

CREATE TABLE public.stock_put_in_pack (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    location_dest_id integer,
    package_type_id integer,
    result_package_id integer,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_put_in_pack
    ADD CONSTRAINT stock_put_in_pack_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_put_in_pack_tenant 
    ON public.stock_put_in_pack(tenant_id);

COMMENT ON COLUMN public.stock_put_in_pack.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_put_in_pack IS 'Put In Pack Wizard';
COMMENT ON COLUMN public.stock_put_in_pack.location_dest_id IS 'Destination';
COMMENT ON COLUMN public.stock_put_in_pack.package_type_id IS 'Package Type';
COMMENT ON COLUMN public.stock_put_in_pack.result_package_id IS 'Package';
COMMENT ON COLUMN public.stock_put_in_pack.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_put_in_pack.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_put_in_pack.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_put_in_pack.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_putaway_rule
-- ============================================================

CREATE TABLE public.stock_putaway_rule (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer,
    category_id integer,
    location_in_id integer NOT NULL,
    location_out_id integer NOT NULL,
    sequence integer,
    company_id integer NOT NULL,
    storage_category_id integer,
    create_uid integer,
    write_uid integer,
    sublocation character varying,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_putaway_rule
    ADD CONSTRAINT stock_putaway_rule_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_putaway_rule_tenant 
    ON public.stock_putaway_rule(tenant_id);

COMMENT ON COLUMN public.stock_putaway_rule.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_putaway_rule IS 'Putaway Rule';
COMMENT ON COLUMN public.stock_putaway_rule.product_id IS 'Product';
COMMENT ON COLUMN public.stock_putaway_rule.category_id IS 'Product Category';
COMMENT ON COLUMN public.stock_putaway_rule.location_in_id IS 'When product arrives in';
COMMENT ON COLUMN public.stock_putaway_rule.location_out_id IS 'Store to sublocation';
COMMENT ON COLUMN public.stock_putaway_rule.sequence IS 'Priority';
COMMENT ON COLUMN public.stock_putaway_rule.company_id IS 'Company';
COMMENT ON COLUMN public.stock_putaway_rule.storage_category_id IS 'Storage Category';
COMMENT ON COLUMN public.stock_putaway_rule.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_putaway_rule.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_putaway_rule.sublocation IS 'Sublocation';
COMMENT ON COLUMN public.stock_putaway_rule.active IS 'Active';
COMMENT ON COLUMN public.stock_putaway_rule.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_putaway_rule.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_putaway_rule_product 
    ON public.stock_putaway_rule(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_putaway_rule_company 
    ON public.stock_putaway_rule(tenant_id, company_id);

-- ============================================================
-- Table: stock_quant_relocate
-- ============================================================

CREATE TABLE public.stock_quant_relocate (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    dest_location_id integer,
    dest_package_id integer,
    create_uid integer,
    write_uid integer,
    message text,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_quant_relocate
    ADD CONSTRAINT stock_quant_relocate_pkey PRIMARY KEY (id);

COMMENT ON TABLE public.stock_quant_relocate IS 'Stock Quantity Relocation';
COMMENT ON COLUMN public.stock_quant_relocate.dest_location_id IS 'Dest Location';
COMMENT ON COLUMN public.stock_quant_relocate.dest_package_id IS 'Dest Package';
COMMENT ON COLUMN public.stock_quant_relocate.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_quant_relocate.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_quant_relocate.message IS 'Reason for relocation';
COMMENT ON COLUMN public.stock_quant_relocate.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_quant_relocate.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_quant_stock_quant_relocate_rel
-- ============================================================

CREATE TABLE public.stock_quant_stock_quant_relocate_rel (
    stock_quant_relocate_id integer NOT NULL,
    stock_quant_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_quant_stock_quant_relocate_rel
    ADD CONSTRAINT stock_quant_stock_quant_relocate_rel_pkey PRIMARY KEY (stock_quant_relocate_id, stock_quant_id);

COMMENT ON TABLE public.stock_quant_stock_quant_relocate_rel IS 'RELATION BETWEEN stock_quant_relocate AND stock_quant';

-- ============================================================
-- Table: stock_quant_stock_request_count_rel
-- ============================================================

CREATE TABLE public.stock_quant_stock_request_count_rel (
    stock_request_count_id integer NOT NULL,
    stock_quant_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_quant_stock_request_count_rel
    ADD CONSTRAINT stock_quant_stock_request_count_rel_pkey PRIMARY KEY (stock_request_count_id, stock_quant_id);

COMMENT ON TABLE public.stock_quant_stock_request_count_rel IS 'RELATION BETWEEN stock_request_count AND stock_quant';

-- ============================================================
-- Table: stock_quantity_history
-- ============================================================

CREATE TABLE public.stock_quantity_history (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    inventory_datetime timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_quantity_history
    ADD CONSTRAINT stock_quantity_history_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_quantity_history_tenant 
    ON public.stock_quantity_history(tenant_id);

COMMENT ON COLUMN public.stock_quantity_history.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_quantity_history IS 'Stock Quantity History';
COMMENT ON COLUMN public.stock_quantity_history.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_quantity_history.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_quantity_history.inventory_datetime IS 'Inventory at Date';
COMMENT ON COLUMN public.stock_quantity_history.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_quantity_history.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_reference
-- ============================================================

CREATE TABLE public.stock_reference (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_reference
    ADD CONSTRAINT stock_reference_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_reference_tenant 
    ON public.stock_reference(tenant_id);

COMMENT ON COLUMN public.stock_reference.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_reference IS 'Reference between stock documents';
COMMENT ON COLUMN public.stock_reference.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_reference.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_reference.name IS 'Reference';
COMMENT ON COLUMN public.stock_reference.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_reference.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_reference_move_rel
-- ============================================================

CREATE TABLE public.stock_reference_move_rel (
    move_id integer NOT NULL,
    reference_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_reference_move_rel
    ADD CONSTRAINT stock_reference_move_rel_pkey PRIMARY KEY (move_id, reference_id);

COMMENT ON TABLE public.stock_reference_move_rel IS 'RELATION BETWEEN stock_move AND stock_reference';

-- ============================================================
-- Table: stock_reference_purchase_rel
-- ============================================================

CREATE TABLE public.stock_reference_purchase_rel (
    purchase_id integer NOT NULL,
    reference_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_reference_purchase_rel
    ADD CONSTRAINT stock_reference_purchase_rel_pkey PRIMARY KEY (purchase_id, reference_id);

COMMENT ON TABLE public.stock_reference_purchase_rel IS 'RELATION BETWEEN purchase_order AND stock_reference';

-- ============================================================
-- Table: stock_reference_sale_rel
-- ============================================================

CREATE TABLE public.stock_reference_sale_rel (
    sale_id integer NOT NULL,
    reference_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_reference_sale_rel
    ADD CONSTRAINT stock_reference_sale_rel_pkey PRIMARY KEY (sale_id, reference_id);

COMMENT ON TABLE public.stock_reference_sale_rel IS 'RELATION BETWEEN sale_order AND stock_reference';

-- ============================================================
-- Table: stock_replenishment_info
-- ============================================================

CREATE TABLE public.stock_replenishment_info (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    orderpoint_id integer,
    percent_factor integer NOT NULL,
    create_uid integer,
    write_uid integer,
    based_on character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_replenishment_info
    ADD CONSTRAINT stock_replenishment_info_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_replenishment_info_tenant 
    ON public.stock_replenishment_info(tenant_id);

COMMENT ON COLUMN public.stock_replenishment_info.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_replenishment_info IS 'Stock supplier replenishment information';
COMMENT ON COLUMN public.stock_replenishment_info.orderpoint_id IS 'Orderpoint';
COMMENT ON COLUMN public.stock_replenishment_info.percent_factor IS 'Percent Factor';
COMMENT ON COLUMN public.stock_replenishment_info.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_replenishment_info.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_replenishment_info.based_on IS 'Based on';
COMMENT ON COLUMN public.stock_replenishment_info.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_replenishment_info.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_replenishment_option
-- ============================================================

CREATE TABLE public.stock_replenishment_option (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    route_id integer,
    product_id integer,
    replenishment_info_id integer,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_replenishment_option
    ADD CONSTRAINT stock_replenishment_option_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_replenishment_option_tenant 
    ON public.stock_replenishment_option(tenant_id);

COMMENT ON COLUMN public.stock_replenishment_option.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_replenishment_option IS 'Stock warehouse replenishment option';
COMMENT ON COLUMN public.stock_replenishment_option.route_id IS 'Route';
COMMENT ON COLUMN public.stock_replenishment_option.product_id IS 'Product';
COMMENT ON COLUMN public.stock_replenishment_option.replenishment_info_id IS 'Replenishment Info';
COMMENT ON COLUMN public.stock_replenishment_option.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_replenishment_option.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_replenishment_option.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_replenishment_option.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_replenishment_option_product 
    ON public.stock_replenishment_option(tenant_id, product_id);

-- ============================================================
-- Table: stock_request_count
-- ============================================================

CREATE TABLE public.stock_request_count (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id integer,
    create_uid integer,
    write_uid integer,
    inventory_date date NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_request_count
    ADD CONSTRAINT stock_request_count_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_request_count_tenant 
    ON public.stock_request_count(tenant_id);

COMMENT ON COLUMN public.stock_request_count.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_request_count IS 'Stock Request an Inventory Count';
COMMENT ON COLUMN public.stock_request_count.user_id IS 'Assign to';
COMMENT ON COLUMN public.stock_request_count.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_request_count.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_request_count.inventory_date IS 'Scheduled at';
COMMENT ON COLUMN public.stock_request_count.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_request_count.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_return_picking
-- ============================================================

CREATE TABLE public.stock_return_picking (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    picking_id integer,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_return_picking
    ADD CONSTRAINT stock_return_picking_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_return_picking_tenant 
    ON public.stock_return_picking(tenant_id);

COMMENT ON COLUMN public.stock_return_picking.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_return_picking IS 'Return Picking';
COMMENT ON COLUMN public.stock_return_picking.picking_id IS 'Picking';
COMMENT ON COLUMN public.stock_return_picking.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_return_picking.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_return_picking.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_return_picking.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_return_picking_line
-- ============================================================

CREATE TABLE public.stock_return_picking_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer NOT NULL,
    wizard_id integer,
    move_id integer,
    create_uid integer,
    write_uid integer,
    quantity numeric NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    to_refund boolean
);

ALTER TABLE ONLY public.stock_return_picking_line
    ADD CONSTRAINT stock_return_picking_line_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_return_picking_line_tenant 
    ON public.stock_return_picking_line(tenant_id);

COMMENT ON COLUMN public.stock_return_picking_line.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_return_picking_line IS 'Return Picking Line';
COMMENT ON COLUMN public.stock_return_picking_line.product_id IS 'Product';
COMMENT ON COLUMN public.stock_return_picking_line.wizard_id IS 'Wizard';
COMMENT ON COLUMN public.stock_return_picking_line.move_id IS 'Move';
COMMENT ON COLUMN public.stock_return_picking_line.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_return_picking_line.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_return_picking_line.quantity IS 'Quantity';
COMMENT ON COLUMN public.stock_return_picking_line.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_return_picking_line.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_return_picking_line.to_refund IS 'Update quantities on SO/PO';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_return_picking_line_product 
    ON public.stock_return_picking_line(tenant_id, product_id);

-- ============================================================
-- Table: stock_route
-- ============================================================

CREATE TABLE public.stock_route (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    supplied_wh_id integer,
    supplier_wh_id integer,
    company_id integer,
    create_uid integer,
    write_uid integer,
    name jsonb NOT NULL,
    active boolean,
    product_selectable boolean,
    product_categ_selectable boolean,
    warehouse_selectable boolean,
    package_type_selectable boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    sale_selectable boolean
);

ALTER TABLE ONLY public.stock_route
    ADD CONSTRAINT stock_route_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_route_tenant 
    ON public.stock_route(tenant_id);

COMMENT ON COLUMN public.stock_route.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_route IS 'Inventory Routes';
COMMENT ON COLUMN public.stock_route.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_route.supplied_wh_id IS 'Supplied Warehouse';
COMMENT ON COLUMN public.stock_route.supplier_wh_id IS 'Supplying Warehouse';
COMMENT ON COLUMN public.stock_route.company_id IS 'Company';
COMMENT ON COLUMN public.stock_route.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_route.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_route.name IS 'Route';
COMMENT ON COLUMN public.stock_route.active IS 'Active';
COMMENT ON COLUMN public.stock_route.product_selectable IS 'Applicable on Product';
COMMENT ON COLUMN public.stock_route.product_categ_selectable IS 'Applicable on Product Category';
COMMENT ON COLUMN public.stock_route.warehouse_selectable IS 'Applicable on Warehouse';
COMMENT ON COLUMN public.stock_route.package_type_selectable IS 'Applicable on Package Type';
COMMENT ON COLUMN public.stock_route.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_route.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_route.sale_selectable IS 'Selectable on Sales Order Line';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_route_company 
    ON public.stock_route(tenant_id, company_id);
-- ============================================================
-- Table: stock_route_categ
-- ============================================================

CREATE TABLE public.stock_route_categ (
    tenant_id UUID NOT NULL,
    route_id integer NOT NULL,
    categ_id integer NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_route_categ_tenant 
    ON public.stock_route_categ(tenant_id);

COMMENT ON COLUMN public.stock_route_categ.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_route_categ IS 'RELATION BETWEEN stock_route AND product_category';

-- Index: Queries by category
CREATE INDEX IF NOT EXISTS idx_stock_route_categ_category 
    ON public.stock_route_categ(tenant_id, categ_id);

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stock_route_categ_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stock_route_categ_updated_at
    BEFORE UPDATE ON public.stock_route_categ
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_route_categ_timestamp();

-- ============================================================
-- Table: stock_route_move
-- ============================================================

CREATE TABLE public.stock_route_move (
    tenant_id UUID NOT NULL,
    move_id integer NOT NULL,
    route_id integer NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_route_move_tenant 
    ON public.stock_route_move(tenant_id);

COMMENT ON COLUMN public.stock_route_move.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_route_move IS 'RELATION BETWEEN stock_move AND stock_route';

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stock_route_move_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stock_route_move_updated_at
    BEFORE UPDATE ON public.stock_route_move
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_route_move_timestamp();

-- ============================================================
-- Table: stock_route_product
-- ============================================================

CREATE TABLE public.stock_route_product (
    tenant_id UUID NOT NULL,
    route_id integer NOT NULL,
    product_id integer NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_route_product_tenant 
    ON public.stock_route_product(tenant_id);

COMMENT ON COLUMN public.stock_route_product.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_route_product IS 'RELATION BETWEEN stock_route AND product_template';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_route_product_product 
    ON public.stock_route_product(tenant_id, product_id);

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stock_route_product_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stock_route_product_updated_at
    BEFORE UPDATE ON public.stock_route_product
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_route_product_timestamp();

-- ============================================================
-- Table: stock_route_stock_rules_report_rel
-- ============================================================

CREATE TABLE public.stock_route_stock_rules_report_rel (
    stock_rules_report_id integer NOT NULL,
    stock_route_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_route_stock_rules_report_rel
    ADD CONSTRAINT stock_route_stock_rules_report_rel_pkey PRIMARY KEY (stock_rules_report_id, stock_route_id);

COMMENT ON TABLE public.stock_route_stock_rules_report_rel IS 'RELATION BETWEEN stock_rules_report AND stock_route';

-- ============================================================
-- Table: stock_route_warehouse
-- ============================================================

CREATE TABLE public.stock_route_warehouse (
    tenant_id UUID NOT NULL,
    route_id integer NOT NULL,
    warehouse_id integer NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_route_warehouse_tenant 
    ON public.stock_route_warehouse(tenant_id);

COMMENT ON COLUMN public.stock_route_warehouse.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_route_warehouse IS 'RELATION BETWEEN stock_route AND stock_warehouse';

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stock_route_warehouse_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stock_route_warehouse_updated_at
    BEFORE UPDATE ON public.stock_route_warehouse
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_route_warehouse_timestamp();

-- ============================================================
-- Table: stock_rule
-- ============================================================

CREATE TABLE public.stock_rule (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    company_id integer,
    location_dest_id integer NOT NULL,
    location_src_id integer,
    route_id integer NOT NULL,
    route_sequence integer,
    picking_type_id integer NOT NULL,
    delay integer,
    partner_address_id integer,
    warehouse_id integer,
    create_uid integer,
    write_uid integer,
    action character varying NOT NULL,
    procure_method character varying NOT NULL,
    auto character varying NOT NULL,
    push_domain character varying,
    name jsonb NOT NULL,
    active boolean,
    location_dest_from_rule boolean,
    propagate_cancel boolean,
    propagate_carrier boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_rule
    ADD CONSTRAINT stock_rule_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_rule_tenant 
    ON public.stock_rule(tenant_id);

COMMENT ON COLUMN public.stock_rule.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_rule IS 'Stock Rule';
COMMENT ON COLUMN public.stock_rule.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_rule.company_id IS 'Company';
COMMENT ON COLUMN public.stock_rule.location_dest_id IS 'Destination Location';
COMMENT ON COLUMN public.stock_rule.location_src_id IS 'Source Location';
COMMENT ON COLUMN public.stock_rule.route_id IS 'Route';
COMMENT ON COLUMN public.stock_rule.route_sequence IS 'Route Sequence';
COMMENT ON COLUMN public.stock_rule.picking_type_id IS 'Operation Type';
COMMENT ON COLUMN public.stock_rule.delay IS 'Lead Time';
COMMENT ON COLUMN public.stock_rule.partner_address_id IS 'Partner Address';
COMMENT ON COLUMN public.stock_rule.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.stock_rule.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_rule.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_rule.action IS 'Action';
COMMENT ON COLUMN public.stock_rule.procure_method IS 'Supply Method';
COMMENT ON COLUMN public.stock_rule.auto IS 'Automatic Move';
COMMENT ON COLUMN public.stock_rule.push_domain IS 'Push Applicability';
COMMENT ON COLUMN public.stock_rule.name IS 'Name';
COMMENT ON COLUMN public.stock_rule.active IS 'Active';
COMMENT ON COLUMN public.stock_rule.location_dest_from_rule IS 'Destination location origin from rule';
COMMENT ON COLUMN public.stock_rule.propagate_cancel IS 'Cancel Next Move';
COMMENT ON COLUMN public.stock_rule.propagate_carrier IS 'Propagation of carrier';
COMMENT ON COLUMN public.stock_rule.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_rule.write_date IS 'Last Updated on';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_rule_company 
    ON public.stock_rule(tenant_id, company_id);
-- ============================================================
-- Table: stock_rules_report
-- ============================================================

CREATE TABLE public.stock_rules_report (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer NOT NULL,
    product_tmpl_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    product_has_variants boolean NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_rules_report
    ADD CONSTRAINT stock_rules_report_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_rules_report_tenant 
    ON public.stock_rules_report(tenant_id);

COMMENT ON COLUMN public.stock_rules_report.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_rules_report IS 'Stock Rules report';
COMMENT ON COLUMN public.stock_rules_report.product_id IS 'Product';
COMMENT ON COLUMN public.stock_rules_report.product_tmpl_id IS 'Product Template';
COMMENT ON COLUMN public.stock_rules_report.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_rules_report.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_rules_report.product_has_variants IS 'Has variants';
COMMENT ON COLUMN public.stock_rules_report.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_rules_report.write_date IS 'Last Updated on';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_rules_report_product 
    ON public.stock_rules_report(tenant_id, product_id);

-- ============================================================
-- Table: stock_rules_report_stock_warehouse_rel
-- ============================================================

CREATE TABLE public.stock_rules_report_stock_warehouse_rel (
    stock_rules_report_id integer NOT NULL,
    stock_warehouse_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_rules_report_stock_warehouse_rel
    ADD CONSTRAINT stock_rules_report_stock_warehouse_rel_pkey PRIMARY KEY (stock_rules_report_id, stock_warehouse_id);

COMMENT ON TABLE public.stock_rules_report_stock_warehouse_rel IS 'RELATION BETWEEN stock_rules_report AND stock_warehouse';

-- ============================================================
-- Table: stock_scrap
-- ============================================================

CREATE TABLE public.stock_scrap (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    company_id integer NOT NULL,
    product_id integer NOT NULL,
    product_uom_id integer NOT NULL,
    lot_id integer,
    package_id integer,
    owner_id integer,
    picking_id integer,
    location_id integer NOT NULL,
    scrap_location_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    origin character varying,
    state character varying,
    scrap_qty numeric NOT NULL,
    should_replenish boolean,
    date_done timestamp without time zone,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_scrap
    ADD CONSTRAINT stock_scrap_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_scrap_tenant 
    ON public.stock_scrap(tenant_id);

COMMENT ON COLUMN public.stock_scrap.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_scrap IS 'Scrap';
COMMENT ON COLUMN public.stock_scrap.company_id IS 'Company';
COMMENT ON COLUMN public.stock_scrap.product_id IS 'Product';
COMMENT ON COLUMN public.stock_scrap.product_uom_id IS 'Unit';
COMMENT ON COLUMN public.stock_scrap.lot_id IS 'Lot/Serial';
COMMENT ON COLUMN public.stock_scrap.package_id IS 'Package';
COMMENT ON COLUMN public.stock_scrap.owner_id IS 'Owner';
COMMENT ON COLUMN public.stock_scrap.picking_id IS 'Picking';
COMMENT ON COLUMN public.stock_scrap.location_id IS 'Source Location';
COMMENT ON COLUMN public.stock_scrap.scrap_location_id IS 'Scrap Location';
COMMENT ON COLUMN public.stock_scrap.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_scrap.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_scrap.name IS 'Reference';
COMMENT ON COLUMN public.stock_scrap.origin IS 'Source Document';
COMMENT ON COLUMN public.stock_scrap.state IS 'Status';
COMMENT ON COLUMN public.stock_scrap.scrap_qty IS 'Quantity';
COMMENT ON COLUMN public.stock_scrap.should_replenish IS 'Replenish Quantities';
COMMENT ON COLUMN public.stock_scrap.date_done IS 'Date';
COMMENT ON COLUMN public.stock_scrap.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_scrap.write_date IS 'Last Updated on';

-- Index: Queries by state
CREATE INDEX IF NOT EXISTS idx_stock_scrap_state 
    ON public.stock_scrap(tenant_id, state) 
    WHERE state IS NOT NULL;

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_scrap_product 
    ON public.stock_scrap(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_scrap_company 
    ON public.stock_scrap(tenant_id, company_id);

-- ============================================================
-- Table: stock_scrap_reason_tag
-- ============================================================

CREATE TABLE public.stock_scrap_reason_tag (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    sequence integer,
    create_uid integer,
    write_uid integer,
    color character varying,
    name jsonb NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_scrap_reason_tag
    ADD CONSTRAINT stock_scrap_reason_tag_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_scrap_reason_tag_tenant 
    ON public.stock_scrap_reason_tag(tenant_id);

COMMENT ON COLUMN public.stock_scrap_reason_tag.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_scrap_reason_tag IS 'Scrap Reason Tag';
COMMENT ON COLUMN public.stock_scrap_reason_tag.sequence IS 'Sequence';
COMMENT ON COLUMN public.stock_scrap_reason_tag.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_scrap_reason_tag.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_scrap_reason_tag.color IS 'Color';
COMMENT ON COLUMN public.stock_scrap_reason_tag.name IS 'Name';
COMMENT ON COLUMN public.stock_scrap_reason_tag.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_scrap_reason_tag.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_scrap_stock_scrap_reason_tag_rel
-- ============================================================

CREATE TABLE public.stock_scrap_stock_scrap_reason_tag_rel (
    stock_scrap_id integer NOT NULL,
    stock_scrap_reason_tag_id integer NOT NULL
);

ALTER TABLE ONLY public.stock_scrap_stock_scrap_reason_tag_rel
    ADD CONSTRAINT stock_scrap_stock_scrap_reason_tag_rel_pkey PRIMARY KEY (stock_scrap_id, stock_scrap_reason_tag_id);

COMMENT ON TABLE public.stock_scrap_stock_scrap_reason_tag_rel IS 'RELATION BETWEEN stock_scrap AND stock_scrap_reason_tag';

-- ============================================================
-- Table: stock_storage_category
-- ============================================================

CREATE TABLE public.stock_storage_category (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    company_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    allow_new_product character varying NOT NULL,
    max_weight numeric,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_storage_category
    ADD CONSTRAINT stock_storage_category_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_storage_category_tenant 
    ON public.stock_storage_category(tenant_id);

COMMENT ON COLUMN public.stock_storage_category.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_storage_category IS 'Storage Category';
COMMENT ON COLUMN public.stock_storage_category.company_id IS 'Company';
COMMENT ON COLUMN public.stock_storage_category.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_storage_category.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_storage_category.name IS 'Storage Category';
COMMENT ON COLUMN public.stock_storage_category.allow_new_product IS 'Allow New Product';
COMMENT ON COLUMN public.stock_storage_category.max_weight IS 'Max Weight';
COMMENT ON COLUMN public.stock_storage_category.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_storage_category.write_date IS 'Last Updated on';

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_storage_category_company 
    ON public.stock_storage_category(tenant_id, company_id);
-- ============================================================
-- Table: stock_storage_category_capacity
-- ============================================================

CREATE TABLE public.stock_storage_category_capacity (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    storage_category_id integer NOT NULL,
    product_id integer,
    package_type_id integer,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    quantity double precision NOT NULL
);

ALTER TABLE ONLY public.stock_storage_category_capacity
    ADD CONSTRAINT stock_storage_category_capacity_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_storage_category_capacity_tenant 
    ON public.stock_storage_category_capacity(tenant_id);

COMMENT ON COLUMN public.stock_storage_category_capacity.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_storage_category_capacity IS 'Storage Category Capacity';
COMMENT ON COLUMN public.stock_storage_category_capacity.storage_category_id IS 'Storage Category';
COMMENT ON COLUMN public.stock_storage_category_capacity.product_id IS 'Product';
COMMENT ON COLUMN public.stock_storage_category_capacity.package_type_id IS 'Package Type';
COMMENT ON COLUMN public.stock_storage_category_capacity.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_storage_category_capacity.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_storage_category_capacity.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_storage_category_capacity.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_storage_category_capacity.quantity IS 'Quantity';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_storage_category_capacity_product 
    ON public.stock_storage_category_capacity(tenant_id, product_id);

-- ============================================================
-- Table: stock_traceability_report
-- ============================================================

CREATE TABLE public.stock_traceability_report (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone
);

ALTER TABLE ONLY public.stock_traceability_report
    ADD CONSTRAINT stock_traceability_report_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_traceability_report_tenant 
    ON public.stock_traceability_report(tenant_id);

COMMENT ON COLUMN public.stock_traceability_report.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_traceability_report IS 'Traceability Report';
COMMENT ON COLUMN public.stock_traceability_report.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_traceability_report.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_traceability_report.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_traceability_report.write_date IS 'Last Updated on';

-- ============================================================
-- Table: stock_warehouse_orderpoint
-- ============================================================

CREATE TABLE public.stock_warehouse_orderpoint (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    warehouse_id integer NOT NULL,
    location_id integer NOT NULL,
    product_id integer NOT NULL,
    replenishment_uom_id integer,
    company_id integer NOT NULL,
    route_id integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    trigger character varying NOT NULL,
    snoozed_until date,
    deadline_date date,
    product_min_qty numeric NOT NULL,
    product_max_qty numeric NOT NULL,
    qty_to_order_computed numeric,
    qty_to_order_manual numeric,
    active boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    supplier_id integer
);

ALTER TABLE ONLY public.stock_warehouse_orderpoint
    ADD CONSTRAINT stock_warehouse_orderpoint_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_warehouse_orderpoint_tenant 
    ON public.stock_warehouse_orderpoint(tenant_id);

COMMENT ON COLUMN public.stock_warehouse_orderpoint.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_warehouse_orderpoint IS 'Minimum Inventory Rule';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.warehouse_id IS 'Warehouse';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.location_id IS 'Location';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.product_id IS 'Product';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.replenishment_uom_id IS 'Multiple';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.company_id IS 'Company';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.route_id IS 'Route';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.name IS 'Name';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.trigger IS 'Trigger';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.snoozed_until IS 'Snoozed';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.deadline_date IS 'Deadline';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.product_min_qty IS 'Min Quantity';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.product_max_qty IS 'Max Quantity';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.qty_to_order_computed IS 'To Order Computed';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.qty_to_order_manual IS 'To Order Manual';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.active IS 'Active';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_warehouse_orderpoint.supplier_id IS 'Vendor Pricelist';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_warehouse_orderpoint_product 
    ON public.stock_warehouse_orderpoint(tenant_id, product_id);

-- Index: Queries by company
CREATE INDEX IF NOT EXISTS idx_stock_warehouse_orderpoint_company 
    ON public.stock_warehouse_orderpoint(tenant_id, company_id);

-- ============================================================
-- Table: stock_warn_insufficient_qty_scrap
-- ============================================================

CREATE TABLE public.stock_warn_insufficient_qty_scrap (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    product_id integer NOT NULL,
    location_id integer NOT NULL,
    scrap_id integer,
    create_uid integer,
    write_uid integer,
    product_uom_name character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    quantity double precision NOT NULL
);

ALTER TABLE ONLY public.stock_warn_insufficient_qty_scrap
    ADD CONSTRAINT stock_warn_insufficient_qty_scrap_pkey PRIMARY KEY (tenant_id, id);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_warn_insufficient_qty_scrap_tenant 
    ON public.stock_warn_insufficient_qty_scrap(tenant_id);

COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_warn_insufficient_qty_scrap IS 'Warn Insufficient Scrap Quantity';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.product_id IS 'Product';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.location_id IS 'Location';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.scrap_id IS 'Scrap';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.create_uid IS 'Created by';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.write_uid IS 'Last Updated by';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.product_uom_name IS 'Unit';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.create_date IS 'Created on';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.write_date IS 'Last Updated on';
COMMENT ON COLUMN public.stock_warn_insufficient_qty_scrap.quantity IS 'Quantity';

-- Index: Queries by product
CREATE INDEX IF NOT EXISTS idx_stock_warn_insufficient_qty_scrap_product 
    ON public.stock_warn_insufficient_qty_scrap(tenant_id, product_id);

-- ============================================================
-- Table: stock_wh_resupply_table
-- ============================================================

CREATE TABLE public.stock_wh_resupply_table (
    tenant_id UUID NOT NULL,
    supplied_wh_id integer NOT NULL,
    supplier_wh_id integer NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for tenant sharding
CREATE INDEX IF NOT EXISTS idx_stock_wh_resupply_table_tenant 
    ON public.stock_wh_resupply_table(tenant_id);

COMMENT ON COLUMN public.stock_wh_resupply_table.tenant_id IS 'Tenant ID for multi-tenancy';
COMMENT ON TABLE public.stock_wh_resupply_table IS 'RELATION BETWEEN stock_warehouse AND stock_warehouse';

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stock_wh_resupply_table_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stock_wh_resupply_table_updated_at
    BEFORE UPDATE ON public.stock_wh_resupply_table
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_wh_resupply_table_timestamp();


-- ============================================================
