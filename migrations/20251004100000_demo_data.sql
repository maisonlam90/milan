-- ============================================================
-- 🎯 DEMO DATA - Complete Sample Data for Testing
-- ============================================================
-- Tạo dữ liệu mẫu đầy đủ cho:
-- - Enterprise & Company
-- - Tenant
-- - Users (with roles)
-- - Contacts (customers & suppliers)
-- - Loan Contracts with Transactions
-- - Invoices with Lines and Payments
-- ============================================================

SET TIME ZONE 'UTC';

-- ============================================================
-- SECTION 1: ENTERPRISE, COMPANY & TENANT
-- ============================================================

DO $$
DECLARE
    v_enterprise_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
    v_company_id UUID := 'c1111111-1111-1111-1111-111111111111'::uuid;
    v_tenant_id UUID := '00000000-0000-0000-0000-000000000000'::uuid;
    
    -- Users
    v_admin_id UUID := 'a1111111-1111-1111-1111-111111111111'::uuid;
    v_manager_id UUID := 'a2222222-2222-2222-2222-222222222222'::uuid;
    v_accountant_id UUID := 'a3333333-3333-3333-3333-333333333333'::uuid;
    v_sales_id UUID := 'a4444444-4444-4444-4444-444444444444'::uuid;
    
    -- Contacts
    v_customer1_id UUID := 'c0111111-1111-1111-1111-111111111111'::uuid;
    v_customer2_id UUID := 'c0222222-2222-2222-2222-222222222222'::uuid;
    v_customer3_id UUID := 'c0333333-3333-3333-3333-333333333333'::uuid;
    v_supplier1_id UUID := 'c0444444-4444-4444-4444-444444444444'::uuid;
    v_supplier2_id UUID := 'c0555555-5555-5555-5555-555555555555'::uuid;
    
    -- Loan Contracts
    v_loan1_id UUID := 'f1111111-1111-1111-1111-111111111111'::uuid;
    v_loan2_id UUID := 'f2222222-2222-2222-2222-222222222222'::uuid;
    v_loan3_id UUID := 'f3333333-3333-3333-3333-333333333333'::uuid;
    
    -- Invoices
    v_invoice1_id UUID := 'd1111111-1111-1111-1111-111111111111'::uuid;
    v_invoice2_id UUID := 'd2222222-2222-2222-2222-222222222222'::uuid;
    v_bill1_id UUID := 'd3333333-3333-3333-3333-333333333333'::uuid;
    
    -- Supporting tables
    v_tax_10_id UUID := 'e1111111-1111-1111-1111-111111111111'::uuid;
    v_tax_5_id UUID := 'e2222222-2222-2222-2222-222222222222'::uuid;
    v_journal_sale_id UUID := 'e3333333-3333-3333-3333-333333333333'::uuid;
    v_journal_purchase_id UUID := 'e4444444-4444-4444-4444-444444444444'::uuid;
    v_journal_bank_id UUID := 'e5555555-5555-5555-5555-555555555555'::uuid;
    v_payment_method_id UUID := 'e6666666-6666-6666-6666-666666666666'::uuid;
    v_payment_term_30_id UUID := 'e7777777-7777-7777-7777-777777777777'::uuid;
