-- ============================================================
-- FOREIGN KEY CONSTRAINTS FOR ALL ODOO MODULES
-- ============================================================
-- Run AFTER all table migrations (product, stock, sale, purchase)
-- 
-- This file contains all FK constraints from Odoo,
-- adapted for multi-tenant architecture with tenant_id
--
-- Order of execution:
--   1. 20251205000000_product.sql (tables only)
--   2. 20251205000001_stock.sql (tables only)
--   3. 20251205000002_sale.sql (tables only)
--   4. 20251205000003_purchase.sql (tables only)
--   5. 20251205000004_add_foreign_keys.sql (THIS FILE)
--
-- NOTE: Some FK constraints may be commented out due to:
--   - Type mismatches (integer vs UUID)
--   - Missing tenant_id in relation tables
--   - Structural incompatibilities with multi-tenant design
-- ============================================================

-- ============================================================
-- PRODUCT MODULE FOREIGN KEYS
-- ============================================================

-- FK: account_account_tag_product_template_rel.product_template_id -> product_template.id
-- Original constraint: account_account_tag_product_template_r_product_template_id_fkey
-- ALTER TABLE public.account_account_tag_product_template_rel
--     ADD CONSTRAINT account_account_tag_product_template_r_product_template_id_fkey
--     FOREIGN KEY (product_template_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: account_analytic_applicability.product_categ_id -> product_category.id
-- Original constraint: account_analytic_applicability_product_categ_id_fkey
-- ALTER TABLE public.account_analytic_applicability
--     ADD CONSTRAINT account_analytic_applicability_product_categ_id_fkey
--     FOREIGN KEY (product_categ_id)
--     REFERENCES public.product_category(id)
--     ON DELETE SET NULL;

-- FK: account_analytic_distribution_model.product_categ_id -> product_category.id
-- Original constraint: account_analytic_distribution_model_product_categ_id_fkey
-- ALTER TABLE public.account_analytic_distribution_model
--     ADD CONSTRAINT account_analytic_distribution_model_product_categ_id_fkey
--     FOREIGN KEY (product_categ_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: account_analytic_distribution_model.product_id -> product_product.id
-- Original constraint: account_analytic_distribution_model_product_id_fkey
-- ALTER TABLE public.account_analytic_distribution_model
--     ADD CONSTRAINT account_analytic_distribution_model_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: account_analytic_line.product_id -> product_product.id
-- Original constraint: account_analytic_line_product_id_fkey
-- ALTER TABLE public.account_analytic_line
--     ADD CONSTRAINT account_analytic_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: account_move_line.product_id -> product_product.id
-- Original constraint: account_move_line_product_id_fkey
-- ALTER TABLE public.account_move_line
--     ADD CONSTRAINT account_move_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: product_attr_exclusion_value_ids_rel.product_template_attribute_exclusion_id -> product_template_attribute_exclusion.id
-- Original constraint: product_attr_exclusion_value__product_template_attribute_e_fkey
-- ALTER TABLE public.product_attr_exclusion_value_ids_rel
--     ADD CONSTRAINT product_attr_exclusion_value__product_template_attribute_e_fkey
--     FOREIGN KEY (product_template_attribute_exclusion_id)
--     REFERENCES public.product_template_attribute_exclusion(id)
--     ON DELETE CASCADE;

-- FK: product_attr_exclusion_value_ids_rel.product_template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: product_attr_exclusion_value__product_template_attribute_v_fkey
-- ALTER TABLE public.product_attr_exclusion_value_ids_rel
--     ADD CONSTRAINT product_attr_exclusion_value__product_template_attribute_v_fkey
--     FOREIGN KEY (product_template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE CASCADE;

-- FK: product_attribute.create_uid -> res_users.id
-- Original constraint: product_attribute_create_uid_fkey
-- ALTER TABLE public.product_attribute
--     ADD CONSTRAINT product_attribute_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_attribute.write_uid -> res_users.id
-- Original constraint: product_attribute_write_uid_fkey
-- ALTER TABLE public.product_attribute
--     ADD CONSTRAINT product_attribute_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_attribute_custom_value.custom_product_template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: product_attribute_custom_valu_custom_product_template_attr_fkey
-- ALTER TABLE public.product_attribute_custom_value
--     ADD CONSTRAINT product_attribute_custom_valu_custom_product_template_attr_fkey
--     FOREIGN KEY (custom_product_template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE RESTRICT;

-- FK: product_attribute_custom_value.create_uid -> res_users.id
-- Original constraint: product_attribute_custom_value_create_uid_fkey
-- ALTER TABLE public.product_attribute_custom_value
--     ADD CONSTRAINT product_attribute_custom_value_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_attribute_custom_value.sale_order_line_id -> sale_order_line.id
-- Original constraint: product_attribute_custom_value_sale_order_line_id_fkey
-- ALTER TABLE public.product_attribute_custom_value
--     ADD CONSTRAINT product_attribute_custom_value_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: product_attribute_custom_value.write_uid -> res_users.id
-- Original constraint: product_attribute_custom_value_write_uid_fkey
-- ALTER TABLE public.product_attribute_custom_value
--     ADD CONSTRAINT product_attribute_custom_value_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_attribute_product_template_rel.product_attribute_id -> product_attribute.id
-- Original constraint: product_attribute_product_template_re_product_attribute_id_fkey
-- ALTER TABLE public.product_attribute_product_template_rel
--     ADD CONSTRAINT product_attribute_product_template_re_product_attribute_id_fkey
--     FOREIGN KEY (product_attribute_id)
--     REFERENCES public.product_attribute(id)
--     ON DELETE CASCADE;

-- FK: product_attribute_product_template_rel.product_template_id -> product_template.id
-- Original constraint: product_attribute_product_template_rel_product_template_id_fkey
-- ALTER TABLE public.product_attribute_product_template_rel
--     ADD CONSTRAINT product_attribute_product_template_rel_product_template_id_fkey
--     FOREIGN KEY (product_template_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_attribute_value.attribute_id -> product_attribute.id
-- Original constraint: product_attribute_value_attribute_id_fkey
-- ALTER TABLE public.product_attribute_value
--     ADD CONSTRAINT product_attribute_value_attribute_id_fkey
--     FOREIGN KEY (attribute_id)
--     REFERENCES public.product_attribute(id)
--     ON DELETE CASCADE;

-- FK: product_attribute_value.create_uid -> res_users.id
-- Original constraint: product_attribute_value_create_uid_fkey
-- ALTER TABLE public.product_attribute_value
--     ADD CONSTRAINT product_attribute_value_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_attribute_value.write_uid -> res_users.id
-- Original constraint: product_attribute_value_write_uid_fkey
-- ALTER TABLE public.product_attribute_value
--     ADD CONSTRAINT product_attribute_value_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_attribute_value_product_template_attribute_line_rel.product_template_attribute_line_id -> product_template_attribute_line.id
-- Original constraint: product_attribute_value_produ_product_template_attribute_l_fkey
-- ALTER TABLE public.product_attribute_value_product_template_attribute_line_rel
--     ADD CONSTRAINT product_attribute_value_produ_product_template_attribute_l_fkey
--     FOREIGN KEY (product_template_attribute_line_id)
--     REFERENCES public.product_template_attribute_line(id)
--     ON DELETE CASCADE;

-- FK: product_attribute_value_product_template_attribute_line_rel.product_attribute_value_id -> product_attribute_value.id
-- Original constraint: product_attribute_value_product_product_attribute_value_id_fkey
-- ALTER TABLE public.product_attribute_value_product_template_attribute_line_rel
--     ADD CONSTRAINT product_attribute_value_product_product_attribute_value_id_fkey
--     FOREIGN KEY (product_attribute_value_id)
--     REFERENCES public.product_attribute_value(id)
--     ON DELETE RESTRICT;

-- FK: product_category.create_uid -> res_users.id
-- Original constraint: product_category_create_uid_fkey
-- ALTER TABLE public.product_category
--     ADD CONSTRAINT product_category_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_category.parent_id -> product_category.id
-- Original constraint: product_category_parent_id_fkey
-- ALTER TABLE public.product_category
--     ADD CONSTRAINT product_category_parent_id_fkey
--     FOREIGN KEY (parent_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: product_category.removal_strategy_id -> product_removal.id
-- Original constraint: product_category_removal_strategy_id_fkey
-- ALTER TABLE public.product_category
--     ADD CONSTRAINT product_category_removal_strategy_id_fkey
--     FOREIGN KEY (removal_strategy_id)
--     REFERENCES public.product_removal(id)
--     ON DELETE SET NULL;

-- FK: product_category.write_uid -> res_users.id
-- Original constraint: product_category_write_uid_fkey
-- ALTER TABLE public.product_category
--     ADD CONSTRAINT product_category_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_combo.company_id -> res_company.id
-- Original constraint: product_combo_company_id_fkey
-- ALTER TABLE public.product_combo
--     ADD CONSTRAINT product_combo_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_combo.create_uid -> res_users.id
-- Original constraint: product_combo_create_uid_fkey
-- ALTER TABLE public.product_combo
--     ADD CONSTRAINT product_combo_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_combo.write_uid -> res_users.id
-- Original constraint: product_combo_write_uid_fkey
-- ALTER TABLE public.product_combo
--     ADD CONSTRAINT product_combo_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_combo_item.combo_id -> product_combo.id
-- Original constraint: product_combo_item_combo_id_fkey
-- ALTER TABLE public.product_combo_item
--     ADD CONSTRAINT product_combo_item_combo_id_fkey
--     FOREIGN KEY (combo_id)
--     REFERENCES public.product_combo(id)
--     ON DELETE CASCADE;

-- FK: product_combo_item.company_id -> res_company.id
-- Original constraint: product_combo_item_company_id_fkey
-- ALTER TABLE public.product_combo_item
--     ADD CONSTRAINT product_combo_item_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_combo_item.create_uid -> res_users.id
-- Original constraint: product_combo_item_create_uid_fkey
-- ALTER TABLE public.product_combo_item
--     ADD CONSTRAINT product_combo_item_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_combo_item.product_id -> product_product.id
-- Original constraint: product_combo_item_product_id_fkey
-- ALTER TABLE public.product_combo_item
--     ADD CONSTRAINT product_combo_item_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: product_combo_item.write_uid -> res_users.id
-- Original constraint: product_combo_item_write_uid_fkey
-- ALTER TABLE public.product_combo_item
--     ADD CONSTRAINT product_combo_item_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_combo_product_template_rel.product_combo_id -> product_combo.id
-- Original constraint: product_combo_product_template_rel_product_combo_id_fkey
-- ALTER TABLE public.product_combo_product_template_rel
--     ADD CONSTRAINT product_combo_product_template_rel_product_combo_id_fkey
--     FOREIGN KEY (product_combo_id)
--     REFERENCES public.product_combo(id)
--     ON DELETE CASCADE;

-- FK: product_combo_product_template_rel.product_template_id -> product_template.id
-- Original constraint: product_combo_product_template_rel_product_template_id_fkey
-- ALTER TABLE public.product_combo_product_template_rel
--     ADD CONSTRAINT product_combo_product_template_rel_product_template_id_fkey
--     FOREIGN KEY (product_template_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_document.create_uid -> res_users.id
-- Original constraint: product_document_create_uid_fkey
-- ALTER TABLE public.product_document
--     ADD CONSTRAINT product_document_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_document.ir_attachment_id -> ir_attachment.id
-- Original constraint: product_document_ir_attachment_id_fkey
-- ALTER TABLE public.product_document
--     ADD CONSTRAINT product_document_ir_attachment_id_fkey
--     FOREIGN KEY (ir_attachment_id)
--     REFERENCES public.ir_attachment(id)
--     ON DELETE CASCADE;

-- FK: product_document.write_uid -> res_users.id
-- Original constraint: product_document_write_uid_fkey
-- ALTER TABLE public.product_document
--     ADD CONSTRAINT product_document_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_document_sale_pdf_form_field_rel.sale_pdf_form_field_id -> sale_pdf_form_field.id
-- Original constraint: product_document_sale_pdf_form_fiel_sale_pdf_form_field_id_fkey
-- ALTER TABLE public.product_document_sale_pdf_form_field_rel
--     ADD CONSTRAINT product_document_sale_pdf_form_fiel_sale_pdf_form_field_id_fkey
--     FOREIGN KEY (sale_pdf_form_field_id)
--     REFERENCES public.sale_pdf_form_field(id)
--     ON DELETE CASCADE;

-- FK: product_document_sale_pdf_form_field_rel.product_document_id -> product_document.id
-- Original constraint: product_document_sale_pdf_form_field_r_product_document_id_fkey
-- ALTER TABLE public.product_document_sale_pdf_form_field_rel
--     ADD CONSTRAINT product_document_sale_pdf_form_field_r_product_document_id_fkey
--     FOREIGN KEY (product_document_id)
--     REFERENCES public.product_document(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout.create_uid -> res_users.id
-- Original constraint: product_label_layout_create_uid_fkey
-- ALTER TABLE public.product_label_layout
--     ADD CONSTRAINT product_label_layout_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_label_layout.pricelist_id -> product_pricelist.id
-- Original constraint: product_label_layout_pricelist_id_fkey
-- ALTER TABLE public.product_label_layout
--     ADD CONSTRAINT product_label_layout_pricelist_id_fkey
--     FOREIGN KEY (pricelist_id)
--     REFERENCES public.product_pricelist(id)
--     ON DELETE SET NULL;

-- FK: product_label_layout.write_uid -> res_users.id
-- Original constraint: product_label_layout_write_uid_fkey
-- ALTER TABLE public.product_label_layout
--     ADD CONSTRAINT product_label_layout_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_label_layout_product_product_rel.product_label_layout_id -> product_label_layout.id
-- Original constraint: product_label_layout_product_produ_product_label_layout_id_fkey
-- ALTER TABLE public.product_label_layout_product_product_rel
--     ADD CONSTRAINT product_label_layout_product_produ_product_label_layout_id_fkey
--     FOREIGN KEY (product_label_layout_id)
--     REFERENCES public.product_label_layout(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout_product_product_rel.product_product_id -> product_product.id
-- Original constraint: product_label_layout_product_product_re_product_product_id_fkey
-- ALTER TABLE public.product_label_layout_product_product_rel
--     ADD CONSTRAINT product_label_layout_product_product_re_product_product_id_fkey
--     FOREIGN KEY (product_product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout_product_template_rel.product_label_layout_id -> product_label_layout.id
-- Original constraint: product_label_layout_product_templ_product_label_layout_id_fkey
-- ALTER TABLE public.product_label_layout_product_template_rel
--     ADD CONSTRAINT product_label_layout_product_templ_product_label_layout_id_fkey
--     FOREIGN KEY (product_label_layout_id)
--     REFERENCES public.product_label_layout(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout_product_template_rel.product_template_id -> product_template.id
-- Original constraint: product_label_layout_product_template__product_template_id_fkey
-- ALTER TABLE public.product_label_layout_product_template_rel
--     ADD CONSTRAINT product_label_layout_product_template__product_template_id_fkey
--     FOREIGN KEY (product_template_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout_stock_move_rel.product_label_layout_id -> product_label_layout.id
-- Original constraint: product_label_layout_stock_move_re_product_label_layout_id_fkey
-- ALTER TABLE public.product_label_layout_stock_move_rel
--     ADD CONSTRAINT product_label_layout_stock_move_re_product_label_layout_id_fkey
--     FOREIGN KEY (product_label_layout_id)
--     REFERENCES public.product_label_layout(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout_stock_move_rel.stock_move_id -> stock_move.id
-- Original constraint: product_label_layout_stock_move_rel_stock_move_id_fkey
-- ALTER TABLE public.product_label_layout_stock_move_rel
--     ADD CONSTRAINT product_label_layout_stock_move_rel_stock_move_id_fkey
--     FOREIGN KEY (stock_move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: product_optional_rel.dest_id -> product_template.id
-- Original constraint: product_optional_rel_dest_id_fkey
-- ALTER TABLE public.product_optional_rel
--     ADD CONSTRAINT product_optional_rel_dest_id_fkey
--     FOREIGN KEY (dest_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_optional_rel.src_id -> product_template.id
-- Original constraint: product_optional_rel_src_id_fkey
-- ALTER TABLE public.product_optional_rel
--     ADD CONSTRAINT product_optional_rel_src_id_fkey
--     FOREIGN KEY (src_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_pricelist.company_id -> res_company.id
-- Original constraint: product_pricelist_company_id_fkey
-- ALTER TABLE public.product_pricelist
--     ADD CONSTRAINT product_pricelist_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist.create_uid -> res_users.id
-- Original constraint: product_pricelist_create_uid_fkey
-- ALTER TABLE public.product_pricelist
--     ADD CONSTRAINT product_pricelist_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist.currency_id -> res_currency.id
-- Original constraint: product_pricelist_currency_id_fkey
-- ALTER TABLE public.product_pricelist
--     ADD CONSTRAINT product_pricelist_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE RESTRICT;

-- FK: product_pricelist.write_uid -> res_users.id
-- Original constraint: product_pricelist_write_uid_fkey
-- ALTER TABLE public.product_pricelist
--     ADD CONSTRAINT product_pricelist_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist_item.base_pricelist_id -> product_pricelist.id
-- Original constraint: product_pricelist_item_base_pricelist_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_base_pricelist_id_fkey
--     FOREIGN KEY (base_pricelist_id)
--     REFERENCES public.product_pricelist(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist_item.categ_id -> product_category.id
-- Original constraint: product_pricelist_item_categ_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_categ_id_fkey
--     FOREIGN KEY (categ_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: product_pricelist_item.company_id -> res_company.id
-- Original constraint: product_pricelist_item_company_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist_item.create_uid -> res_users.id
-- Original constraint: product_pricelist_item_create_uid_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist_item.currency_id -> res_currency.id
-- Original constraint: product_pricelist_item_currency_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE SET NULL;

-- FK: product_pricelist_item.pricelist_id -> product_pricelist.id
-- Original constraint: product_pricelist_item_pricelist_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_pricelist_id_fkey
--     FOREIGN KEY (pricelist_id)
--     REFERENCES public.product_pricelist(id)
--     ON DELETE CASCADE;

-- FK: product_pricelist_item.product_id -> product_product.id
-- Original constraint: product_pricelist_item_product_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: product_pricelist_item.product_tmpl_id -> product_template.id
-- Original constraint: product_pricelist_item_product_tmpl_id_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_pricelist_item.write_uid -> res_users.id
-- Original constraint: product_pricelist_item_write_uid_fkey
-- ALTER TABLE public.product_pricelist_item
--     ADD CONSTRAINT product_pricelist_item_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_product.create_uid -> res_users.id
-- Original constraint: product_product_create_uid_fkey
-- ALTER TABLE public.product_product
--     ADD CONSTRAINT product_product_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_product.product_tmpl_id -> product_template.id
-- Original constraint: product_product_product_tmpl_id_fkey
-- ALTER TABLE public.product_product
--     ADD CONSTRAINT product_product_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_product.write_uid -> res_users.id
-- Original constraint: product_product_write_uid_fkey
-- ALTER TABLE public.product_product
--     ADD CONSTRAINT product_product_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_removal.create_uid -> res_users.id
-- Original constraint: product_removal_create_uid_fkey
-- ALTER TABLE public.product_removal
--     ADD CONSTRAINT product_removal_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_removal.write_uid -> res_users.id
-- Original constraint: product_removal_write_uid_fkey
-- ALTER TABLE public.product_removal
--     ADD CONSTRAINT product_removal_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_replenish.company_id -> res_company.id
-- Original constraint: product_replenish_company_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_replenish.create_uid -> res_users.id
-- Original constraint: product_replenish_create_uid_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_replenish.product_id -> product_product.id
-- Original constraint: product_replenish_product_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: product_replenish.product_tmpl_id -> product_template.id
-- Original constraint: product_replenish_product_tmpl_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_replenish.product_uom_id -> uom_uom.id
-- Original constraint: product_replenish_product_uom_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE CASCADE;

-- FK: product_replenish.route_id -> stock_route.id
-- Original constraint: product_replenish_route_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE SET NULL;

-- FK: product_replenish.supplier_id -> product_supplierinfo.id
-- Original constraint: product_replenish_supplier_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_supplier_id_fkey
--     FOREIGN KEY (supplier_id)
--     REFERENCES public.product_supplierinfo(id)
--     ON DELETE SET NULL;

-- FK: product_replenish.warehouse_id -> stock_warehouse.id
-- Original constraint: product_replenish_warehouse_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: product_replenish.write_uid -> res_users.id
-- Original constraint: product_replenish_write_uid_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_supplier_taxes_rel.prod_id -> product_template.id
-- Original constraint: product_supplier_taxes_rel_prod_id_fkey
-- ALTER TABLE public.product_supplier_taxes_rel
--     ADD CONSTRAINT product_supplier_taxes_rel_prod_id_fkey
--     FOREIGN KEY (prod_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_supplier_taxes_rel.tax_id -> account_tax.id
-- Original constraint: product_supplier_taxes_rel_tax_id_fkey
-- ALTER TABLE public.product_supplier_taxes_rel
--     ADD CONSTRAINT product_supplier_taxes_rel_tax_id_fkey
--     FOREIGN KEY (tax_id)
--     REFERENCES public.account_tax(id)
--     ON DELETE CASCADE;

-- FK: product_supplierinfo.company_id -> res_company.id
-- Original constraint: product_supplierinfo_company_id_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_supplierinfo.create_uid -> res_users.id
-- Original constraint: product_supplierinfo_create_uid_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_supplierinfo.currency_id -> res_currency.id
-- Original constraint: product_supplierinfo_currency_id_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE RESTRICT;

-- FK: product_supplierinfo.partner_id -> res_partner.id
-- Original constraint: product_supplierinfo_partner_id_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE CASCADE;

-- FK: product_supplierinfo.product_id -> product_product.id
-- Original constraint: product_supplierinfo_product_id_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: product_supplierinfo.product_tmpl_id -> product_template.id
-- Original constraint: product_supplierinfo_product_tmpl_id_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_supplierinfo.product_uom_id -> uom_uom.id
-- Original constraint: product_supplierinfo_product_uom_id_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: product_supplierinfo.write_uid -> res_users.id
-- Original constraint: product_supplierinfo_write_uid_fkey
-- ALTER TABLE public.product_supplierinfo
--     ADD CONSTRAINT product_supplierinfo_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_supplierinfo_stock_replenishment_info_rel.stock_replenishment_info_id -> stock_replenishment_info.id
-- Original constraint: product_supplierinfo_stock_rep_stock_replenishment_info_id_fkey
-- ALTER TABLE public.product_supplierinfo_stock_replenishment_info_rel
--     ADD CONSTRAINT product_supplierinfo_stock_rep_stock_replenishment_info_id_fkey
--     FOREIGN KEY (stock_replenishment_info_id)
--     REFERENCES public.stock_replenishment_info(id)
--     ON DELETE CASCADE;

-- FK: product_supplierinfo_stock_replenishment_info_rel.product_supplierinfo_id -> product_supplierinfo.id
-- Original constraint: product_supplierinfo_stock_repleni_product_supplierinfo_id_fkey
-- ALTER TABLE public.product_supplierinfo_stock_replenishment_info_rel
--     ADD CONSTRAINT product_supplierinfo_stock_repleni_product_supplierinfo_id_fkey
--     FOREIGN KEY (product_supplierinfo_id)
--     REFERENCES public.product_supplierinfo(id)
--     ON DELETE CASCADE;

-- FK: product_tag.create_uid -> res_users.id
-- Original constraint: product_tag_create_uid_fkey
-- ALTER TABLE public.product_tag
--     ADD CONSTRAINT product_tag_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_tag.write_uid -> res_users.id
-- Original constraint: product_tag_write_uid_fkey
-- ALTER TABLE public.product_tag
--     ADD CONSTRAINT product_tag_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_tag_product_product_rel.product_product_id -> product_product.id
-- Original constraint: product_tag_product_product_rel_product_product_id_fkey
-- ALTER TABLE public.product_tag_product_product_rel
--     ADD CONSTRAINT product_tag_product_product_rel_product_product_id_fkey
--     FOREIGN KEY (product_product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: product_tag_product_product_rel.product_tag_id -> product_tag.id
-- Original constraint: product_tag_product_product_rel_product_tag_id_fkey
-- ALTER TABLE public.product_tag_product_product_rel
--     ADD CONSTRAINT product_tag_product_product_rel_product_tag_id_fkey
--     FOREIGN KEY (product_tag_id)
--     REFERENCES public.product_tag(id)
--     ON DELETE CASCADE;

-- FK: product_tag_product_template_rel.product_tag_id -> product_tag.id
-- Original constraint: product_tag_product_template_rel_product_tag_id_fkey
-- ALTER TABLE public.product_tag_product_template_rel
--     ADD CONSTRAINT product_tag_product_template_rel_product_tag_id_fkey
--     FOREIGN KEY (product_tag_id)
--     REFERENCES public.product_tag(id)
--     ON DELETE CASCADE;

-- FK: product_tag_product_template_rel.product_template_id -> product_template.id
-- Original constraint: product_tag_product_template_rel_product_template_id_fkey
-- ALTER TABLE public.product_tag_product_template_rel
--     ADD CONSTRAINT product_tag_product_template_rel_product_template_id_fkey
--     FOREIGN KEY (product_template_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_taxes_rel.prod_id -> product_template.id
-- Original constraint: product_taxes_rel_prod_id_fkey
-- ALTER TABLE public.product_taxes_rel
--     ADD CONSTRAINT product_taxes_rel_prod_id_fkey
--     FOREIGN KEY (prod_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_taxes_rel.tax_id -> account_tax.id
-- Original constraint: product_taxes_rel_tax_id_fkey
-- ALTER TABLE public.product_taxes_rel
--     ADD CONSTRAINT product_taxes_rel_tax_id_fkey
--     FOREIGN KEY (tax_id)
--     REFERENCES public.account_tax(id)
--     ON DELETE CASCADE;

-- FK: product_template.categ_id -> product_category.id
-- Original constraint: product_template_categ_id_fkey
-- ALTER TABLE public.product_template
--     ADD CONSTRAINT product_template_categ_id_fkey
--     FOREIGN KEY (categ_id)
--     REFERENCES public.product_category(id)
--     ON DELETE SET NULL;

-- FK: product_template.company_id -> res_company.id
-- Original constraint: product_template_company_id_fkey
-- ALTER TABLE public.product_template
--     ADD CONSTRAINT product_template_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_template.create_uid -> res_users.id
-- Original constraint: product_template_create_uid_fkey
-- ALTER TABLE public.product_template
--     ADD CONSTRAINT product_template_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template.lot_sequence_id -> ir_sequence.id
-- Original constraint: product_template_lot_sequence_id_fkey
-- ALTER TABLE public.product_template
--     ADD CONSTRAINT product_template_lot_sequence_id_fkey
--     FOREIGN KEY (lot_sequence_id)
--     REFERENCES public.ir_sequence(id)
--     ON DELETE SET NULL;

-- FK: product_template.uom_id -> uom_uom.id
-- Original constraint: product_template_uom_id_fkey
-- ALTER TABLE public.product_template
--     ADD CONSTRAINT product_template_uom_id_fkey
--     FOREIGN KEY (uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: product_template.write_uid -> res_users.id
-- Original constraint: product_template_write_uid_fkey
-- ALTER TABLE public.product_template
--     ADD CONSTRAINT product_template_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_exclusion.product_template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: product_template_attribute_ex_product_template_attribute_v_fkey
-- ALTER TABLE public.product_template_attribute_exclusion
--     ADD CONSTRAINT product_template_attribute_ex_product_template_attribute_v_fkey
--     FOREIGN KEY (product_template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_exclusion.create_uid -> res_users.id
-- Original constraint: product_template_attribute_exclusion_create_uid_fkey
-- ALTER TABLE public.product_template_attribute_exclusion
--     ADD CONSTRAINT product_template_attribute_exclusion_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_exclusion.product_tmpl_id -> product_template.id
-- Original constraint: product_template_attribute_exclusion_product_tmpl_id_fkey
-- ALTER TABLE public.product_template_attribute_exclusion
--     ADD CONSTRAINT product_template_attribute_exclusion_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_exclusion.write_uid -> res_users.id
-- Original constraint: product_template_attribute_exclusion_write_uid_fkey
-- ALTER TABLE public.product_template_attribute_exclusion
--     ADD CONSTRAINT product_template_attribute_exclusion_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_line.attribute_id -> product_attribute.id
-- Original constraint: product_template_attribute_line_attribute_id_fkey
-- ALTER TABLE public.product_template_attribute_line
--     ADD CONSTRAINT product_template_attribute_line_attribute_id_fkey
--     FOREIGN KEY (attribute_id)
--     REFERENCES public.product_attribute(id)
--     ON DELETE RESTRICT;

-- FK: product_template_attribute_line.create_uid -> res_users.id
-- Original constraint: product_template_attribute_line_create_uid_fkey
-- ALTER TABLE public.product_template_attribute_line
--     ADD CONSTRAINT product_template_attribute_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_line.product_tmpl_id -> product_template.id
-- Original constraint: product_template_attribute_line_product_tmpl_id_fkey
-- ALTER TABLE public.product_template_attribute_line
--     ADD CONSTRAINT product_template_attribute_line_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_line.write_uid -> res_users.id
-- Original constraint: product_template_attribute_line_write_uid_fkey
-- ALTER TABLE public.product_template_attribute_line
--     ADD CONSTRAINT product_template_attribute_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_value.product_attribute_value_id -> product_attribute_value.id
-- Original constraint: product_template_attribute_valu_product_attribute_value_id_fkey
-- ALTER TABLE public.product_template_attribute_value
--     ADD CONSTRAINT product_template_attribute_valu_product_attribute_value_id_fkey
--     FOREIGN KEY (product_attribute_value_id)
--     REFERENCES public.product_attribute_value(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_value.attribute_id -> product_attribute.id
-- Original constraint: product_template_attribute_value_attribute_id_fkey
-- ALTER TABLE public.product_template_attribute_value
--     ADD CONSTRAINT product_template_attribute_value_attribute_id_fkey
--     FOREIGN KEY (attribute_id)
--     REFERENCES public.product_attribute(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_value.attribute_line_id -> product_template_attribute_line.id
-- Original constraint: product_template_attribute_value_attribute_line_id_fkey
-- ALTER TABLE public.product_template_attribute_value
--     ADD CONSTRAINT product_template_attribute_value_attribute_line_id_fkey
--     FOREIGN KEY (attribute_line_id)
--     REFERENCES public.product_template_attribute_line(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_value.create_uid -> res_users.id
-- Original constraint: product_template_attribute_value_create_uid_fkey
-- ALTER TABLE public.product_template_attribute_value
--     ADD CONSTRAINT product_template_attribute_value_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_value.product_tmpl_id -> product_template.id
-- Original constraint: product_template_attribute_value_product_tmpl_id_fkey
-- ALTER TABLE public.product_template_attribute_value
--     ADD CONSTRAINT product_template_attribute_value_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_value.write_uid -> res_users.id
-- Original constraint: product_template_attribute_value_write_uid_fkey
-- ALTER TABLE public.product_template_attribute_value
--     ADD CONSTRAINT product_template_attribute_value_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_value_purchase_order_line_rel.product_template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: product_template_attribute_v_product_template_attribute_v_fkey1
-- ALTER TABLE public.product_template_attribute_value_purchase_order_line_rel
--     ADD CONSTRAINT product_template_attribute_v_product_template_attribute_v_fkey1
--     FOREIGN KEY (product_template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE RESTRICT;

-- FK: product_template_attribute_value_purchase_order_line_rel.purchase_order_line_id -> purchase_order_line.id
-- Original constraint: product_template_attribute_value_pu_purchase_order_line_id_fkey
-- ALTER TABLE public.product_template_attribute_value_purchase_order_line_rel
--     ADD CONSTRAINT product_template_attribute_value_pu_purchase_order_line_id_fkey
--     FOREIGN KEY (purchase_order_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_value_sale_order_line_rel.product_template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: product_template_attribute_va_product_template_attribute_v_fkey
-- ALTER TABLE public.product_template_attribute_value_sale_order_line_rel
--     ADD CONSTRAINT product_template_attribute_va_product_template_attribute_v_fkey
--     FOREIGN KEY (product_template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE RESTRICT;

-- FK: product_template_attribute_value_sale_order_line_rel.sale_order_line_id -> sale_order_line.id
-- Original constraint: product_template_attribute_value_sale_o_sale_order_line_id_fkey
-- ALTER TABLE public.product_template_attribute_value_sale_order_line_rel
--     ADD CONSTRAINT product_template_attribute_value_sale_o_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: product_template_uom_uom_rel.product_template_id -> product_template.id
-- Original constraint: product_template_uom_uom_rel_product_template_id_fkey
-- ALTER TABLE public.product_template_uom_uom_rel
--     ADD CONSTRAINT product_template_uom_uom_rel_product_template_id_fkey
--     FOREIGN KEY (product_template_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: product_template_uom_uom_rel.uom_uom_id -> uom_uom.id
-- Original constraint: product_template_uom_uom_rel_uom_uom_id_fkey
-- ALTER TABLE public.product_template_uom_uom_rel
--     ADD CONSTRAINT product_template_uom_uom_rel_uom_uom_id_fkey
--     FOREIGN KEY (uom_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE CASCADE;

-- FK: product_uom.company_id -> res_company.id
-- Original constraint: product_uom_company_id_fkey
-- ALTER TABLE public.product_uom
--     ADD CONSTRAINT product_uom_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: product_uom.create_uid -> res_users.id
-- Original constraint: product_uom_create_uid_fkey
-- ALTER TABLE public.product_uom
--     ADD CONSTRAINT product_uom_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_uom.product_id -> product_product.id
-- Original constraint: product_uom_product_id_fkey
-- ALTER TABLE public.product_uom
--     ADD CONSTRAINT product_uom_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: product_uom.uom_id -> uom_uom.id
-- Original constraint: product_uom_uom_id_fkey
-- ALTER TABLE public.product_uom
--     ADD CONSTRAINT product_uom_uom_id_fkey
--     FOREIGN KEY (uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE CASCADE;

-- FK: product_uom.write_uid -> res_users.id
-- Original constraint: product_uom_write_uid_fkey
-- ALTER TABLE public.product_uom
--     ADD CONSTRAINT product_uom_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_value.company_id -> res_company.id
-- Original constraint: product_value_company_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: product_value.create_uid -> res_users.id
-- Original constraint: product_value_create_uid_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_value.lot_id -> stock_lot.id
-- Original constraint: product_value_lot_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_lot_id_fkey
--     FOREIGN KEY (lot_id)
--     REFERENCES public.stock_lot(id)
--     ON DELETE SET NULL;

-- FK: product_value.move_id -> stock_move.id
-- Original constraint: product_value_move_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE SET NULL;

-- FK: product_value.product_id -> product_product.id
-- Original constraint: product_value_product_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: product_value.user_id -> res_users.id
-- Original constraint: product_value_user_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_user_id_fkey
--     FOREIGN KEY (user_id)
--     REFERENCES public.res_users(id)
--     ON DELETE RESTRICT;

-- FK: product_value.write_uid -> res_users.id
-- Original constraint: product_value_write_uid_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: product_variant_combination.product_product_id -> product_product.id
-- Original constraint: product_variant_combination_product_product_id_fkey
-- ALTER TABLE public.product_variant_combination
--     ADD CONSTRAINT product_variant_combination_product_product_id_fkey
--     FOREIGN KEY (product_product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: product_variant_combination.product_template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: product_variant_combination_product_template_attribute_val_fkey
-- ALTER TABLE public.product_variant_combination
--     ADD CONSTRAINT product_variant_combination_product_template_attribute_val_fkey
--     FOREIGN KEY (product_template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order_line.product_id -> product_product.id
-- Original constraint: purchase_order_line_product_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: res_company.sale_discount_product_id -> product_product.id
-- Original constraint: res_company_sale_discount_product_id_fkey
-- ALTER TABLE public.res_company
--     ADD CONSTRAINT res_company_sale_discount_product_id_fkey
--     FOREIGN KEY (sale_discount_product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: res_country_group_pricelist_rel.pricelist_id -> product_pricelist.id
-- Original constraint: res_country_group_pricelist_rel_pricelist_id_fkey
-- ALTER TABLE public.res_country_group_pricelist_rel
--     ADD CONSTRAINT res_country_group_pricelist_rel_pricelist_id_fkey
--     FOREIGN KEY (pricelist_id)
--     REFERENCES public.product_pricelist(id)
--     ON DELETE CASCADE;

-- FK: sale_order.pricelist_id -> product_pricelist.id
-- Original constraint: sale_order_pricelist_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_pricelist_id_fkey
--     FOREIGN KEY (pricelist_id)
--     REFERENCES public.product_pricelist(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.combo_item_id -> product_combo_item.id
-- Original constraint: sale_order_line_combo_item_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_combo_item_id_fkey
--     FOREIGN KEY (combo_item_id)
--     REFERENCES public.product_combo_item(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.product_id -> product_product.id
-- Original constraint: sale_order_line_product_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: sale_order_line_product_document_rel.product_document_id -> product_document.id
-- Original constraint: sale_order_line_product_document_rel_product_document_id_fkey
-- ALTER TABLE public.sale_order_line_product_document_rel
--     ADD CONSTRAINT sale_order_line_product_document_rel_product_document_id_fkey
--     FOREIGN KEY (product_document_id)
--     REFERENCES public.product_document(id)
--     ON DELETE CASCADE;

-- FK: sale_order_template_line.product_id -> product_product.id
-- Original constraint: sale_order_template_line_product_id_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: stock_location.removal_strategy_id -> product_removal.id
-- Original constraint: stock_location_removal_strategy_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_removal_strategy_id_fkey
--     FOREIGN KEY (removal_strategy_id)
--     REFERENCES public.product_removal(id)
--     ON DELETE SET NULL;

-- FK: stock_lot.product_id -> product_product.id
-- Original constraint: stock_lot_product_id_fkey
-- ALTER TABLE public.stock_lot
--     ADD CONSTRAINT stock_lot_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.product_id -> product_product.id
-- Original constraint: stock_move_product_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.product_id -> product_product.id
-- Original constraint: stock_move_line_product_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.category_id -> product_category.id
-- Original constraint: stock_putaway_rule_category_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_category_id_fkey
--     FOREIGN KEY (category_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.product_id -> product_product.id
-- Original constraint: stock_putaway_rule_product_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_quant.product_id -> product_product.id
-- Original constraint: stock_quant_product_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_replenishment_option.product_id -> product_product.id
-- Original constraint: stock_replenishment_option_product_id_fkey
-- ALTER TABLE public.stock_replenishment_option
--     ADD CONSTRAINT stock_replenishment_option_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking_line.product_id -> product_product.id
-- Original constraint: stock_return_picking_line_product_id_fkey
-- ALTER TABLE public.stock_return_picking_line
--     ADD CONSTRAINT stock_return_picking_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_route_categ.categ_id -> product_category.id
-- Original constraint: stock_route_categ_categ_id_fkey
-- ALTER TABLE public.stock_route_categ
--     ADD CONSTRAINT stock_route_categ_categ_id_fkey
--     FOREIGN KEY (categ_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: stock_route_product.product_id -> product_template.id
-- Original constraint: stock_route_product_product_id_fkey
-- ALTER TABLE public.stock_route_product
--     ADD CONSTRAINT stock_route_product_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: stock_rules_report.product_id -> product_product.id
-- Original constraint: stock_rules_report_product_id_fkey
-- ALTER TABLE public.stock_rules_report
--     ADD CONSTRAINT stock_rules_report_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_rules_report.product_tmpl_id -> product_template.id
-- Original constraint: stock_rules_report_product_tmpl_id_fkey
-- ALTER TABLE public.stock_rules_report
--     ADD CONSTRAINT stock_rules_report_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: stock_scrap.product_id -> product_product.id
-- Original constraint: stock_scrap_product_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_storage_category_capacity.product_id -> product_product.id
-- Original constraint: stock_storage_category_capacity_product_id_fkey
-- ALTER TABLE public.stock_storage_category_capacity
--     ADD CONSTRAINT stock_storage_category_capacity_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_warehouse_orderpoint.product_id -> product_product.id
-- Original constraint: stock_warehouse_orderpoint_product_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_warehouse_orderpoint.supplier_id -> product_supplierinfo.id
-- Original constraint: stock_warehouse_orderpoint_supplier_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_supplier_id_fkey
--     FOREIGN KEY (supplier_id)
--     REFERENCES public.product_supplierinfo(id)
--     ON DELETE SET NULL;

-- FK: stock_warn_insufficient_qty_scrap.product_id -> product_product.id
-- Original constraint: stock_warn_insufficient_qty_scrap_product_id_fkey
-- ALTER TABLE public.stock_warn_insufficient_qty_scrap
--     ADD CONSTRAINT stock_warn_insufficient_qty_scrap_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: template_attribute_value_stock_move_rel.template_attribute_value_id -> product_template_attribute_value.id
-- Original constraint: template_attribute_value_stock_template_attribute_value_id_fkey
-- ALTER TABLE public.template_attribute_value_stock_move_rel
--     ADD CONSTRAINT template_attribute_value_stock_template_attribute_value_id_fkey
--     FOREIGN KEY (template_attribute_value_id)
--     REFERENCES public.product_template_attribute_value(id)
--     ON DELETE CASCADE;

-- FK: update_product_attribute_value.attribute_value_id -> product_attribute_value.id
-- Original constraint: update_product_attribute_value_attribute_value_id_fkey
-- ALTER TABLE public.update_product_attribute_value
--     ADD CONSTRAINT update_product_attribute_value_attribute_value_id_fkey
--     FOREIGN KEY (attribute_value_id)
--     REFERENCES public.product_attribute_value(id)
--     ON DELETE CASCADE;


-- ============================================================
-- STOCK MODULE FOREIGN KEYS
-- ============================================================

-- FK: account_analytic_line_stock_move_rel.stock_move_id -> stock_move.id
-- Original constraint: account_analytic_line_stock_move_rel_stock_move_id_fkey
-- ALTER TABLE public.account_analytic_line_stock_move_rel
--     ADD CONSTRAINT account_analytic_line_stock_move_rel_stock_move_id_fkey
--     FOREIGN KEY (stock_move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: lot_label_layout_stock_move_line_rel.stock_move_line_id -> stock_move_line.id
-- Original constraint: lot_label_layout_stock_move_line_rel_stock_move_line_id_fkey
-- ALTER TABLE public.lot_label_layout_stock_move_line_rel
--     ADD CONSTRAINT lot_label_layout_stock_move_line_rel_stock_move_line_id_fkey
--     FOREIGN KEY (stock_move_line_id)
--     REFERENCES public.stock_move_line(id)
--     ON DELETE CASCADE;

-- FK: picking_label_type_stock_picking_rel.stock_picking_id -> stock_picking.id
-- Original constraint: picking_label_type_stock_picking_rel_stock_picking_id_fkey
-- ALTER TABLE public.picking_label_type_stock_picking_rel
--     ADD CONSTRAINT picking_label_type_stock_picking_rel_stock_picking_id_fkey
--     FOREIGN KEY (stock_picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE CASCADE;

-- FK: picking_type_favorite_user_rel.picking_type_id -> stock_picking_type.id
-- Original constraint: picking_type_favorite_user_rel_picking_type_id_fkey
-- ALTER TABLE public.picking_type_favorite_user_rel
--     ADD CONSTRAINT picking_type_favorite_user_rel_picking_type_id_fkey
--     FOREIGN KEY (picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE CASCADE;

-- FK: product_label_layout_stock_move_rel.stock_move_id -> stock_move.id
-- Original constraint: product_label_layout_stock_move_rel_stock_move_id_fkey
-- ALTER TABLE public.product_label_layout_stock_move_rel
--     ADD CONSTRAINT product_label_layout_stock_move_rel_stock_move_id_fkey
--     FOREIGN KEY (stock_move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: product_replenish.route_id -> stock_route.id
-- Original constraint: product_replenish_route_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE SET NULL;

-- FK: product_replenish.warehouse_id -> stock_warehouse.id
-- Original constraint: product_replenish_warehouse_id_fkey
-- ALTER TABLE public.product_replenish
--     ADD CONSTRAINT product_replenish_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: product_supplierinfo_stock_replenishment_info_rel.stock_replenishment_info_id -> stock_replenishment_info.id
-- Original constraint: product_supplierinfo_stock_rep_stock_replenishment_info_id_fkey
-- ALTER TABLE public.product_supplierinfo_stock_replenishment_info_rel
--     ADD CONSTRAINT product_supplierinfo_stock_rep_stock_replenishment_info_id_fkey
--     FOREIGN KEY (stock_replenishment_info_id)
--     REFERENCES public.stock_replenishment_info(id)
--     ON DELETE CASCADE;

-- FK: product_value.lot_id -> stock_lot.id
-- Original constraint: product_value_lot_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_lot_id_fkey
--     FOREIGN KEY (lot_id)
--     REFERENCES public.stock_lot(id)
--     ON DELETE SET NULL;

-- FK: product_value.move_id -> stock_move.id
-- Original constraint: product_value_move_id_fkey
-- ALTER TABLE public.product_value
--     ADD CONSTRAINT product_value_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.picking_type_id -> stock_picking_type.id
-- Original constraint: purchase_order_picking_type_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_picking_type_id_fkey
--     FOREIGN KEY (picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order_line.location_final_id -> stock_location.id
-- Original constraint: purchase_order_line_location_final_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_location_final_id_fkey
--     FOREIGN KEY (location_final_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.orderpoint_id -> stock_warehouse_orderpoint.id
-- Original constraint: purchase_order_line_orderpoint_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_orderpoint_id_fkey
--     FOREIGN KEY (orderpoint_id)
--     REFERENCES public.stock_warehouse_orderpoint(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_stock_picking_rel.stock_picking_id -> stock_picking.id
-- Original constraint: purchase_order_stock_picking_rel_stock_picking_id_fkey
-- ALTER TABLE public.purchase_order_stock_picking_rel
--     ADD CONSTRAINT purchase_order_stock_picking_rel_stock_picking_id_fkey
--     FOREIGN KEY (stock_picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE CASCADE;

-- FK: res_company.internal_transit_location_id -> stock_location.id
-- Original constraint: res_company_internal_transit_location_id_fkey
-- ALTER TABLE public.res_company
--     ADD CONSTRAINT res_company_internal_transit_location_id_fkey
--     FOREIGN KEY (internal_transit_location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: sale_order.warehouse_id -> stock_warehouse.id
-- Original constraint: sale_order_warehouse_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.warehouse_id -> stock_warehouse.id
-- Original constraint: sale_order_line_warehouse_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line_stock_route_rel.stock_route_id -> stock_route.id
-- Original constraint: sale_order_line_stock_route_rel_stock_route_id_fkey
-- ALTER TABLE public.sale_order_line_stock_route_rel
--     ADD CONSTRAINT sale_order_line_stock_route_rel_stock_route_id_fkey
--     FOREIGN KEY (stock_route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE RESTRICT;

-- FK: stock_backorder_confirmation.create_uid -> res_users.id
-- Original constraint: stock_backorder_confirmation_create_uid_fkey
-- ALTER TABLE public.stock_backorder_confirmation
--     ADD CONSTRAINT stock_backorder_confirmation_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_backorder_confirmation.write_uid -> res_users.id
-- Original constraint: stock_backorder_confirmation_write_uid_fkey
-- ALTER TABLE public.stock_backorder_confirmation
--     ADD CONSTRAINT stock_backorder_confirmation_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_backorder_confirmation_line.backorder_confirmation_id -> stock_backorder_confirmation.id
-- Original constraint: stock_backorder_confirmation_lin_backorder_confirmation_id_fkey
-- ALTER TABLE public.stock_backorder_confirmation_line
--     ADD CONSTRAINT stock_backorder_confirmation_lin_backorder_confirmation_id_fkey
--     FOREIGN KEY (backorder_confirmation_id)
--     REFERENCES public.stock_backorder_confirmation(id)
--     ON DELETE SET NULL;

-- FK: stock_backorder_confirmation_line.create_uid -> res_users.id
-- Original constraint: stock_backorder_confirmation_line_create_uid_fkey
-- ALTER TABLE public.stock_backorder_confirmation_line
--     ADD CONSTRAINT stock_backorder_confirmation_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_backorder_confirmation_line.picking_id -> stock_picking.id
-- Original constraint: stock_backorder_confirmation_line_picking_id_fkey
-- ALTER TABLE public.stock_backorder_confirmation_line
--     ADD CONSTRAINT stock_backorder_confirmation_line_picking_id_fkey
--     FOREIGN KEY (picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_backorder_confirmation_line.write_uid -> res_users.id
-- Original constraint: stock_backorder_confirmation_line_write_uid_fkey
-- ALTER TABLE public.stock_backorder_confirmation_line
--     ADD CONSTRAINT stock_backorder_confirmation_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_conflict_quant_rel.stock_inventory_conflict_id -> stock_inventory_conflict.id
-- Original constraint: stock_conflict_quant_rel_stock_inventory_conflict_id_fkey
-- ALTER TABLE public.stock_conflict_quant_rel
--     ADD CONSTRAINT stock_conflict_quant_rel_stock_inventory_conflict_id_fkey
--     FOREIGN KEY (stock_inventory_conflict_id)
--     REFERENCES public.stock_inventory_conflict(id)
--     ON DELETE CASCADE;

-- FK: stock_conflict_quant_rel.stock_quant_id -> stock_quant.id
-- Original constraint: stock_conflict_quant_rel_stock_quant_id_fkey
-- ALTER TABLE public.stock_conflict_quant_rel
--     ADD CONSTRAINT stock_conflict_quant_rel_stock_quant_id_fkey
--     FOREIGN KEY (stock_quant_id)
--     REFERENCES public.stock_quant(id)
--     ON DELETE CASCADE;

-- FK: stock_inventory_adjustment_name.create_uid -> res_users.id
-- Original constraint: stock_inventory_adjustment_name_create_uid_fkey
-- ALTER TABLE public.stock_inventory_adjustment_name
--     ADD CONSTRAINT stock_inventory_adjustment_name_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_inventory_adjustment_name.write_uid -> res_users.id
-- Original constraint: stock_inventory_adjustment_name_write_uid_fkey
-- ALTER TABLE public.stock_inventory_adjustment_name
--     ADD CONSTRAINT stock_inventory_adjustment_name_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_inventory_adjustment_name_stock_quant_rel.stock_inventory_adjustment_name_id -> stock_inventory_adjustment_name.id
-- Original constraint: stock_inventory_adjustment_na_stock_inventory_adjustment_n_fkey
-- ALTER TABLE public.stock_inventory_adjustment_name_stock_quant_rel
--     ADD CONSTRAINT stock_inventory_adjustment_na_stock_inventory_adjustment_n_fkey
--     FOREIGN KEY (stock_inventory_adjustment_name_id)
--     REFERENCES public.stock_inventory_adjustment_name(id)
--     ON DELETE CASCADE;

-- FK: stock_inventory_adjustment_name_stock_quant_rel.stock_quant_id -> stock_quant.id
-- Original constraint: stock_inventory_adjustment_name_stock_quant_stock_quant_id_fkey
-- ALTER TABLE public.stock_inventory_adjustment_name_stock_quant_rel
--     ADD CONSTRAINT stock_inventory_adjustment_name_stock_quant_stock_quant_id_fkey
--     FOREIGN KEY (stock_quant_id)
--     REFERENCES public.stock_quant(id)
--     ON DELETE CASCADE;

-- FK: stock_inventory_conflict.create_uid -> res_users.id
-- Original constraint: stock_inventory_conflict_create_uid_fkey
-- ALTER TABLE public.stock_inventory_conflict
--     ADD CONSTRAINT stock_inventory_conflict_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_inventory_conflict.write_uid -> res_users.id
-- Original constraint: stock_inventory_conflict_write_uid_fkey
-- ALTER TABLE public.stock_inventory_conflict
--     ADD CONSTRAINT stock_inventory_conflict_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_inventory_conflict_stock_quant_rel.stock_quant_id -> stock_quant.id
-- Original constraint: stock_inventory_conflict_stock_quant_rel_stock_quant_id_fkey
-- ALTER TABLE public.stock_inventory_conflict_stock_quant_rel
--     ADD CONSTRAINT stock_inventory_conflict_stock_quant_rel_stock_quant_id_fkey
--     FOREIGN KEY (stock_quant_id)
--     REFERENCES public.stock_quant(id)
--     ON DELETE CASCADE;

-- FK: stock_inventory_conflict_stock_quant_rel.stock_inventory_conflict_id -> stock_inventory_conflict.id
-- Original constraint: stock_inventory_conflict_stock_stock_inventory_conflict_id_fkey
-- ALTER TABLE public.stock_inventory_conflict_stock_quant_rel
--     ADD CONSTRAINT stock_inventory_conflict_stock_stock_inventory_conflict_id_fkey
--     FOREIGN KEY (stock_inventory_conflict_id)
--     REFERENCES public.stock_inventory_conflict(id)
--     ON DELETE CASCADE;

-- FK: stock_inventory_warning.create_uid -> res_users.id
-- Original constraint: stock_inventory_warning_create_uid_fkey
-- ALTER TABLE public.stock_inventory_warning
--     ADD CONSTRAINT stock_inventory_warning_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_inventory_warning.write_uid -> res_users.id
-- Original constraint: stock_inventory_warning_write_uid_fkey
-- ALTER TABLE public.stock_inventory_warning
--     ADD CONSTRAINT stock_inventory_warning_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_inventory_warning_stock_quant_rel.stock_inventory_warning_id -> stock_inventory_warning.id
-- Original constraint: stock_inventory_warning_stock_q_stock_inventory_warning_id_fkey
-- ALTER TABLE public.stock_inventory_warning_stock_quant_rel
--     ADD CONSTRAINT stock_inventory_warning_stock_q_stock_inventory_warning_id_fkey
--     FOREIGN KEY (stock_inventory_warning_id)
--     REFERENCES public.stock_inventory_warning(id)
--     ON DELETE CASCADE;

-- FK: stock_inventory_warning_stock_quant_rel.stock_quant_id -> stock_quant.id
-- Original constraint: stock_inventory_warning_stock_quant_rel_stock_quant_id_fkey
-- ALTER TABLE public.stock_inventory_warning_stock_quant_rel
--     ADD CONSTRAINT stock_inventory_warning_stock_quant_rel_stock_quant_id_fkey
--     FOREIGN KEY (stock_quant_id)
--     REFERENCES public.stock_quant(id)
--     ON DELETE CASCADE;

-- FK: stock_location.company_id -> res_company.id
-- Original constraint: stock_location_company_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_location.create_uid -> res_users.id
-- Original constraint: stock_location_create_uid_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_location.location_id -> stock_location.id
-- Original constraint: stock_location_location_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_location.removal_strategy_id -> product_removal.id
-- Original constraint: stock_location_removal_strategy_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_removal_strategy_id_fkey
--     FOREIGN KEY (removal_strategy_id)
--     REFERENCES public.product_removal(id)
--     ON DELETE SET NULL;

-- FK: stock_location.storage_category_id -> stock_storage_category.id
-- Original constraint: stock_location_storage_category_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_storage_category_id_fkey
--     FOREIGN KEY (storage_category_id)
--     REFERENCES public.stock_storage_category(id)
--     ON DELETE SET NULL;

-- FK: stock_location.valuation_account_id -> account_account.id
-- Original constraint: stock_location_valuation_account_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_valuation_account_id_fkey
--     FOREIGN KEY (valuation_account_id)
--     REFERENCES public.account_account(id)
--     ON DELETE SET NULL;

-- FK: stock_location.warehouse_id -> stock_warehouse.id
-- Original constraint: stock_location_warehouse_id_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: stock_location.write_uid -> res_users.id
-- Original constraint: stock_location_write_uid_fkey
-- ALTER TABLE public.stock_location
--     ADD CONSTRAINT stock_location_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_lot.company_id -> res_company.id
-- Original constraint: stock_lot_company_id_fkey
-- ALTER TABLE public.stock_lot
--     ADD CONSTRAINT stock_lot_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_lot.create_uid -> res_users.id
-- Original constraint: stock_lot_create_uid_fkey
-- ALTER TABLE public.stock_lot
--     ADD CONSTRAINT stock_lot_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_lot.location_id -> stock_location.id
-- Original constraint: stock_lot_location_id_fkey
-- ALTER TABLE public.stock_lot
--     ADD CONSTRAINT stock_lot_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_lot.product_id -> product_product.id
-- Original constraint: stock_lot_product_id_fkey
-- ALTER TABLE public.stock_lot
--     ADD CONSTRAINT stock_lot_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_lot.write_uid -> res_users.id
-- Original constraint: stock_lot_write_uid_fkey
-- ALTER TABLE public.stock_lot
--     ADD CONSTRAINT stock_lot_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_move.account_move_id -> account_move.id
-- Original constraint: stock_move_account_move_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_account_move_id_fkey
--     FOREIGN KEY (account_move_id)
--     REFERENCES public.account_move(id)
--     ON DELETE SET NULL;

-- FK: stock_move.company_id -> res_company.id
-- Original constraint: stock_move_company_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.create_uid -> res_users.id
-- Original constraint: stock_move_create_uid_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_move.location_dest_id -> stock_location.id
-- Original constraint: stock_move_location_dest_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.location_final_id -> stock_location.id
-- Original constraint: stock_move_location_final_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_location_final_id_fkey
--     FOREIGN KEY (location_final_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_move.location_id -> stock_location.id
-- Original constraint: stock_move_location_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.orderpoint_id -> stock_warehouse_orderpoint.id
-- Original constraint: stock_move_orderpoint_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_orderpoint_id_fkey
--     FOREIGN KEY (orderpoint_id)
--     REFERENCES public.stock_warehouse_orderpoint(id)
--     ON DELETE SET NULL;

-- FK: stock_move.origin_returned_move_id -> stock_move.id
-- Original constraint: stock_move_origin_returned_move_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_origin_returned_move_id_fkey
--     FOREIGN KEY (origin_returned_move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE SET NULL;

-- FK: stock_move.packaging_uom_id -> uom_uom.id
-- Original constraint: stock_move_packaging_uom_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_packaging_uom_id_fkey
--     FOREIGN KEY (packaging_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE SET NULL;

-- FK: stock_move.partner_id -> res_partner.id
-- Original constraint: stock_move_partner_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_move.picking_id -> stock_picking.id
-- Original constraint: stock_move_picking_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_picking_id_fkey
--     FOREIGN KEY (picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_move.picking_type_id -> stock_picking_type.id
-- Original constraint: stock_move_picking_type_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_picking_type_id_fkey
--     FOREIGN KEY (picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_move.product_id -> product_product.id
-- Original constraint: stock_move_product_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.product_uom -> uom_uom.id
-- Original constraint: stock_move_product_uom_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_product_uom_fkey
--     FOREIGN KEY (product_uom)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.purchase_line_id -> purchase_order_line.id
-- Original constraint: stock_move_purchase_line_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_purchase_line_id_fkey
--     FOREIGN KEY (purchase_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE SET NULL;

-- FK: stock_move.restrict_partner_id -> res_partner.id
-- Original constraint: stock_move_restrict_partner_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_restrict_partner_id_fkey
--     FOREIGN KEY (restrict_partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_move.rule_id -> stock_rule.id
-- Original constraint: stock_move_rule_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_rule_id_fkey
--     FOREIGN KEY (rule_id)
--     REFERENCES public.stock_rule(id)
--     ON DELETE RESTRICT;

-- FK: stock_move.sale_line_id -> sale_order_line.id
-- Original constraint: stock_move_sale_line_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_sale_line_id_fkey
--     FOREIGN KEY (sale_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE SET NULL;

-- FK: stock_move.scrap_id -> stock_scrap.id
-- Original constraint: stock_move_scrap_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_scrap_id_fkey
--     FOREIGN KEY (scrap_id)
--     REFERENCES public.stock_scrap(id)
--     ON DELETE SET NULL;

-- FK: stock_move.warehouse_id -> stock_warehouse.id
-- Original constraint: stock_move_warehouse_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: stock_move.write_uid -> res_users.id
-- Original constraint: stock_move_write_uid_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_move_created_purchase_line_rel.created_purchase_line_id -> purchase_order_line.id
-- Original constraint: stock_move_created_purchase_line__created_purchase_line_id_fkey
-- ALTER TABLE public.stock_move_created_purchase_line_rel
--     ADD CONSTRAINT stock_move_created_purchase_line__created_purchase_line_id_fkey
--     FOREIGN KEY (created_purchase_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE CASCADE;

-- FK: stock_move_created_purchase_line_rel.move_id -> stock_move.id
-- Original constraint: stock_move_created_purchase_line_rel_move_id_fkey
-- ALTER TABLE public.stock_move_created_purchase_line_rel
--     ADD CONSTRAINT stock_move_created_purchase_line_rel_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: stock_move_line.company_id -> res_company.id
-- Original constraint: stock_move_line_company_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.create_uid -> res_users.id
-- Original constraint: stock_move_line_create_uid_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line.location_dest_id -> stock_location.id
-- Original constraint: stock_move_line_location_dest_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.location_id -> stock_location.id
-- Original constraint: stock_move_line_location_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.lot_id -> stock_lot.id
-- Original constraint: stock_move_line_lot_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_lot_id_fkey
--     FOREIGN KEY (lot_id)
--     REFERENCES public.stock_lot(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line.move_id -> stock_move.id
-- Original constraint: stock_move_line_move_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line.owner_id -> res_partner.id
-- Original constraint: stock_move_line_owner_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_owner_id_fkey
--     FOREIGN KEY (owner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line.package_history_id -> stock_package_history.id
-- Original constraint: stock_move_line_package_history_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_package_history_id_fkey
--     FOREIGN KEY (package_history_id)
--     REFERENCES public.stock_package_history(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line.package_id -> stock_package.id
-- Original constraint: stock_move_line_package_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_package_id_fkey
--     FOREIGN KEY (package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.picking_id -> stock_picking.id
-- Original constraint: stock_move_line_picking_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_picking_id_fkey
--     FOREIGN KEY (picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line.product_id -> product_product.id
-- Original constraint: stock_move_line_product_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_move_line.product_uom_id -> uom_uom.id
-- Original constraint: stock_move_line_product_uom_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.result_package_id -> stock_package.id
-- Original constraint: stock_move_line_result_package_id_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_result_package_id_fkey
--     FOREIGN KEY (result_package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE RESTRICT;

-- FK: stock_move_line.write_uid -> res_users.id
-- Original constraint: stock_move_line_write_uid_fkey
-- ALTER TABLE public.stock_move_line
--     ADD CONSTRAINT stock_move_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_move_line_consume_rel.consume_line_id -> stock_move_line.id
-- Original constraint: stock_move_line_consume_rel_consume_line_id_fkey
-- ALTER TABLE public.stock_move_line_consume_rel
--     ADD CONSTRAINT stock_move_line_consume_rel_consume_line_id_fkey
--     FOREIGN KEY (consume_line_id)
--     REFERENCES public.stock_move_line(id)
--     ON DELETE CASCADE;

-- FK: stock_move_line_consume_rel.produce_line_id -> stock_move_line.id
-- Original constraint: stock_move_line_consume_rel_produce_line_id_fkey
-- ALTER TABLE public.stock_move_line_consume_rel
--     ADD CONSTRAINT stock_move_line_consume_rel_produce_line_id_fkey
--     FOREIGN KEY (produce_line_id)
--     REFERENCES public.stock_move_line(id)
--     ON DELETE CASCADE;

-- FK: stock_move_line_stock_put_in_pack_rel.stock_move_line_id -> stock_move_line.id
-- Original constraint: stock_move_line_stock_put_in_pack_rel_stock_move_line_id_fkey
-- ALTER TABLE public.stock_move_line_stock_put_in_pack_rel
--     ADD CONSTRAINT stock_move_line_stock_put_in_pack_rel_stock_move_line_id_fkey
--     FOREIGN KEY (stock_move_line_id)
--     REFERENCES public.stock_move_line(id)
--     ON DELETE CASCADE;

-- FK: stock_move_line_stock_put_in_pack_rel.stock_put_in_pack_id -> stock_put_in_pack.id
-- Original constraint: stock_move_line_stock_put_in_pack_rel_stock_put_in_pack_id_fkey
-- ALTER TABLE public.stock_move_line_stock_put_in_pack_rel
--     ADD CONSTRAINT stock_move_line_stock_put_in_pack_rel_stock_put_in_pack_id_fkey
--     FOREIGN KEY (stock_put_in_pack_id)
--     REFERENCES public.stock_put_in_pack(id)
--     ON DELETE CASCADE;

-- FK: stock_move_move_rel.move_dest_id -> stock_move.id
-- Original constraint: stock_move_move_rel_move_dest_id_fkey
-- ALTER TABLE public.stock_move_move_rel
--     ADD CONSTRAINT stock_move_move_rel_move_dest_id_fkey
--     FOREIGN KEY (move_dest_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: stock_move_move_rel.move_orig_id -> stock_move.id
-- Original constraint: stock_move_move_rel_move_orig_id_fkey
-- ALTER TABLE public.stock_move_move_rel
--     ADD CONSTRAINT stock_move_move_rel_move_orig_id_fkey
--     FOREIGN KEY (move_orig_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: stock_orderpoint_snooze.create_uid -> res_users.id
-- Original constraint: stock_orderpoint_snooze_create_uid_fkey
-- ALTER TABLE public.stock_orderpoint_snooze
--     ADD CONSTRAINT stock_orderpoint_snooze_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_orderpoint_snooze.write_uid -> res_users.id
-- Original constraint: stock_orderpoint_snooze_write_uid_fkey
-- ALTER TABLE public.stock_orderpoint_snooze
--     ADD CONSTRAINT stock_orderpoint_snooze_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_orderpoint_snooze_stock_warehouse_orderpoint_rel.stock_warehouse_orderpoint_id -> stock_warehouse_orderpoint.id
-- Original constraint: stock_orderpoint_snooze_stock_stock_warehouse_orderpoint_i_fkey
-- ALTER TABLE public.stock_orderpoint_snooze_stock_warehouse_orderpoint_rel
--     ADD CONSTRAINT stock_orderpoint_snooze_stock_stock_warehouse_orderpoint_i_fkey
--     FOREIGN KEY (stock_warehouse_orderpoint_id)
--     REFERENCES public.stock_warehouse_orderpoint(id)
--     ON DELETE CASCADE;

-- FK: stock_orderpoint_snooze_stock_warehouse_orderpoint_rel.stock_orderpoint_snooze_id -> stock_orderpoint_snooze.id
-- Original constraint: stock_orderpoint_snooze_stock_w_stock_orderpoint_snooze_id_fkey
-- ALTER TABLE public.stock_orderpoint_snooze_stock_warehouse_orderpoint_rel
--     ADD CONSTRAINT stock_orderpoint_snooze_stock_w_stock_orderpoint_snooze_id_fkey
--     FOREIGN KEY (stock_orderpoint_snooze_id)
--     REFERENCES public.stock_orderpoint_snooze(id)
--     ON DELETE CASCADE;

-- FK: stock_package.company_id -> res_company.id
-- Original constraint: stock_package_company_id_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_package.create_uid -> res_users.id
-- Original constraint: stock_package_create_uid_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package.location_id -> stock_location.id
-- Original constraint: stock_package_location_id_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_package.package_dest_id -> stock_package.id
-- Original constraint: stock_package_package_dest_id_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_package_dest_id_fkey
--     FOREIGN KEY (package_dest_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_package.package_type_id -> stock_package_type.id
-- Original constraint: stock_package_package_type_id_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_package_type_id_fkey
--     FOREIGN KEY (package_type_id)
--     REFERENCES public.stock_package_type(id)
--     ON DELETE SET NULL;

-- FK: stock_package.parent_package_id -> stock_package.id
-- Original constraint: stock_package_parent_package_id_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_parent_package_id_fkey
--     FOREIGN KEY (parent_package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_package.write_uid -> res_users.id
-- Original constraint: stock_package_write_uid_fkey
-- ALTER TABLE public.stock_package
--     ADD CONSTRAINT stock_package_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_destination.create_uid -> res_users.id
-- Original constraint: stock_package_destination_create_uid_fkey
-- ALTER TABLE public.stock_package_destination
--     ADD CONSTRAINT stock_package_destination_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_destination.location_dest_id -> stock_location.id
-- Original constraint: stock_package_destination_location_dest_id_fkey
-- ALTER TABLE public.stock_package_destination
--     ADD CONSTRAINT stock_package_destination_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE CASCADE;

-- FK: stock_package_destination.write_uid -> res_users.id
-- Original constraint: stock_package_destination_write_uid_fkey
-- ALTER TABLE public.stock_package_destination
--     ADD CONSTRAINT stock_package_destination_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.company_id -> res_company.id
-- Original constraint: stock_package_history_company_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_package_history.create_uid -> res_users.id
-- Original constraint: stock_package_history_create_uid_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.location_dest_id -> stock_location.id
-- Original constraint: stock_package_history_location_dest_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.location_id -> stock_location.id
-- Original constraint: stock_package_history_location_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.outermost_dest_id -> stock_package.id
-- Original constraint: stock_package_history_outermost_dest_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_outermost_dest_id_fkey
--     FOREIGN KEY (outermost_dest_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.package_id -> stock_package.id
-- Original constraint: stock_package_history_package_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_package_id_fkey
--     FOREIGN KEY (package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE CASCADE;

-- FK: stock_package_history.parent_dest_id -> stock_package.id
-- Original constraint: stock_package_history_parent_dest_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_parent_dest_id_fkey
--     FOREIGN KEY (parent_dest_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.parent_orig_id -> stock_package.id
-- Original constraint: stock_package_history_parent_orig_id_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_parent_orig_id_fkey
--     FOREIGN KEY (parent_orig_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history.write_uid -> res_users.id
-- Original constraint: stock_package_history_write_uid_fkey
-- ALTER TABLE public.stock_package_history
--     ADD CONSTRAINT stock_package_history_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_history_stock_picking_rel.stock_package_history_id -> stock_package_history.id
-- Original constraint: stock_package_history_stock_picki_stock_package_history_id_fkey
-- ALTER TABLE public.stock_package_history_stock_picking_rel
--     ADD CONSTRAINT stock_package_history_stock_picki_stock_package_history_id_fkey
--     FOREIGN KEY (stock_package_history_id)
--     REFERENCES public.stock_package_history(id)
--     ON DELETE CASCADE;

-- FK: stock_package_history_stock_picking_rel.stock_picking_id -> stock_picking.id
-- Original constraint: stock_package_history_stock_picking_rel_stock_picking_id_fkey
-- ALTER TABLE public.stock_package_history_stock_picking_rel
--     ADD CONSTRAINT stock_package_history_stock_picking_rel_stock_picking_id_fkey
--     FOREIGN KEY (stock_picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE CASCADE;

-- FK: stock_package_stock_put_in_pack_rel.stock_package_id -> stock_package.id
-- Original constraint: stock_package_stock_put_in_pack_rel_stock_package_id_fkey
-- ALTER TABLE public.stock_package_stock_put_in_pack_rel
--     ADD CONSTRAINT stock_package_stock_put_in_pack_rel_stock_package_id_fkey
--     FOREIGN KEY (stock_package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE CASCADE;

-- FK: stock_package_stock_put_in_pack_rel.stock_put_in_pack_id -> stock_put_in_pack.id
-- Original constraint: stock_package_stock_put_in_pack_rel_stock_put_in_pack_id_fkey
-- ALTER TABLE public.stock_package_stock_put_in_pack_rel
--     ADD CONSTRAINT stock_package_stock_put_in_pack_rel_stock_put_in_pack_id_fkey
--     FOREIGN KEY (stock_put_in_pack_id)
--     REFERENCES public.stock_put_in_pack(id)
--     ON DELETE CASCADE;

-- FK: stock_package_type.company_id -> res_company.id
-- Original constraint: stock_package_type_company_id_fkey
-- ALTER TABLE public.stock_package_type
--     ADD CONSTRAINT stock_package_type_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_package_type.create_uid -> res_users.id
-- Original constraint: stock_package_type_create_uid_fkey
-- ALTER TABLE public.stock_package_type
--     ADD CONSTRAINT stock_package_type_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_type.sequence_id -> ir_sequence.id
-- Original constraint: stock_package_type_sequence_id_fkey
-- ALTER TABLE public.stock_package_type
--     ADD CONSTRAINT stock_package_type_sequence_id_fkey
--     FOREIGN KEY (sequence_id)
--     REFERENCES public.ir_sequence(id)
--     ON DELETE SET NULL;

-- FK: stock_package_type.write_uid -> res_users.id
-- Original constraint: stock_package_type_write_uid_fkey
-- ALTER TABLE public.stock_package_type
--     ADD CONSTRAINT stock_package_type_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_package_type_stock_putaway_rule_rel.stock_package_type_id -> stock_package_type.id
-- Original constraint: stock_package_type_stock_putaway_rul_stock_package_type_id_fkey
-- ALTER TABLE public.stock_package_type_stock_putaway_rule_rel
--     ADD CONSTRAINT stock_package_type_stock_putaway_rul_stock_package_type_id_fkey
--     FOREIGN KEY (stock_package_type_id)
--     REFERENCES public.stock_package_type(id)
--     ON DELETE CASCADE;

-- FK: stock_package_type_stock_putaway_rule_rel.stock_putaway_rule_id -> stock_putaway_rule.id
-- Original constraint: stock_package_type_stock_putaway_rul_stock_putaway_rule_id_fkey
-- ALTER TABLE public.stock_package_type_stock_putaway_rule_rel
--     ADD CONSTRAINT stock_package_type_stock_putaway_rul_stock_putaway_rule_id_fkey
--     FOREIGN KEY (stock_putaway_rule_id)
--     REFERENCES public.stock_putaway_rule(id)
--     ON DELETE CASCADE;

-- FK: stock_package_type_stock_route_rel.stock_package_type_id -> stock_package_type.id
-- Original constraint: stock_package_type_stock_route_rel_stock_package_type_id_fkey
-- ALTER TABLE public.stock_package_type_stock_route_rel
--     ADD CONSTRAINT stock_package_type_stock_route_rel_stock_package_type_id_fkey
--     FOREIGN KEY (stock_package_type_id)
--     REFERENCES public.stock_package_type(id)
--     ON DELETE CASCADE;

-- FK: stock_package_type_stock_route_rel.stock_route_id -> stock_route.id
-- Original constraint: stock_package_type_stock_route_rel_stock_route_id_fkey
-- ALTER TABLE public.stock_package_type_stock_route_rel
--     ADD CONSTRAINT stock_package_type_stock_route_rel_stock_route_id_fkey
--     FOREIGN KEY (stock_route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_picking.backorder_id -> stock_picking.id
-- Original constraint: stock_picking_backorder_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_backorder_id_fkey
--     FOREIGN KEY (backorder_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.company_id -> res_company.id
-- Original constraint: stock_picking_company_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.create_uid -> res_users.id
-- Original constraint: stock_picking_create_uid_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.location_dest_id -> stock_location.id
-- Original constraint: stock_picking_location_dest_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_picking.location_id -> stock_location.id
-- Original constraint: stock_picking_location_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_picking.owner_id -> res_partner.id
-- Original constraint: stock_picking_owner_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_owner_id_fkey
--     FOREIGN KEY (owner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.partner_id -> res_partner.id
-- Original constraint: stock_picking_partner_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.picking_type_id -> stock_picking_type.id
-- Original constraint: stock_picking_picking_type_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_picking_type_id_fkey
--     FOREIGN KEY (picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE RESTRICT;

-- FK: stock_picking.return_id -> stock_picking.id
-- Original constraint: stock_picking_return_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_return_id_fkey
--     FOREIGN KEY (return_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.sale_id -> sale_order.id
-- Original constraint: stock_picking_sale_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_sale_id_fkey
--     FOREIGN KEY (sale_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.user_id -> res_users.id
-- Original constraint: stock_picking_user_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_user_id_fkey
--     FOREIGN KEY (user_id)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.write_uid -> res_users.id
-- Original constraint: stock_picking_write_uid_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_picking_backorder_rel.stock_backorder_confirmation_id -> stock_backorder_confirmation.id
-- Original constraint: stock_picking_backorder_rel_stock_backorder_confirmation_i_fkey
-- ALTER TABLE public.stock_picking_backorder_rel
--     ADD CONSTRAINT stock_picking_backorder_rel_stock_backorder_confirmation_i_fkey
--     FOREIGN KEY (stock_backorder_confirmation_id)
--     REFERENCES public.stock_backorder_confirmation(id)
--     ON DELETE CASCADE;

-- FK: stock_picking_backorder_rel.stock_picking_id -> stock_picking.id
-- Original constraint: stock_picking_backorder_rel_stock_picking_id_fkey
-- ALTER TABLE public.stock_picking_backorder_rel
--     ADD CONSTRAINT stock_picking_backorder_rel_stock_picking_id_fkey
--     FOREIGN KEY (stock_picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE CASCADE;

-- FK: stock_picking_sms_rel.confirm_stock_sms_id -> confirm_stock_sms.id
-- Original constraint: stock_picking_sms_rel_confirm_stock_sms_id_fkey
-- ALTER TABLE public.stock_picking_sms_rel
--     ADD CONSTRAINT stock_picking_sms_rel_confirm_stock_sms_id_fkey
--     FOREIGN KEY (confirm_stock_sms_id)
--     REFERENCES public.confirm_stock_sms(id)
--     ON DELETE CASCADE;

-- FK: stock_picking_sms_rel.stock_picking_id -> stock_picking.id
-- Original constraint: stock_picking_sms_rel_stock_picking_id_fkey
-- ALTER TABLE public.stock_picking_sms_rel
--     ADD CONSTRAINT stock_picking_sms_rel_stock_picking_id_fkey
--     FOREIGN KEY (stock_picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE CASCADE;

-- FK: stock_picking_type.company_id -> res_company.id
-- Original constraint: stock_picking_type_company_id_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_picking_type.create_uid -> res_users.id
-- Original constraint: stock_picking_type_create_uid_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_picking_type.default_location_dest_id -> stock_location.id
-- Original constraint: stock_picking_type_default_location_dest_id_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_default_location_dest_id_fkey
--     FOREIGN KEY (default_location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_picking_type.default_location_src_id -> stock_location.id
-- Original constraint: stock_picking_type_default_location_src_id_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_default_location_src_id_fkey
--     FOREIGN KEY (default_location_src_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_picking_type.return_picking_type_id -> stock_picking_type.id
-- Original constraint: stock_picking_type_return_picking_type_id_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_return_picking_type_id_fkey
--     FOREIGN KEY (return_picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_picking_type.sequence_id -> ir_sequence.id
-- Original constraint: stock_picking_type_sequence_id_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_sequence_id_fkey
--     FOREIGN KEY (sequence_id)
--     REFERENCES public.ir_sequence(id)
--     ON DELETE SET NULL;

-- FK: stock_picking_type.warehouse_id -> stock_warehouse.id
-- Original constraint: stock_picking_type_warehouse_id_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: stock_picking_type.write_uid -> res_users.id
-- Original constraint: stock_picking_type_write_uid_fkey
-- ALTER TABLE public.stock_picking_type
--     ADD CONSTRAINT stock_picking_type_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_put_in_pack.create_uid -> res_users.id
-- Original constraint: stock_put_in_pack_create_uid_fkey
-- ALTER TABLE public.stock_put_in_pack
--     ADD CONSTRAINT stock_put_in_pack_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_put_in_pack.location_dest_id -> stock_location.id
-- Original constraint: stock_put_in_pack_location_dest_id_fkey
-- ALTER TABLE public.stock_put_in_pack
--     ADD CONSTRAINT stock_put_in_pack_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_put_in_pack.package_type_id -> stock_package_type.id
-- Original constraint: stock_put_in_pack_package_type_id_fkey
-- ALTER TABLE public.stock_put_in_pack
--     ADD CONSTRAINT stock_put_in_pack_package_type_id_fkey
--     FOREIGN KEY (package_type_id)
--     REFERENCES public.stock_package_type(id)
--     ON DELETE SET NULL;

-- FK: stock_put_in_pack.result_package_id -> stock_package.id
-- Original constraint: stock_put_in_pack_result_package_id_fkey
-- ALTER TABLE public.stock_put_in_pack
--     ADD CONSTRAINT stock_put_in_pack_result_package_id_fkey
--     FOREIGN KEY (result_package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_put_in_pack.write_uid -> res_users.id
-- Original constraint: stock_put_in_pack_write_uid_fkey
-- ALTER TABLE public.stock_put_in_pack
--     ADD CONSTRAINT stock_put_in_pack_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_putaway_rule.category_id -> product_category.id
-- Original constraint: stock_putaway_rule_category_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_category_id_fkey
--     FOREIGN KEY (category_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.company_id -> res_company.id
-- Original constraint: stock_putaway_rule_company_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_putaway_rule.create_uid -> res_users.id
-- Original constraint: stock_putaway_rule_create_uid_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_putaway_rule.location_in_id -> stock_location.id
-- Original constraint: stock_putaway_rule_location_in_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_location_in_id_fkey
--     FOREIGN KEY (location_in_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.location_out_id -> stock_location.id
-- Original constraint: stock_putaway_rule_location_out_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_location_out_id_fkey
--     FOREIGN KEY (location_out_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.product_id -> product_product.id
-- Original constraint: stock_putaway_rule_product_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.storage_category_id -> stock_storage_category.id
-- Original constraint: stock_putaway_rule_storage_category_id_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_storage_category_id_fkey
--     FOREIGN KEY (storage_category_id)
--     REFERENCES public.stock_storage_category(id)
--     ON DELETE CASCADE;

-- FK: stock_putaway_rule.write_uid -> res_users.id
-- Original constraint: stock_putaway_rule_write_uid_fkey
-- ALTER TABLE public.stock_putaway_rule
--     ADD CONSTRAINT stock_putaway_rule_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quant.company_id -> res_company.id
-- Original constraint: stock_quant_company_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_quant.create_uid -> res_users.id
-- Original constraint: stock_quant_create_uid_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quant.location_id -> stock_location.id
-- Original constraint: stock_quant_location_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_quant.lot_id -> stock_lot.id
-- Original constraint: stock_quant_lot_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_lot_id_fkey
--     FOREIGN KEY (lot_id)
--     REFERENCES public.stock_lot(id)
--     ON DELETE RESTRICT;

-- FK: stock_quant.owner_id -> res_partner.id
-- Original constraint: stock_quant_owner_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_owner_id_fkey
--     FOREIGN KEY (owner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_quant.package_id -> stock_package.id
-- Original constraint: stock_quant_package_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_package_id_fkey
--     FOREIGN KEY (package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE RESTRICT;

-- FK: stock_quant.product_id -> product_product.id
-- Original constraint: stock_quant_product_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_quant.user_id -> res_users.id
-- Original constraint: stock_quant_user_id_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_user_id_fkey
--     FOREIGN KEY (user_id)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quant.write_uid -> res_users.id
-- Original constraint: stock_quant_write_uid_fkey
-- ALTER TABLE public.stock_quant
--     ADD CONSTRAINT stock_quant_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quant_relocate.create_uid -> res_users.id
-- Original constraint: stock_quant_relocate_create_uid_fkey
-- ALTER TABLE public.stock_quant_relocate
--     ADD CONSTRAINT stock_quant_relocate_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quant_relocate.dest_location_id -> stock_location.id
-- Original constraint: stock_quant_relocate_dest_location_id_fkey
-- ALTER TABLE public.stock_quant_relocate
--     ADD CONSTRAINT stock_quant_relocate_dest_location_id_fkey
--     FOREIGN KEY (dest_location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_quant_relocate.dest_package_id -> stock_package.id
-- Original constraint: stock_quant_relocate_dest_package_id_fkey
-- ALTER TABLE public.stock_quant_relocate
--     ADD CONSTRAINT stock_quant_relocate_dest_package_id_fkey
--     FOREIGN KEY (dest_package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_quant_relocate.write_uid -> res_users.id
-- Original constraint: stock_quant_relocate_write_uid_fkey
-- ALTER TABLE public.stock_quant_relocate
--     ADD CONSTRAINT stock_quant_relocate_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quant_stock_quant_relocate_rel.stock_quant_relocate_id -> stock_quant_relocate.id
-- Original constraint: stock_quant_stock_quant_relocate_r_stock_quant_relocate_id_fkey
-- ALTER TABLE public.stock_quant_stock_quant_relocate_rel
--     ADD CONSTRAINT stock_quant_stock_quant_relocate_r_stock_quant_relocate_id_fkey
--     FOREIGN KEY (stock_quant_relocate_id)
--     REFERENCES public.stock_quant_relocate(id)
--     ON DELETE CASCADE;

-- FK: stock_quant_stock_quant_relocate_rel.stock_quant_id -> stock_quant.id
-- Original constraint: stock_quant_stock_quant_relocate_rel_stock_quant_id_fkey
-- ALTER TABLE public.stock_quant_stock_quant_relocate_rel
--     ADD CONSTRAINT stock_quant_stock_quant_relocate_rel_stock_quant_id_fkey
--     FOREIGN KEY (stock_quant_id)
--     REFERENCES public.stock_quant(id)
--     ON DELETE CASCADE;

-- FK: stock_quant_stock_request_count_rel.stock_quant_id -> stock_quant.id
-- Original constraint: stock_quant_stock_request_count_rel_stock_quant_id_fkey
-- ALTER TABLE public.stock_quant_stock_request_count_rel
--     ADD CONSTRAINT stock_quant_stock_request_count_rel_stock_quant_id_fkey
--     FOREIGN KEY (stock_quant_id)
--     REFERENCES public.stock_quant(id)
--     ON DELETE CASCADE;

-- FK: stock_quant_stock_request_count_rel.stock_request_count_id -> stock_request_count.id
-- Original constraint: stock_quant_stock_request_count_rel_stock_request_count_id_fkey
-- ALTER TABLE public.stock_quant_stock_request_count_rel
--     ADD CONSTRAINT stock_quant_stock_request_count_rel_stock_request_count_id_fkey
--     FOREIGN KEY (stock_request_count_id)
--     REFERENCES public.stock_request_count(id)
--     ON DELETE CASCADE;

-- FK: stock_quantity_history.create_uid -> res_users.id
-- Original constraint: stock_quantity_history_create_uid_fkey
-- ALTER TABLE public.stock_quantity_history
--     ADD CONSTRAINT stock_quantity_history_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_quantity_history.write_uid -> res_users.id
-- Original constraint: stock_quantity_history_write_uid_fkey
-- ALTER TABLE public.stock_quantity_history
--     ADD CONSTRAINT stock_quantity_history_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_reference.create_uid -> res_users.id
-- Original constraint: stock_reference_create_uid_fkey
-- ALTER TABLE public.stock_reference
--     ADD CONSTRAINT stock_reference_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_reference.write_uid -> res_users.id
-- Original constraint: stock_reference_write_uid_fkey
-- ALTER TABLE public.stock_reference
--     ADD CONSTRAINT stock_reference_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_reference_move_rel.move_id -> stock_move.id
-- Original constraint: stock_reference_move_rel_move_id_fkey
-- ALTER TABLE public.stock_reference_move_rel
--     ADD CONSTRAINT stock_reference_move_rel_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: stock_reference_move_rel.reference_id -> stock_reference.id
-- Original constraint: stock_reference_move_rel_reference_id_fkey
-- ALTER TABLE public.stock_reference_move_rel
--     ADD CONSTRAINT stock_reference_move_rel_reference_id_fkey
--     FOREIGN KEY (reference_id)
--     REFERENCES public.stock_reference(id)
--     ON DELETE CASCADE;

-- FK: stock_reference_purchase_rel.purchase_id -> purchase_order.id
-- Original constraint: stock_reference_purchase_rel_purchase_id_fkey
-- ALTER TABLE public.stock_reference_purchase_rel
--     ADD CONSTRAINT stock_reference_purchase_rel_purchase_id_fkey
--     FOREIGN KEY (purchase_id)
--     REFERENCES public.purchase_order(id)
--     ON DELETE CASCADE;

-- FK: stock_reference_purchase_rel.reference_id -> stock_reference.id
-- Original constraint: stock_reference_purchase_rel_reference_id_fkey
-- ALTER TABLE public.stock_reference_purchase_rel
--     ADD CONSTRAINT stock_reference_purchase_rel_reference_id_fkey
--     FOREIGN KEY (reference_id)
--     REFERENCES public.stock_reference(id)
--     ON DELETE CASCADE;

-- FK: stock_reference_sale_rel.reference_id -> stock_reference.id
-- Original constraint: stock_reference_sale_rel_reference_id_fkey
-- ALTER TABLE public.stock_reference_sale_rel
--     ADD CONSTRAINT stock_reference_sale_rel_reference_id_fkey
--     FOREIGN KEY (reference_id)
--     REFERENCES public.stock_reference(id)
--     ON DELETE CASCADE;

-- FK: stock_reference_sale_rel.sale_id -> sale_order.id
-- Original constraint: stock_reference_sale_rel_sale_id_fkey
-- ALTER TABLE public.stock_reference_sale_rel
--     ADD CONSTRAINT stock_reference_sale_rel_sale_id_fkey
--     FOREIGN KEY (sale_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: stock_replenishment_info.create_uid -> res_users.id
-- Original constraint: stock_replenishment_info_create_uid_fkey
-- ALTER TABLE public.stock_replenishment_info
--     ADD CONSTRAINT stock_replenishment_info_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_info.orderpoint_id -> stock_warehouse_orderpoint.id
-- Original constraint: stock_replenishment_info_orderpoint_id_fkey
-- ALTER TABLE public.stock_replenishment_info
--     ADD CONSTRAINT stock_replenishment_info_orderpoint_id_fkey
--     FOREIGN KEY (orderpoint_id)
--     REFERENCES public.stock_warehouse_orderpoint(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_info.write_uid -> res_users.id
-- Original constraint: stock_replenishment_info_write_uid_fkey
-- ALTER TABLE public.stock_replenishment_info
--     ADD CONSTRAINT stock_replenishment_info_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_option.create_uid -> res_users.id
-- Original constraint: stock_replenishment_option_create_uid_fkey
-- ALTER TABLE public.stock_replenishment_option
--     ADD CONSTRAINT stock_replenishment_option_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_option.product_id -> product_product.id
-- Original constraint: stock_replenishment_option_product_id_fkey
-- ALTER TABLE public.stock_replenishment_option
--     ADD CONSTRAINT stock_replenishment_option_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_option.replenishment_info_id -> stock_replenishment_info.id
-- Original constraint: stock_replenishment_option_replenishment_info_id_fkey
-- ALTER TABLE public.stock_replenishment_option
--     ADD CONSTRAINT stock_replenishment_option_replenishment_info_id_fkey
--     FOREIGN KEY (replenishment_info_id)
--     REFERENCES public.stock_replenishment_info(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_option.route_id -> stock_route.id
-- Original constraint: stock_replenishment_option_route_id_fkey
-- ALTER TABLE public.stock_replenishment_option
--     ADD CONSTRAINT stock_replenishment_option_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE SET NULL;

-- FK: stock_replenishment_option.write_uid -> res_users.id
-- Original constraint: stock_replenishment_option_write_uid_fkey
-- ALTER TABLE public.stock_replenishment_option
--     ADD CONSTRAINT stock_replenishment_option_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_request_count.create_uid -> res_users.id
-- Original constraint: stock_request_count_create_uid_fkey
-- ALTER TABLE public.stock_request_count
--     ADD CONSTRAINT stock_request_count_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_request_count.user_id -> res_users.id
-- Original constraint: stock_request_count_user_id_fkey
-- ALTER TABLE public.stock_request_count
--     ADD CONSTRAINT stock_request_count_user_id_fkey
--     FOREIGN KEY (user_id)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_request_count.write_uid -> res_users.id
-- Original constraint: stock_request_count_write_uid_fkey
-- ALTER TABLE public.stock_request_count
--     ADD CONSTRAINT stock_request_count_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking.create_uid -> res_users.id
-- Original constraint: stock_return_picking_create_uid_fkey
-- ALTER TABLE public.stock_return_picking
--     ADD CONSTRAINT stock_return_picking_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking.picking_id -> stock_picking.id
-- Original constraint: stock_return_picking_picking_id_fkey
-- ALTER TABLE public.stock_return_picking
--     ADD CONSTRAINT stock_return_picking_picking_id_fkey
--     FOREIGN KEY (picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking.write_uid -> res_users.id
-- Original constraint: stock_return_picking_write_uid_fkey
-- ALTER TABLE public.stock_return_picking
--     ADD CONSTRAINT stock_return_picking_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking_line.create_uid -> res_users.id
-- Original constraint: stock_return_picking_line_create_uid_fkey
-- ALTER TABLE public.stock_return_picking_line
--     ADD CONSTRAINT stock_return_picking_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking_line.move_id -> stock_move.id
-- Original constraint: stock_return_picking_line_move_id_fkey
-- ALTER TABLE public.stock_return_picking_line
--     ADD CONSTRAINT stock_return_picking_line_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking_line.product_id -> product_product.id
-- Original constraint: stock_return_picking_line_product_id_fkey
-- ALTER TABLE public.stock_return_picking_line
--     ADD CONSTRAINT stock_return_picking_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_return_picking_line.wizard_id -> stock_return_picking.id
-- Original constraint: stock_return_picking_line_wizard_id_fkey
-- ALTER TABLE public.stock_return_picking_line
--     ADD CONSTRAINT stock_return_picking_line_wizard_id_fkey
--     FOREIGN KEY (wizard_id)
--     REFERENCES public.stock_return_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_return_picking_line.write_uid -> res_users.id
-- Original constraint: stock_return_picking_line_write_uid_fkey
-- ALTER TABLE public.stock_return_picking_line
--     ADD CONSTRAINT stock_return_picking_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_route.company_id -> res_company.id
-- Original constraint: stock_route_company_id_fkey
-- ALTER TABLE public.stock_route
--     ADD CONSTRAINT stock_route_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_route.create_uid -> res_users.id
-- Original constraint: stock_route_create_uid_fkey
-- ALTER TABLE public.stock_route
--     ADD CONSTRAINT stock_route_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_route.supplied_wh_id -> stock_warehouse.id
-- Original constraint: stock_route_supplied_wh_id_fkey
-- ALTER TABLE public.stock_route
--     ADD CONSTRAINT stock_route_supplied_wh_id_fkey
--     FOREIGN KEY (supplied_wh_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: stock_route.supplier_wh_id -> stock_warehouse.id
-- Original constraint: stock_route_supplier_wh_id_fkey
-- ALTER TABLE public.stock_route
--     ADD CONSTRAINT stock_route_supplier_wh_id_fkey
--     FOREIGN KEY (supplier_wh_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: stock_route.write_uid -> res_users.id
-- Original constraint: stock_route_write_uid_fkey
-- ALTER TABLE public.stock_route
--     ADD CONSTRAINT stock_route_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_route_categ.categ_id -> product_category.id
-- Original constraint: stock_route_categ_categ_id_fkey
-- ALTER TABLE public.stock_route_categ
--     ADD CONSTRAINT stock_route_categ_categ_id_fkey
--     FOREIGN KEY (categ_id)
--     REFERENCES public.product_category(id)
--     ON DELETE CASCADE;

-- FK: stock_route_categ.route_id -> stock_route.id
-- Original constraint: stock_route_categ_route_id_fkey
-- ALTER TABLE public.stock_route_categ
--     ADD CONSTRAINT stock_route_categ_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_route_move.move_id -> stock_move.id
-- Original constraint: stock_route_move_move_id_fkey
-- ALTER TABLE public.stock_route_move
--     ADD CONSTRAINT stock_route_move_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: stock_route_move.route_id -> stock_route.id
-- Original constraint: stock_route_move_route_id_fkey
-- ALTER TABLE public.stock_route_move
--     ADD CONSTRAINT stock_route_move_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_route_product.product_id -> product_template.id
-- Original constraint: stock_route_product_product_id_fkey
-- ALTER TABLE public.stock_route_product
--     ADD CONSTRAINT stock_route_product_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: stock_route_product.route_id -> stock_route.id
-- Original constraint: stock_route_product_route_id_fkey
-- ALTER TABLE public.stock_route_product
--     ADD CONSTRAINT stock_route_product_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_route_stock_rules_report_rel.stock_route_id -> stock_route.id
-- Original constraint: stock_route_stock_rules_report_rel_stock_route_id_fkey
-- ALTER TABLE public.stock_route_stock_rules_report_rel
--     ADD CONSTRAINT stock_route_stock_rules_report_rel_stock_route_id_fkey
--     FOREIGN KEY (stock_route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_route_stock_rules_report_rel.stock_rules_report_id -> stock_rules_report.id
-- Original constraint: stock_route_stock_rules_report_rel_stock_rules_report_id_fkey
-- ALTER TABLE public.stock_route_stock_rules_report_rel
--     ADD CONSTRAINT stock_route_stock_rules_report_rel_stock_rules_report_id_fkey
--     FOREIGN KEY (stock_rules_report_id)
--     REFERENCES public.stock_rules_report(id)
--     ON DELETE CASCADE;

-- FK: stock_route_warehouse.route_id -> stock_route.id
-- Original constraint: stock_route_warehouse_route_id_fkey
-- ALTER TABLE public.stock_route_warehouse
--     ADD CONSTRAINT stock_route_warehouse_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_route_warehouse.warehouse_id -> stock_warehouse.id
-- Original constraint: stock_route_warehouse_warehouse_id_fkey
-- ALTER TABLE public.stock_route_warehouse
--     ADD CONSTRAINT stock_route_warehouse_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: stock_rule.company_id -> res_company.id
-- Original constraint: stock_rule_company_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_rule.create_uid -> res_users.id
-- Original constraint: stock_rule_create_uid_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_rule.location_dest_id -> stock_location.id
-- Original constraint: stock_rule_location_dest_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_location_dest_id_fkey
--     FOREIGN KEY (location_dest_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_rule.location_src_id -> stock_location.id
-- Original constraint: stock_rule_location_src_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_location_src_id_fkey
--     FOREIGN KEY (location_src_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_rule.partner_address_id -> res_partner.id
-- Original constraint: stock_rule_partner_address_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_partner_address_id_fkey
--     FOREIGN KEY (partner_address_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_rule.picking_type_id -> stock_picking_type.id
-- Original constraint: stock_rule_picking_type_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_picking_type_id_fkey
--     FOREIGN KEY (picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE RESTRICT;

-- FK: stock_rule.route_id -> stock_route.id
-- Original constraint: stock_rule_route_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE CASCADE;

-- FK: stock_rule.warehouse_id -> stock_warehouse.id
-- Original constraint: stock_rule_warehouse_id_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: stock_rule.write_uid -> res_users.id
-- Original constraint: stock_rule_write_uid_fkey
-- ALTER TABLE public.stock_rule
--     ADD CONSTRAINT stock_rule_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_rules_report.create_uid -> res_users.id
-- Original constraint: stock_rules_report_create_uid_fkey
-- ALTER TABLE public.stock_rules_report
--     ADD CONSTRAINT stock_rules_report_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_rules_report.product_id -> product_product.id
-- Original constraint: stock_rules_report_product_id_fkey
-- ALTER TABLE public.stock_rules_report
--     ADD CONSTRAINT stock_rules_report_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_rules_report.product_tmpl_id -> product_template.id
-- Original constraint: stock_rules_report_product_tmpl_id_fkey
-- ALTER TABLE public.stock_rules_report
--     ADD CONSTRAINT stock_rules_report_product_tmpl_id_fkey
--     FOREIGN KEY (product_tmpl_id)
--     REFERENCES public.product_template(id)
--     ON DELETE CASCADE;

-- FK: stock_rules_report.write_uid -> res_users.id
-- Original constraint: stock_rules_report_write_uid_fkey
-- ALTER TABLE public.stock_rules_report
--     ADD CONSTRAINT stock_rules_report_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_rules_report_stock_warehouse_rel.stock_rules_report_id -> stock_rules_report.id
-- Original constraint: stock_rules_report_stock_warehouse_r_stock_rules_report_id_fkey
-- ALTER TABLE public.stock_rules_report_stock_warehouse_rel
--     ADD CONSTRAINT stock_rules_report_stock_warehouse_r_stock_rules_report_id_fkey
--     FOREIGN KEY (stock_rules_report_id)
--     REFERENCES public.stock_rules_report(id)
--     ON DELETE CASCADE;

-- FK: stock_rules_report_stock_warehouse_rel.stock_warehouse_id -> stock_warehouse.id
-- Original constraint: stock_rules_report_stock_warehouse_rel_stock_warehouse_id_fkey
-- ALTER TABLE public.stock_rules_report_stock_warehouse_rel
--     ADD CONSTRAINT stock_rules_report_stock_warehouse_rel_stock_warehouse_id_fkey
--     FOREIGN KEY (stock_warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: stock_scrap.company_id -> res_company.id
-- Original constraint: stock_scrap_company_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_scrap.create_uid -> res_users.id
-- Original constraint: stock_scrap_create_uid_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap.location_id -> stock_location.id
-- Original constraint: stock_scrap_location_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_scrap.lot_id -> stock_lot.id
-- Original constraint: stock_scrap_lot_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_lot_id_fkey
--     FOREIGN KEY (lot_id)
--     REFERENCES public.stock_lot(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap.owner_id -> res_partner.id
-- Original constraint: stock_scrap_owner_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_owner_id_fkey
--     FOREIGN KEY (owner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap.package_id -> stock_package.id
-- Original constraint: stock_scrap_package_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_package_id_fkey
--     FOREIGN KEY (package_id)
--     REFERENCES public.stock_package(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap.picking_id -> stock_picking.id
-- Original constraint: stock_scrap_picking_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_picking_id_fkey
--     FOREIGN KEY (picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap.product_id -> product_product.id
-- Original constraint: stock_scrap_product_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: stock_scrap.product_uom_id -> uom_uom.id
-- Original constraint: stock_scrap_product_uom_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: stock_scrap.scrap_location_id -> stock_location.id
-- Original constraint: stock_scrap_scrap_location_id_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_scrap_location_id_fkey
--     FOREIGN KEY (scrap_location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_scrap.write_uid -> res_users.id
-- Original constraint: stock_scrap_write_uid_fkey
-- ALTER TABLE public.stock_scrap
--     ADD CONSTRAINT stock_scrap_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap_reason_tag.create_uid -> res_users.id
-- Original constraint: stock_scrap_reason_tag_create_uid_fkey
-- ALTER TABLE public.stock_scrap_reason_tag
--     ADD CONSTRAINT stock_scrap_reason_tag_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap_reason_tag.write_uid -> res_users.id
-- Original constraint: stock_scrap_reason_tag_write_uid_fkey
-- ALTER TABLE public.stock_scrap_reason_tag
--     ADD CONSTRAINT stock_scrap_reason_tag_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_scrap_stock_scrap_reason_tag_rel.stock_scrap_reason_tag_id -> stock_scrap_reason_tag.id
-- Original constraint: stock_scrap_stock_scrap_reason_t_stock_scrap_reason_tag_id_fkey
-- ALTER TABLE public.stock_scrap_stock_scrap_reason_tag_rel
--     ADD CONSTRAINT stock_scrap_stock_scrap_reason_t_stock_scrap_reason_tag_id_fkey
--     FOREIGN KEY (stock_scrap_reason_tag_id)
--     REFERENCES public.stock_scrap_reason_tag(id)
--     ON DELETE CASCADE;

-- FK: stock_scrap_stock_scrap_reason_tag_rel.stock_scrap_id -> stock_scrap.id
-- Original constraint: stock_scrap_stock_scrap_reason_tag_rel_stock_scrap_id_fkey
-- ALTER TABLE public.stock_scrap_stock_scrap_reason_tag_rel
--     ADD CONSTRAINT stock_scrap_stock_scrap_reason_tag_rel_stock_scrap_id_fkey
--     FOREIGN KEY (stock_scrap_id)
--     REFERENCES public.stock_scrap(id)
--     ON DELETE CASCADE;

-- FK: stock_storage_category.company_id -> res_company.id
-- Original constraint: stock_storage_category_company_id_fkey
-- ALTER TABLE public.stock_storage_category
--     ADD CONSTRAINT stock_storage_category_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: stock_storage_category.create_uid -> res_users.id
-- Original constraint: stock_storage_category_create_uid_fkey
-- ALTER TABLE public.stock_storage_category
--     ADD CONSTRAINT stock_storage_category_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_storage_category.write_uid -> res_users.id
-- Original constraint: stock_storage_category_write_uid_fkey
-- ALTER TABLE public.stock_storage_category
--     ADD CONSTRAINT stock_storage_category_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_storage_category_capacity.create_uid -> res_users.id
-- Original constraint: stock_storage_category_capacity_create_uid_fkey
-- ALTER TABLE public.stock_storage_category_capacity
--     ADD CONSTRAINT stock_storage_category_capacity_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_storage_category_capacity.package_type_id -> stock_package_type.id
-- Original constraint: stock_storage_category_capacity_package_type_id_fkey
-- ALTER TABLE public.stock_storage_category_capacity
--     ADD CONSTRAINT stock_storage_category_capacity_package_type_id_fkey
--     FOREIGN KEY (package_type_id)
--     REFERENCES public.stock_package_type(id)
--     ON DELETE CASCADE;

-- FK: stock_storage_category_capacity.product_id -> product_product.id
-- Original constraint: stock_storage_category_capacity_product_id_fkey
-- ALTER TABLE public.stock_storage_category_capacity
--     ADD CONSTRAINT stock_storage_category_capacity_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_storage_category_capacity.storage_category_id -> stock_storage_category.id
-- Original constraint: stock_storage_category_capacity_storage_category_id_fkey
-- ALTER TABLE public.stock_storage_category_capacity
--     ADD CONSTRAINT stock_storage_category_capacity_storage_category_id_fkey
--     FOREIGN KEY (storage_category_id)
--     REFERENCES public.stock_storage_category(id)
--     ON DELETE CASCADE;

-- FK: stock_storage_category_capacity.write_uid -> res_users.id
-- Original constraint: stock_storage_category_capacity_write_uid_fkey
-- ALTER TABLE public.stock_storage_category_capacity
--     ADD CONSTRAINT stock_storage_category_capacity_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_traceability_report.create_uid -> res_users.id
-- Original constraint: stock_traceability_report_create_uid_fkey
-- ALTER TABLE public.stock_traceability_report
--     ADD CONSTRAINT stock_traceability_report_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_traceability_report.write_uid -> res_users.id
-- Original constraint: stock_traceability_report_write_uid_fkey
-- ALTER TABLE public.stock_traceability_report
--     ADD CONSTRAINT stock_traceability_report_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.buy_pull_id -> stock_rule.id
-- Original constraint: stock_warehouse_buy_pull_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_buy_pull_id_fkey
--     FOREIGN KEY (buy_pull_id)
--     REFERENCES public.stock_rule(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.company_id -> res_company.id
-- Original constraint: stock_warehouse_company_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_warehouse.create_uid -> res_users.id
-- Original constraint: stock_warehouse_create_uid_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.delivery_route_id -> stock_route.id
-- Original constraint: stock_warehouse_delivery_route_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_delivery_route_id_fkey
--     FOREIGN KEY (delivery_route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE RESTRICT;

-- FK: stock_warehouse.in_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_in_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_in_type_id_fkey
--     FOREIGN KEY (in_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.int_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_int_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_int_type_id_fkey
--     FOREIGN KEY (int_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.lot_stock_id -> stock_location.id
-- Original constraint: stock_warehouse_lot_stock_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_lot_stock_id_fkey
--     FOREIGN KEY (lot_stock_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_warehouse.mto_pull_id -> stock_rule.id
-- Original constraint: stock_warehouse_mto_pull_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_mto_pull_id_fkey
--     FOREIGN KEY (mto_pull_id)
--     REFERENCES public.stock_rule(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.out_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_out_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_out_type_id_fkey
--     FOREIGN KEY (out_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.pack_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_pack_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_pack_type_id_fkey
--     FOREIGN KEY (pack_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.partner_id -> res_partner.id
-- Original constraint: stock_warehouse_partner_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.pick_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_pick_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_pick_type_id_fkey
--     FOREIGN KEY (pick_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.qc_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_qc_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_qc_type_id_fkey
--     FOREIGN KEY (qc_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.reception_route_id -> stock_route.id
-- Original constraint: stock_warehouse_reception_route_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_reception_route_id_fkey
--     FOREIGN KEY (reception_route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE RESTRICT;

-- FK: stock_warehouse.store_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_store_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_store_type_id_fkey
--     FOREIGN KEY (store_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.view_location_id -> stock_location.id
-- Original constraint: stock_warehouse_view_location_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_view_location_id_fkey
--     FOREIGN KEY (view_location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE RESTRICT;

-- FK: stock_warehouse.wh_input_stock_loc_id -> stock_location.id
-- Original constraint: stock_warehouse_wh_input_stock_loc_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_wh_input_stock_loc_id_fkey
--     FOREIGN KEY (wh_input_stock_loc_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.wh_output_stock_loc_id -> stock_location.id
-- Original constraint: stock_warehouse_wh_output_stock_loc_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_wh_output_stock_loc_id_fkey
--     FOREIGN KEY (wh_output_stock_loc_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.wh_pack_stock_loc_id -> stock_location.id
-- Original constraint: stock_warehouse_wh_pack_stock_loc_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_wh_pack_stock_loc_id_fkey
--     FOREIGN KEY (wh_pack_stock_loc_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.wh_qc_stock_loc_id -> stock_location.id
-- Original constraint: stock_warehouse_wh_qc_stock_loc_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_wh_qc_stock_loc_id_fkey
--     FOREIGN KEY (wh_qc_stock_loc_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.write_uid -> res_users.id
-- Original constraint: stock_warehouse_write_uid_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse.xdock_type_id -> stock_picking_type.id
-- Original constraint: stock_warehouse_xdock_type_id_fkey
-- ALTER TABLE public.stock_warehouse
--     ADD CONSTRAINT stock_warehouse_xdock_type_id_fkey
--     FOREIGN KEY (xdock_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse_orderpoint.company_id -> res_company.id
-- Original constraint: stock_warehouse_orderpoint_company_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: stock_warehouse_orderpoint.create_uid -> res_users.id
-- Original constraint: stock_warehouse_orderpoint_create_uid_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse_orderpoint.location_id -> stock_location.id
-- Original constraint: stock_warehouse_orderpoint_location_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE CASCADE;

-- FK: stock_warehouse_orderpoint.product_id -> product_product.id
-- Original constraint: stock_warehouse_orderpoint_product_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_warehouse_orderpoint.replenishment_uom_id -> uom_uom.id
-- Original constraint: stock_warehouse_orderpoint_replenishment_uom_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_replenishment_uom_id_fkey
--     FOREIGN KEY (replenishment_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse_orderpoint.route_id -> stock_route.id
-- Original constraint: stock_warehouse_orderpoint_route_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_route_id_fkey
--     FOREIGN KEY (route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse_orderpoint.supplier_id -> product_supplierinfo.id
-- Original constraint: stock_warehouse_orderpoint_supplier_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_supplier_id_fkey
--     FOREIGN KEY (supplier_id)
--     REFERENCES public.product_supplierinfo(id)
--     ON DELETE SET NULL;

-- FK: stock_warehouse_orderpoint.warehouse_id -> stock_warehouse.id
-- Original constraint: stock_warehouse_orderpoint_warehouse_id_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: stock_warehouse_orderpoint.write_uid -> res_users.id
-- Original constraint: stock_warehouse_orderpoint_write_uid_fkey
-- ALTER TABLE public.stock_warehouse_orderpoint
--     ADD CONSTRAINT stock_warehouse_orderpoint_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_warn_insufficient_qty_scrap.create_uid -> res_users.id
-- Original constraint: stock_warn_insufficient_qty_scrap_create_uid_fkey
-- ALTER TABLE public.stock_warn_insufficient_qty_scrap
--     ADD CONSTRAINT stock_warn_insufficient_qty_scrap_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_warn_insufficient_qty_scrap.location_id -> stock_location.id
-- Original constraint: stock_warn_insufficient_qty_scrap_location_id_fkey
-- ALTER TABLE public.stock_warn_insufficient_qty_scrap
--     ADD CONSTRAINT stock_warn_insufficient_qty_scrap_location_id_fkey
--     FOREIGN KEY (location_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE CASCADE;

-- FK: stock_warn_insufficient_qty_scrap.product_id -> product_product.id
-- Original constraint: stock_warn_insufficient_qty_scrap_product_id_fkey
-- ALTER TABLE public.stock_warn_insufficient_qty_scrap
--     ADD CONSTRAINT stock_warn_insufficient_qty_scrap_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE CASCADE;

-- FK: stock_warn_insufficient_qty_scrap.scrap_id -> stock_scrap.id
-- Original constraint: stock_warn_insufficient_qty_scrap_scrap_id_fkey
-- ALTER TABLE public.stock_warn_insufficient_qty_scrap
--     ADD CONSTRAINT stock_warn_insufficient_qty_scrap_scrap_id_fkey
--     FOREIGN KEY (scrap_id)
--     REFERENCES public.stock_scrap(id)
--     ON DELETE SET NULL;

-- FK: stock_warn_insufficient_qty_scrap.write_uid -> res_users.id
-- Original constraint: stock_warn_insufficient_qty_scrap_write_uid_fkey
-- ALTER TABLE public.stock_warn_insufficient_qty_scrap
--     ADD CONSTRAINT stock_warn_insufficient_qty_scrap_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_wh_resupply_table.supplied_wh_id -> stock_warehouse.id
-- Original constraint: stock_wh_resupply_table_supplied_wh_id_fkey
-- ALTER TABLE public.stock_wh_resupply_table
--     ADD CONSTRAINT stock_wh_resupply_table_supplied_wh_id_fkey
--     FOREIGN KEY (supplied_wh_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: stock_wh_resupply_table.supplier_wh_id -> stock_warehouse.id
-- Original constraint: stock_wh_resupply_table_supplier_wh_id_fkey
-- ALTER TABLE public.stock_wh_resupply_table
--     ADD CONSTRAINT stock_wh_resupply_table_supplier_wh_id_fkey
--     FOREIGN KEY (supplier_wh_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE CASCADE;

-- FK: template_attribute_value_stock_move_rel.move_id -> stock_move.id
-- Original constraint: template_attribute_value_stock_move_rel_move_id_fkey
-- ALTER TABLE public.template_attribute_value_stock_move_rel
--     ADD CONSTRAINT template_attribute_value_stock_move_rel_move_id_fkey
--     FOREIGN KEY (move_id)
--     REFERENCES public.stock_move(id)
--     ON DELETE CASCADE;

-- FK: uom_uom.package_type_id -> stock_package_type.id
-- Original constraint: uom_uom_package_type_id_fkey
-- ALTER TABLE public.uom_uom
--     ADD CONSTRAINT uom_uom_package_type_id_fkey
--     FOREIGN KEY (package_type_id)
--     REFERENCES public.stock_package_type(id)
--     ON DELETE SET NULL;


-- ============================================================
-- SALE MODULE FOREIGN KEYS
-- ============================================================

-- FK: account_analytic_line.so_line -> sale_order_line.id
-- Original constraint: account_analytic_line_so_line_fkey
-- ALTER TABLE public.account_analytic_line
--     ADD CONSTRAINT account_analytic_line_so_line_fkey
--     FOREIGN KEY (so_line)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE SET NULL;

-- FK: account_tax_sale_order_line_rel.sale_order_line_id -> sale_order_line.id
-- Original constraint: account_tax_sale_order_line_rel_sale_order_line_id_fkey
-- ALTER TABLE public.account_tax_sale_order_line_rel
--     ADD CONSTRAINT account_tax_sale_order_line_rel_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: header_footer_quotation_template_rel.sale_order_template_id -> sale_order_template.id
-- Original constraint: header_footer_quotation_template_re_sale_order_template_id_fkey
-- ALTER TABLE public.header_footer_quotation_template_rel
--     ADD CONSTRAINT header_footer_quotation_template_re_sale_order_template_id_fkey
--     FOREIGN KEY (sale_order_template_id)
--     REFERENCES public.sale_order_template(id)
--     ON DELETE CASCADE;

-- FK: product_attribute_custom_value.sale_order_line_id -> sale_order_line.id
-- Original constraint: product_attribute_custom_value_sale_order_line_id_fkey
-- ALTER TABLE public.product_attribute_custom_value
--     ADD CONSTRAINT product_attribute_custom_value_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: product_document_sale_pdf_form_field_rel.sale_pdf_form_field_id -> sale_pdf_form_field.id
-- Original constraint: product_document_sale_pdf_form_fiel_sale_pdf_form_field_id_fkey
-- ALTER TABLE public.product_document_sale_pdf_form_field_rel
--     ADD CONSTRAINT product_document_sale_pdf_form_fiel_sale_pdf_form_field_id_fkey
--     FOREIGN KEY (sale_pdf_form_field_id)
--     REFERENCES public.sale_pdf_form_field(id)
--     ON DELETE CASCADE;

-- FK: product_template_attribute_value_sale_order_line_rel.sale_order_line_id -> sale_order_line.id
-- Original constraint: product_template_attribute_value_sale_o_sale_order_line_id_fkey
-- ALTER TABLE public.product_template_attribute_value_sale_order_line_rel
--     ADD CONSTRAINT product_template_attribute_value_sale_o_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: purchase_order_line.sale_line_id -> sale_order_line.id
-- Original constraint: purchase_order_line_sale_line_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_sale_line_id_fkey
--     FOREIGN KEY (sale_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE SET NULL;

-- FK: quotation_document_sale_order_rel.sale_order_id -> sale_order.id
-- Original constraint: quotation_document_sale_order_rel_sale_order_id_fkey
-- ALTER TABLE public.quotation_document_sale_order_rel
--     ADD CONSTRAINT quotation_document_sale_order_rel_sale_order_id_fkey
--     FOREIGN KEY (sale_order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: quotation_document_sale_pdf_form_field_rel.sale_pdf_form_field_id -> sale_pdf_form_field.id
-- Original constraint: quotation_document_sale_pdf_form_fi_sale_pdf_form_field_id_fkey
-- ALTER TABLE public.quotation_document_sale_pdf_form_field_rel
--     ADD CONSTRAINT quotation_document_sale_pdf_form_fi_sale_pdf_form_field_id_fkey
--     FOREIGN KEY (sale_pdf_form_field_id)
--     REFERENCES public.sale_pdf_form_field(id)
--     ON DELETE CASCADE;

-- FK: res_company.sale_order_template_id -> sale_order_template.id
-- Original constraint: res_company_sale_order_template_id_fkey
-- ALTER TABLE public.res_company
--     ADD CONSTRAINT res_company_sale_order_template_id_fkey
--     FOREIGN KEY (sale_order_template_id)
--     REFERENCES public.sale_order_template(id)
--     ON DELETE SET NULL;

-- FK: sale_advance_payment_inv.company_id -> res_company.id
-- Original constraint: sale_advance_payment_inv_company_id_fkey
-- ALTER TABLE public.sale_advance_payment_inv
--     ADD CONSTRAINT sale_advance_payment_inv_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: sale_advance_payment_inv.create_uid -> res_users.id
-- Original constraint: sale_advance_payment_inv_create_uid_fkey
-- ALTER TABLE public.sale_advance_payment_inv
--     ADD CONSTRAINT sale_advance_payment_inv_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_advance_payment_inv.currency_id -> res_currency.id
-- Original constraint: sale_advance_payment_inv_currency_id_fkey
-- ALTER TABLE public.sale_advance_payment_inv
--     ADD CONSTRAINT sale_advance_payment_inv_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE SET NULL;

-- FK: sale_advance_payment_inv.write_uid -> res_users.id
-- Original constraint: sale_advance_payment_inv_write_uid_fkey
-- ALTER TABLE public.sale_advance_payment_inv
--     ADD CONSTRAINT sale_advance_payment_inv_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_advance_payment_inv_sale_order_rel.sale_advance_payment_inv_id -> sale_advance_payment_inv.id
-- Original constraint: sale_advance_payment_inv_sale__sale_advance_payment_inv_id_fkey
-- ALTER TABLE public.sale_advance_payment_inv_sale_order_rel
--     ADD CONSTRAINT sale_advance_payment_inv_sale__sale_advance_payment_inv_id_fkey
--     FOREIGN KEY (sale_advance_payment_inv_id)
--     REFERENCES public.sale_advance_payment_inv(id)
--     ON DELETE CASCADE;

-- FK: sale_advance_payment_inv_sale_order_rel.sale_order_id -> sale_order.id
-- Original constraint: sale_advance_payment_inv_sale_order_rel_sale_order_id_fkey
-- ALTER TABLE public.sale_advance_payment_inv_sale_order_rel
--     ADD CONSTRAINT sale_advance_payment_inv_sale_order_rel_sale_order_id_fkey
--     FOREIGN KEY (sale_order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: sale_mass_cancel_orders.create_uid -> res_users.id
-- Original constraint: sale_mass_cancel_orders_create_uid_fkey
-- ALTER TABLE public.sale_mass_cancel_orders
--     ADD CONSTRAINT sale_mass_cancel_orders_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_mass_cancel_orders.write_uid -> res_users.id
-- Original constraint: sale_mass_cancel_orders_write_uid_fkey
-- ALTER TABLE public.sale_mass_cancel_orders
--     ADD CONSTRAINT sale_mass_cancel_orders_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order.campaign_id -> utm_campaign.id
-- Original constraint: sale_order_campaign_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_campaign_id_fkey
--     FOREIGN KEY (campaign_id)
--     REFERENCES public.utm_campaign(id)
--     ON DELETE SET NULL;

-- FK: sale_order.company_id -> res_company.id
-- Original constraint: sale_order_company_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: sale_order.create_uid -> res_users.id
-- Original constraint: sale_order_create_uid_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order.currency_id -> res_currency.id
-- Original constraint: sale_order_currency_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE RESTRICT;

-- FK: sale_order.fiscal_position_id -> account_fiscal_position.id
-- Original constraint: sale_order_fiscal_position_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_fiscal_position_id_fkey
--     FOREIGN KEY (fiscal_position_id)
--     REFERENCES public.account_fiscal_position(id)
--     ON DELETE SET NULL;

-- FK: sale_order.incoterm -> account_incoterms.id
-- Original constraint: sale_order_incoterm_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_incoterm_fkey
--     FOREIGN KEY (incoterm)
--     REFERENCES public.account_incoterms(id)
--     ON DELETE SET NULL;

-- FK: sale_order.journal_id -> account_journal.id
-- Original constraint: sale_order_journal_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_journal_id_fkey
--     FOREIGN KEY (journal_id)
--     REFERENCES public.account_journal(id)
--     ON DELETE SET NULL;

-- FK: sale_order.medium_id -> utm_medium.id
-- Original constraint: sale_order_medium_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_medium_id_fkey
--     FOREIGN KEY (medium_id)
--     REFERENCES public.utm_medium(id)
--     ON DELETE SET NULL;

-- FK: sale_order.partner_id -> res_partner.id
-- Original constraint: sale_order_partner_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE RESTRICT;

-- FK: sale_order.partner_invoice_id -> res_partner.id
-- Original constraint: sale_order_partner_invoice_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_partner_invoice_id_fkey
--     FOREIGN KEY (partner_invoice_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE RESTRICT;

-- FK: sale_order.partner_shipping_id -> res_partner.id
-- Original constraint: sale_order_partner_shipping_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_partner_shipping_id_fkey
--     FOREIGN KEY (partner_shipping_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE RESTRICT;

-- FK: sale_order.payment_term_id -> account_payment_term.id
-- Original constraint: sale_order_payment_term_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_payment_term_id_fkey
--     FOREIGN KEY (payment_term_id)
--     REFERENCES public.account_payment_term(id)
--     ON DELETE SET NULL;

-- FK: sale_order.pending_email_template_id -> mail_template.id
-- Original constraint: sale_order_pending_email_template_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_pending_email_template_id_fkey
--     FOREIGN KEY (pending_email_template_id)
--     REFERENCES public.mail_template(id)
--     ON DELETE SET NULL;

-- FK: sale_order.preferred_payment_method_line_id -> account_payment_method_line.id
-- Original constraint: sale_order_preferred_payment_method_line_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_preferred_payment_method_line_id_fkey
--     FOREIGN KEY (preferred_payment_method_line_id)
--     REFERENCES public.account_payment_method_line(id)
--     ON DELETE SET NULL;

-- FK: sale_order.pricelist_id -> product_pricelist.id
-- Original constraint: sale_order_pricelist_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_pricelist_id_fkey
--     FOREIGN KEY (pricelist_id)
--     REFERENCES public.product_pricelist(id)
--     ON DELETE SET NULL;

-- FK: sale_order.sale_order_template_id -> sale_order_template.id
-- Original constraint: sale_order_sale_order_template_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_sale_order_template_id_fkey
--     FOREIGN KEY (sale_order_template_id)
--     REFERENCES public.sale_order_template(id)
--     ON DELETE SET NULL;

-- FK: sale_order.source_id -> utm_source.id
-- Original constraint: sale_order_source_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_source_id_fkey
--     FOREIGN KEY (source_id)
--     REFERENCES public.utm_source(id)
--     ON DELETE SET NULL;

-- FK: sale_order.team_id -> crm_team.id
-- Original constraint: sale_order_team_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_team_id_fkey
--     FOREIGN KEY (team_id)
--     REFERENCES public.crm_team(id)
--     ON DELETE SET NULL;

-- FK: sale_order.user_id -> res_users.id
-- Original constraint: sale_order_user_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_user_id_fkey
--     FOREIGN KEY (user_id)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order.warehouse_id -> stock_warehouse.id
-- Original constraint: sale_order_warehouse_id_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: sale_order.write_uid -> res_users.id
-- Original constraint: sale_order_write_uid_fkey
-- ALTER TABLE public.sale_order
--     ADD CONSTRAINT sale_order_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_discount.create_uid -> res_users.id
-- Original constraint: sale_order_discount_create_uid_fkey
-- ALTER TABLE public.sale_order_discount
--     ADD CONSTRAINT sale_order_discount_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_discount.sale_order_id -> sale_order.id
-- Original constraint: sale_order_discount_sale_order_id_fkey
-- ALTER TABLE public.sale_order_discount
--     ADD CONSTRAINT sale_order_discount_sale_order_id_fkey
--     FOREIGN KEY (sale_order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: sale_order_discount.write_uid -> res_users.id
-- Original constraint: sale_order_discount_write_uid_fkey
-- ALTER TABLE public.sale_order_discount
--     ADD CONSTRAINT sale_order_discount_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.combo_item_id -> product_combo_item.id
-- Original constraint: sale_order_line_combo_item_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_combo_item_id_fkey
--     FOREIGN KEY (combo_item_id)
--     REFERENCES public.product_combo_item(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.company_id -> res_company.id
-- Original constraint: sale_order_line_company_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.create_uid -> res_users.id
-- Original constraint: sale_order_line_create_uid_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.currency_id -> res_currency.id
-- Original constraint: sale_order_line_currency_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.linked_line_id -> sale_order_line.id
-- Original constraint: sale_order_line_linked_line_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_linked_line_id_fkey
--     FOREIGN KEY (linked_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line.order_id -> sale_order.id
-- Original constraint: sale_order_line_order_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_order_id_fkey
--     FOREIGN KEY (order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line.order_partner_id -> res_partner.id
-- Original constraint: sale_order_line_order_partner_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_order_partner_id_fkey
--     FOREIGN KEY (order_partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.product_id -> product_product.id
-- Original constraint: sale_order_line_product_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: sale_order_line.product_uom_id -> uom_uom.id
-- Original constraint: sale_order_line_product_uom_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: sale_order_line.salesman_id -> res_users.id
-- Original constraint: sale_order_line_salesman_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_salesman_id_fkey
--     FOREIGN KEY (salesman_id)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.warehouse_id -> stock_warehouse.id
-- Original constraint: sale_order_line_warehouse_id_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_warehouse_id_fkey
--     FOREIGN KEY (warehouse_id)
--     REFERENCES public.stock_warehouse(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line.write_uid -> res_users.id
-- Original constraint: sale_order_line_write_uid_fkey
-- ALTER TABLE public.sale_order_line
--     ADD CONSTRAINT sale_order_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_line_invoice_rel.invoice_line_id -> account_move_line.id
-- Original constraint: sale_order_line_invoice_rel_invoice_line_id_fkey
-- ALTER TABLE public.sale_order_line_invoice_rel
--     ADD CONSTRAINT sale_order_line_invoice_rel_invoice_line_id_fkey
--     FOREIGN KEY (invoice_line_id)
--     REFERENCES public.account_move_line(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line_invoice_rel.order_line_id -> sale_order_line.id
-- Original constraint: sale_order_line_invoice_rel_order_line_id_fkey
-- ALTER TABLE public.sale_order_line_invoice_rel
--     ADD CONSTRAINT sale_order_line_invoice_rel_order_line_id_fkey
--     FOREIGN KEY (order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line_product_document_rel.product_document_id -> product_document.id
-- Original constraint: sale_order_line_product_document_rel_product_document_id_fkey
-- ALTER TABLE public.sale_order_line_product_document_rel
--     ADD CONSTRAINT sale_order_line_product_document_rel_product_document_id_fkey
--     FOREIGN KEY (product_document_id)
--     REFERENCES public.product_document(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line_product_document_rel.sale_order_line_id -> sale_order_line.id
-- Original constraint: sale_order_line_product_document_rel_sale_order_line_id_fkey
-- ALTER TABLE public.sale_order_line_product_document_rel
--     ADD CONSTRAINT sale_order_line_product_document_rel_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line_stock_route_rel.sale_order_line_id -> sale_order_line.id
-- Original constraint: sale_order_line_stock_route_rel_sale_order_line_id_fkey
-- ALTER TABLE public.sale_order_line_stock_route_rel
--     ADD CONSTRAINT sale_order_line_stock_route_rel_sale_order_line_id_fkey
--     FOREIGN KEY (sale_order_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE CASCADE;

-- FK: sale_order_line_stock_route_rel.stock_route_id -> stock_route.id
-- Original constraint: sale_order_line_stock_route_rel_stock_route_id_fkey
-- ALTER TABLE public.sale_order_line_stock_route_rel
--     ADD CONSTRAINT sale_order_line_stock_route_rel_stock_route_id_fkey
--     FOREIGN KEY (stock_route_id)
--     REFERENCES public.stock_route(id)
--     ON DELETE RESTRICT;

-- FK: sale_order_mass_cancel_wizard_rel.sale_mass_cancel_orders_id -> sale_mass_cancel_orders.id
-- Original constraint: sale_order_mass_cancel_wizard_r_sale_mass_cancel_orders_id_fkey
-- ALTER TABLE public.sale_order_mass_cancel_wizard_rel
--     ADD CONSTRAINT sale_order_mass_cancel_wizard_r_sale_mass_cancel_orders_id_fkey
--     FOREIGN KEY (sale_mass_cancel_orders_id)
--     REFERENCES public.sale_mass_cancel_orders(id)
--     ON DELETE CASCADE;

-- FK: sale_order_mass_cancel_wizard_rel.sale_order_id -> sale_order.id
-- Original constraint: sale_order_mass_cancel_wizard_rel_sale_order_id_fkey
-- ALTER TABLE public.sale_order_mass_cancel_wizard_rel
--     ADD CONSTRAINT sale_order_mass_cancel_wizard_rel_sale_order_id_fkey
--     FOREIGN KEY (sale_order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: sale_order_tag_rel.order_id -> sale_order.id
-- Original constraint: sale_order_tag_rel_order_id_fkey
-- ALTER TABLE public.sale_order_tag_rel
--     ADD CONSTRAINT sale_order_tag_rel_order_id_fkey
--     FOREIGN KEY (order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: sale_order_tag_rel.tag_id -> crm_tag.id
-- Original constraint: sale_order_tag_rel_tag_id_fkey
-- ALTER TABLE public.sale_order_tag_rel
--     ADD CONSTRAINT sale_order_tag_rel_tag_id_fkey
--     FOREIGN KEY (tag_id)
--     REFERENCES public.crm_tag(id)
--     ON DELETE CASCADE;

-- FK: sale_order_template.company_id -> res_company.id
-- Original constraint: sale_order_template_company_id_fkey
-- ALTER TABLE public.sale_order_template
--     ADD CONSTRAINT sale_order_template_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template.create_uid -> res_users.id
-- Original constraint: sale_order_template_create_uid_fkey
-- ALTER TABLE public.sale_order_template
--     ADD CONSTRAINT sale_order_template_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template.mail_template_id -> mail_template.id
-- Original constraint: sale_order_template_mail_template_id_fkey
-- ALTER TABLE public.sale_order_template
--     ADD CONSTRAINT sale_order_template_mail_template_id_fkey
--     FOREIGN KEY (mail_template_id)
--     REFERENCES public.mail_template(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template.write_uid -> res_users.id
-- Original constraint: sale_order_template_write_uid_fkey
-- ALTER TABLE public.sale_order_template
--     ADD CONSTRAINT sale_order_template_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template_line.company_id -> res_company.id
-- Original constraint: sale_order_template_line_company_id_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template_line.create_uid -> res_users.id
-- Original constraint: sale_order_template_line_create_uid_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template_line.product_id -> product_product.id
-- Original constraint: sale_order_template_line_product_id_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template_line.product_uom_id -> uom_uom.id
-- Original constraint: sale_order_template_line_product_uom_id_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE SET NULL;

-- FK: sale_order_template_line.sale_order_template_id -> sale_order_template.id
-- Original constraint: sale_order_template_line_sale_order_template_id_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_sale_order_template_id_fkey
--     FOREIGN KEY (sale_order_template_id)
--     REFERENCES public.sale_order_template(id)
--     ON DELETE CASCADE;

-- FK: sale_order_template_line.write_uid -> res_users.id
-- Original constraint: sale_order_template_line_write_uid_fkey
-- ALTER TABLE public.sale_order_template_line
--     ADD CONSTRAINT sale_order_template_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_order_transaction_rel.sale_order_id -> sale_order.id
-- Original constraint: sale_order_transaction_rel_sale_order_id_fkey
-- ALTER TABLE public.sale_order_transaction_rel
--     ADD CONSTRAINT sale_order_transaction_rel_sale_order_id_fkey
--     FOREIGN KEY (sale_order_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;

-- FK: sale_order_transaction_rel.transaction_id -> payment_transaction.id
-- Original constraint: sale_order_transaction_rel_transaction_id_fkey
-- ALTER TABLE public.sale_order_transaction_rel
--     ADD CONSTRAINT sale_order_transaction_rel_transaction_id_fkey
--     FOREIGN KEY (transaction_id)
--     REFERENCES public.payment_transaction(id)
--     ON DELETE CASCADE;

-- FK: sale_pdf_form_field.create_uid -> res_users.id
-- Original constraint: sale_pdf_form_field_create_uid_fkey
-- ALTER TABLE public.sale_pdf_form_field
--     ADD CONSTRAINT sale_pdf_form_field_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: sale_pdf_form_field.write_uid -> res_users.id
-- Original constraint: sale_pdf_form_field_write_uid_fkey
-- ALTER TABLE public.sale_pdf_form_field
--     ADD CONSTRAINT sale_pdf_form_field_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: stock_move.sale_line_id -> sale_order_line.id
-- Original constraint: stock_move_sale_line_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_sale_line_id_fkey
--     FOREIGN KEY (sale_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE SET NULL;

-- FK: stock_picking.sale_id -> sale_order.id
-- Original constraint: stock_picking_sale_id_fkey
-- ALTER TABLE public.stock_picking
--     ADD CONSTRAINT stock_picking_sale_id_fkey
--     FOREIGN KEY (sale_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE SET NULL;

-- FK: stock_reference_sale_rel.sale_id -> sale_order.id
-- Original constraint: stock_reference_sale_rel_sale_id_fkey
-- ALTER TABLE public.stock_reference_sale_rel
--     ADD CONSTRAINT stock_reference_sale_rel_sale_id_fkey
--     FOREIGN KEY (sale_id)
--     REFERENCES public.sale_order(id)
--     ON DELETE CASCADE;


-- ============================================================
-- PURCHASE MODULE FOREIGN KEYS
-- ============================================================

-- FK: account_move_line.purchase_line_id -> purchase_order_line.id
-- Original constraint: account_move_line_purchase_line_id_fkey
-- ALTER TABLE public.account_move_line
--     ADD CONSTRAINT account_move_line_purchase_line_id_fkey
--     FOREIGN KEY (purchase_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE SET NULL;

-- FK: account_move_purchase_order_rel.purchase_order_id -> purchase_order.id
-- Original constraint: account_move_purchase_order_rel_purchase_order_id_fkey
-- ALTER TABLE public.account_move_purchase_order_rel
--     ADD CONSTRAINT account_move_purchase_order_rel_purchase_order_id_fkey
--     FOREIGN KEY (purchase_order_id)
--     REFERENCES public.purchase_order(id)
--     ON DELETE CASCADE;

-- FK: account_tax_purchase_order_line_rel.purchase_order_line_id -> purchase_order_line.id
-- Original constraint: account_tax_purchase_order_line_rel_purchase_order_line_id_fkey
-- ALTER TABLE public.account_tax_purchase_order_line_rel
--     ADD CONSTRAINT account_tax_purchase_order_line_rel_purchase_order_line_id_fkey
--     FOREIGN KEY (purchase_order_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE CASCADE;

-- FK: bill_to_po_wizard.purchase_order_id -> purchase_order.id
-- Original constraint: bill_to_po_wizard_purchase_order_id_fkey
-- ALTER TABLE public.bill_to_po_wizard
--     ADD CONSTRAINT bill_to_po_wizard_purchase_order_id_fkey
--     FOREIGN KEY (purchase_order_id)
--     REFERENCES public.purchase_order(id)
--     ON DELETE SET NULL;

-- FK: product_template_attribute_value_purchase_order_line_rel.purchase_order_line_id -> purchase_order_line.id
-- Original constraint: product_template_attribute_value_pu_purchase_order_line_id_fkey
-- ALTER TABLE public.product_template_attribute_value_purchase_order_line_rel
--     ADD CONSTRAINT product_template_attribute_value_pu_purchase_order_line_id_fkey
--     FOREIGN KEY (purchase_order_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE CASCADE;

-- FK: purchase_order.company_id -> res_company.id
-- Original constraint: purchase_order_company_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order.create_uid -> res_users.id
-- Original constraint: purchase_order_create_uid_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.currency_id -> res_currency.id
-- Original constraint: purchase_order_currency_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_currency_id_fkey
--     FOREIGN KEY (currency_id)
--     REFERENCES public.res_currency(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order.dest_address_id -> res_partner.id
-- Original constraint: purchase_order_dest_address_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_dest_address_id_fkey
--     FOREIGN KEY (dest_address_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.fiscal_position_id -> account_fiscal_position.id
-- Original constraint: purchase_order_fiscal_position_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_fiscal_position_id_fkey
--     FOREIGN KEY (fiscal_position_id)
--     REFERENCES public.account_fiscal_position(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.incoterm_id -> account_incoterms.id
-- Original constraint: purchase_order_incoterm_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_incoterm_id_fkey
--     FOREIGN KEY (incoterm_id)
--     REFERENCES public.account_incoterms(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.partner_id -> res_partner.id
-- Original constraint: purchase_order_partner_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order.payment_term_id -> account_payment_term.id
-- Original constraint: purchase_order_payment_term_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_payment_term_id_fkey
--     FOREIGN KEY (payment_term_id)
--     REFERENCES public.account_payment_term(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.picking_type_id -> stock_picking_type.id
-- Original constraint: purchase_order_picking_type_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_picking_type_id_fkey
--     FOREIGN KEY (picking_type_id)
--     REFERENCES public.stock_picking_type(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order.user_id -> res_users.id
-- Original constraint: purchase_order_user_id_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_user_id_fkey
--     FOREIGN KEY (user_id)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: purchase_order.write_uid -> res_users.id
-- Original constraint: purchase_order_write_uid_fkey
-- ALTER TABLE public.purchase_order
--     ADD CONSTRAINT purchase_order_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.company_id -> res_company.id
-- Original constraint: purchase_order_line_company_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_company_id_fkey
--     FOREIGN KEY (company_id)
--     REFERENCES public.res_company(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.create_uid -> res_users.id
-- Original constraint: purchase_order_line_create_uid_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_create_uid_fkey
--     FOREIGN KEY (create_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.location_final_id -> stock_location.id
-- Original constraint: purchase_order_line_location_final_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_location_final_id_fkey
--     FOREIGN KEY (location_final_id)
--     REFERENCES public.stock_location(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.order_id -> purchase_order.id
-- Original constraint: purchase_order_line_order_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_order_id_fkey
--     FOREIGN KEY (order_id)
--     REFERENCES public.purchase_order(id)
--     ON DELETE CASCADE;

-- FK: purchase_order_line.orderpoint_id -> stock_warehouse_orderpoint.id
-- Original constraint: purchase_order_line_orderpoint_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_orderpoint_id_fkey
--     FOREIGN KEY (orderpoint_id)
--     REFERENCES public.stock_warehouse_orderpoint(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.partner_id -> res_partner.id
-- Original constraint: purchase_order_line_partner_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_partner_id_fkey
--     FOREIGN KEY (partner_id)
--     REFERENCES public.res_partner(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.product_id -> product_product.id
-- Original constraint: purchase_order_line_product_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_product_id_fkey
--     FOREIGN KEY (product_id)
--     REFERENCES public.product_product(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order_line.product_uom_id -> uom_uom.id
-- Original constraint: purchase_order_line_product_uom_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_product_uom_id_fkey
--     FOREIGN KEY (product_uom_id)
--     REFERENCES public.uom_uom(id)
--     ON DELETE RESTRICT;

-- FK: purchase_order_line.sale_line_id -> sale_order_line.id
-- Original constraint: purchase_order_line_sale_line_id_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_sale_line_id_fkey
--     FOREIGN KEY (sale_line_id)
--     REFERENCES public.sale_order_line(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_line.write_uid -> res_users.id
-- Original constraint: purchase_order_line_write_uid_fkey
-- ALTER TABLE public.purchase_order_line
--     ADD CONSTRAINT purchase_order_line_write_uid_fkey
--     FOREIGN KEY (write_uid)
--     REFERENCES public.res_users(id)
--     ON DELETE SET NULL;

-- FK: purchase_order_stock_picking_rel.purchase_order_id -> purchase_order.id
-- Original constraint: purchase_order_stock_picking_rel_purchase_order_id_fkey
-- ALTER TABLE public.purchase_order_stock_picking_rel
--     ADD CONSTRAINT purchase_order_stock_picking_rel_purchase_order_id_fkey
--     FOREIGN KEY (purchase_order_id)
--     REFERENCES public.purchase_order(id)
--     ON DELETE CASCADE;

-- FK: purchase_order_stock_picking_rel.stock_picking_id -> stock_picking.id
-- Original constraint: purchase_order_stock_picking_rel_stock_picking_id_fkey
-- ALTER TABLE public.purchase_order_stock_picking_rel
--     ADD CONSTRAINT purchase_order_stock_picking_rel_stock_picking_id_fkey
--     FOREIGN KEY (stock_picking_id)
--     REFERENCES public.stock_picking(id)
--     ON DELETE CASCADE;

-- FK: stock_move.purchase_line_id -> purchase_order_line.id
-- Original constraint: stock_move_purchase_line_id_fkey
-- ALTER TABLE public.stock_move
--     ADD CONSTRAINT stock_move_purchase_line_id_fkey
--     FOREIGN KEY (purchase_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE SET NULL;

-- FK: stock_move_created_purchase_line_rel.created_purchase_line_id -> purchase_order_line.id
-- Original constraint: stock_move_created_purchase_line__created_purchase_line_id_fkey
-- ALTER TABLE public.stock_move_created_purchase_line_rel
--     ADD CONSTRAINT stock_move_created_purchase_line__created_purchase_line_id_fkey
--     FOREIGN KEY (created_purchase_line_id)
--     REFERENCES public.purchase_order_line(id)
--     ON DELETE CASCADE;

-- FK: stock_reference_purchase_rel.purchase_id -> purchase_order.id
-- Original constraint: stock_reference_purchase_rel_purchase_id_fkey
-- ALTER TABLE public.stock_reference_purchase_rel
--     ADD CONSTRAINT stock_reference_purchase_rel_purchase_id_fkey
--     FOREIGN KEY (purchase_id)
--     REFERENCES public.purchase_order(id)
--     ON DELETE CASCADE;