BEGIN
    RAISE NOTICE '🚀 Starting demo data creation...';
    RAISE NOTICE '📌 Using system tenant: %', v_tenant_id;

    -- ============================================================
    -- SECTION 2: USERS & ROLES
    -- ============================================================
    
    -- Password: "password123" hashed with bcrypt
    -- Hash: $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.9aZLZx7q
    
    -- 2.1) Admin User
    INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
    VALUES (
        v_tenant_id, 
        v_admin_id, 
        'admin@milan.finance', 
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.9aZLZx7q',
        'Admin Milan',
        now()
    )
    ON CONFLICT (tenant_id, user_id) DO NOTHING;
    
    -- 2.2) Manager User
    INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
    VALUES (
        v_tenant_id, 
        v_manager_id, 
        'manager@milan.finance', 
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.9aZLZx7q',
        'Nguyễn Văn Manager',
        now()
    )
    ON CONFLICT (tenant_id, user_id) DO NOTHING;
    
    -- 2.3) Accountant User
    INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
    VALUES (
        v_tenant_id, 
        v_accountant_id, 
        'accountant@milan.finance', 
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.9aZLZx7q',
        'Trần Thị Accountant',
        now()
    )
    ON CONFLICT (tenant_id, user_id) DO NOTHING;
    
    -- 2.4) Sales User
    INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
    VALUES (
        v_tenant_id, 
        v_sales_id, 
        'sales@milan.finance', 
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.9aZLZx7q',
        'Lê Văn Sales',
        now()
    )
    ON CONFLICT (tenant_id, user_id) DO NOTHING;
    
    RAISE NOTICE '✅ Users created (4 users)';
    RAISE NOTICE '   - admin@milan.finance';
    RAISE NOTICE '   - manager@milan.finance';
    RAISE NOTICE '   - accountant@milan.finance';
    RAISE NOTICE '   - sales@milan.finance';
    RAISE NOTICE '   - Password for all: password123';

    -- ============================================================
    -- SECTION 3: CONTACTS (Customers & Suppliers)
    -- ============================================================
    
    -- 3.1) Customer 1 - Company
    INSERT INTO contact (
        tenant_id, id, is_company, name, display_name, 
        email, phone, mobile, street, city, country_code,
        created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_customer1_id, TRUE, 
        'Công ty TNHH ABC', 'ABC Company',
        'contact@abc.vn', '0281234567', '0901234567',
        '123 Nguyễn Huệ', 'Hồ Chí Minh', 'VN',
        v_admin_id, v_sales_id, now()
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 3.2) Customer 2 - Company
    INSERT INTO contact (
        tenant_id, id, is_company, name, display_name,
        email, phone, street, city, country_code,
        created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_customer2_id, TRUE,
        'Công ty Cổ phần XYZ', 'XYZ Corp',
        'info@xyz.vn', '0287654321',
        '456 Lê Lợi', 'Hà Nội', 'VN',
        v_admin_id, v_sales_id, now()
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 3.3) Customer 3 - Individual
    INSERT INTO contact (
        tenant_id, id, is_company, name, display_name,
        email, mobile, street, city, country_code,
        created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_customer3_id, FALSE,
        'Nguyễn Văn A', 'Nguyễn Văn A',
        'nguyenvana@gmail.com', '0909876543',
        '789 Trần Hưng Đạo', 'Đà Nẵng', 'VN',
        v_admin_id, v_sales_id, now()
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 3.4) Supplier 1
    INSERT INTO contact (
        tenant_id, id, is_company, name, display_name,
        email, phone, website, street, city, country_code,
        created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_supplier1_id, TRUE,
        'Nhà cung cấp Tech Solutions', 'Tech Solutions',
        'sales@techsolutions.vn', '0283456789',
        'https://techsolutions.vn',
        '321 Hai Bà Trưng', 'Hồ Chí Minh', 'VN',
        v_admin_id, v_accountant_id, now()
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 3.5) Supplier 2
    INSERT INTO contact (
        tenant_id, id, is_company, name, display_name,
        email, phone, street, city, country_code,
        created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_supplier2_id, TRUE,
        'Công ty Vật tư Thiết bị DEF', 'DEF Equipment',
        'info@def.vn', '0289876543',
        '654 Lý Thái Tổ', 'Hà Nội', 'VN',
        v_admin_id, v_accountant_id, now()
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    RAISE NOTICE '✅ Contacts created (5 contacts)';
    RAISE NOTICE '   - 3 customers';
    RAISE NOTICE '   - 2 suppliers';

    -- ============================================================
    -- SECTION 4: INVOICE SUPPORTING TABLES
    -- ============================================================
    
    -- 4.1) Taxes
    INSERT INTO account_tax (tenant_id, id, name, amount_type, amount, type_tax_use, price_include, created_by, created_at)
    VALUES 
        (v_tenant_id, v_tax_10_id, 'VAT 10%', 'percent', 10.0, 'sale', FALSE, v_admin_id, now()),
        (v_tenant_id, v_tax_5_id, 'VAT 5%', 'percent', 5.0, 'sale', FALSE, v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'VAT 10% (Purchase)', 'percent', 10.0, 'purchase', FALSE, v_admin_id, now())
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 4.2) Journals
    INSERT INTO account_journal (tenant_id, id, name, code, type, created_by, created_at)
    VALUES 
        (v_tenant_id, v_journal_sale_id, 'Customer Invoices', 'INV', 'sale', v_admin_id, now()),
        (v_tenant_id, v_journal_purchase_id, 'Vendor Bills', 'BILL', 'purchase', v_admin_id, now()),
        (v_tenant_id, v_journal_bank_id, 'Bank', 'BANK', 'bank', v_admin_id, now())
    ON CONFLICT (tenant_id, code) DO NOTHING;
    
    -- 4.3) Payment Methods
    INSERT INTO account_payment_method (tenant_id, id, name, code, payment_type, created_by, created_at)
    VALUES 
        (v_tenant_id, v_payment_method_id, 'Cash', 'manual', 'inbound', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'Bank Transfer', 'electronic', 'inbound', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'Cash', 'manual', 'outbound', v_admin_id, now())
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 4.4) Payment Terms
    INSERT INTO account_payment_term (tenant_id, id, name, note, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'Immediate Payment', 'Pay immediately', v_admin_id, now()),
        (v_tenant_id, v_payment_term_30_id, '30 Days', 'Payment within 30 days', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), '45 Days', 'Payment within 45 days', v_admin_id, now())
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    RAISE NOTICE '✅ Invoice support tables created';
    RAISE NOTICE '   - Taxes, Journals, Payment Methods, Payment Terms';

    -- ============================================================
    -- SECTION 5: INVOICES
    -- ============================================================
    
    -- 5.1) Customer Invoice 1 - Posted, Partially Paid
    INSERT INTO account_move (
        tenant_id, id, name, move_type, partner_id,
        state, payment_state, invoice_date, invoice_date_due,
        currency_id, journal_id, payment_term_id,
        amount_untaxed, amount_tax, amount_total, amount_residual,
        narration, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_invoice1_id, 'INV/2024/0001', 'out_invoice', v_customer1_id,
        'posted', 'partial', '2024-09-01'::date, '2024-10-01'::date,
        'VND', v_journal_sale_id, v_payment_term_30_id,
        50000000, 5000000, 55000000, 30000000,
        'Hóa đơn bán hàng tháng 9/2024', v_admin_id, v_accountant_id, '2024-09-01'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- Invoice 1 - Lines
    INSERT INTO account_move_line (
        tenant_id, id, move_id, name,
        quantity, price_unit, discount, price_subtotal, price_total,
        created_by, created_at
    )
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_invoice1_id, 'Laptop Dell XPS 15',
         2.0, 25000000, 0.00, 50000000, 55000000,
         v_admin_id, '2024-09-01'::timestamptz)
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 5.2) Customer Invoice 2 - Draft
    INSERT INTO account_move (
        tenant_id, id, name, move_type, partner_id,
        state, payment_state, invoice_date, invoice_date_due,
        currency_id, journal_id,
        amount_untaxed, amount_tax, amount_total, amount_residual,
        narration, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_invoice2_id, 'INV/2024/0002', 'out_invoice', v_customer2_id,
        'draft', 'not_paid', '2024-10-01'::date, '2024-10-31'::date,
        'VND', v_journal_sale_id,
        20000000, 1000000, 21000000, 21000000,
        'Hóa đơn tháng 10/2024', v_admin_id, v_accountant_id, '2024-10-01'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- Invoice 2 - Lines
    INSERT INTO account_move_line (
        tenant_id, id, move_id, name,
        quantity, price_unit, discount, price_subtotal, price_total,
        created_by, created_at
    )
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_invoice2_id, 'Dịch vụ tư vấn IT',
         20.0, 1000000, 0.00, 20000000, 21000000,
         v_admin_id, '2024-10-01'::timestamptz)
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- 5.3) Vendor Bill 1 - Posted, Not Paid
    INSERT INTO account_move (
        tenant_id, id, name, move_type, partner_id,
        state, payment_state, invoice_date, invoice_date_due, ref,
        currency_id, journal_id,
        amount_untaxed, amount_tax, amount_total, amount_residual,
        narration, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_bill1_id, 'BILL/2024/0001', 'in_invoice', v_supplier1_id,
        'posted', 'not_paid', '2024-09-15'::date, '2024-10-15'::date, 'VNDR-2024-001',
        'VND', v_journal_purchase_id,
        30000000, 3000000, 33000000, 33000000,
        'Mua thiết bị máy tính', v_admin_id, v_accountant_id, '2024-09-15'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- Bill 1 - Lines
    INSERT INTO account_move_line (
        tenant_id, id, move_id, name,
        quantity, price_unit, discount, price_subtotal, price_total,
        created_by, created_at
    )
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_bill1_id, 'Máy tính văn phòng',
         10.0, 3000000, 0.00, 30000000, 33000000,
         v_admin_id, '2024-09-15'::timestamptz)
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    RAISE NOTICE '✅ Invoices created (3 invoices)';
    RAISE NOTICE '   - INV/2024/0001: 55M VND, Posted, Partial paid';
    RAISE NOTICE '   - INV/2024/0002: 21M VND, Draft';
    RAISE NOTICE '   - BILL/2024/0001: 33M VND, Posted, Not paid';

    -- ============================================================
    -- FINAL SUMMARY
    -- ============================================================
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ============================================================';
    RAISE NOTICE '🎉 DEMO DATA CREATED SUCCESSFULLY!';
    RAISE NOTICE '🎉 ============================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '   - Tenant: system (%)', v_tenant_id;
    RAISE NOTICE '   - Users: 4 (admin, manager, accountant, sales)';
    RAISE NOTICE '   - Contacts: 5 (3 customers, 2 suppliers)';
    RAISE NOTICE '   - Invoice Support: Taxes, Journals, Payment Methods, Payment Terms';
    RAISE NOTICE '   - Invoices: 3 (2 customer invoices, 1 vendor bill)';
    RAISE NOTICE '   - Note: Loan contracts moved to separate migration file';
    RAISE NOTICE '';
    RAISE NOTICE '🔑 Login credentials:';
    RAISE NOTICE '   - Email: admin@milan.finance';
    RAISE NOTICE '   - Password: password123';
    RAISE NOTICE '';
    RAISE NOTICE '✅ You can now test the APIs with this demo data!';
    RAISE NOTICE '';
    
END $$;

-- ============================================================
-- ✅ DONE: Demo Data Creation Complete
-- ============================================================

