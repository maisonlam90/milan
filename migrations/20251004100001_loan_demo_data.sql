-- ============================================================
-- 🎯 LOAN DEMO DATA - 10 Loan Contracts with Transactions & Collaterals
-- ============================================================
-- Tạo loan data cho testing:
-- - 10 loan contracts đa dạng (LOAN/2025/0001 - LOAN/2025/0010)
-- - Mỗi contract có 4-5 transactions
-- - Mỗi contract có 3-4 collateral assets
-- ============================================================

SET TIME ZONE 'UTC';

DO $$
DECLARE
    v_tenant_id UUID := '00000000-0000-0000-0000-000000000000'::uuid;
    v_admin_id UUID;
    v_manager_id UUID;
    v_sales_id UUID;
    
    -- First 3 customers (from demo_data_base)
    v_customer1_id UUID := 'c0111111-1111-1111-1111-111111111111'::uuid;
    v_customer2_id UUID := 'c0222222-2222-2222-2222-222222222222'::uuid;
    v_customer3_id UUID := 'c0333333-3333-3333-3333-333333333333'::uuid;
    
    -- Additional 7 customers
    v_cust4_id UUID := 'c0666666-6666-6666-6666-666666666666'::uuid;
    v_cust5_id UUID := 'c0777777-7777-7777-7777-777777777777'::uuid;
    v_cust6_id UUID := 'c0888888-8888-8888-8888-888888888888'::uuid;
    v_cust7_id UUID := 'c0999999-9999-9999-9999-999999999999'::uuid;
    v_cust8_id UUID := 'c0aaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
    v_cust9_id UUID := 'c0bbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid;
    v_cust10_id UUID := 'c0cccccc-cccc-cccc-cccc-cccccccccccc'::uuid;
    
    -- Loan contracts (10 total)
    v_loan1_id UUID := 'f1111111-1111-1111-1111-111111111111'::uuid;
    v_loan2_id UUID := 'f2222222-2222-2222-2222-222222222222'::uuid;
    v_loan3_id UUID := 'f3333333-3333-3333-3333-333333333333'::uuid;
    v_loan4_id UUID := 'f4444444-4444-4444-4444-444444444444'::uuid;
    v_loan5_id UUID := 'f5555555-5555-5555-5555-555555555555'::uuid;
    v_loan6_id UUID := 'f6666666-6666-6666-6666-666666666666'::uuid;
    v_loan7_id UUID := 'f7777777-7777-7777-7777-777777777777'::uuid;
    v_loan8_id UUID := 'f8888888-8888-8888-8888-888888888888'::uuid;
    v_loan9_id UUID := 'f9999999-9999-9999-9999-999999999999'::uuid;
    v_loan10_id UUID := 'faaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
    
BEGIN
    -- Get users
    SELECT user_id INTO v_admin_id 
    FROM users 
    WHERE tenant_id = v_tenant_id AND email = 'admin@milan.finance' 
    LIMIT 1;

    SELECT user_id INTO v_manager_id 
    FROM users 
    WHERE tenant_id = v_tenant_id AND email = 'manager@milan.finance' 
    LIMIT 1;

    SELECT user_id INTO v_sales_id 
    FROM users 
    WHERE tenant_id = v_tenant_id AND email = 'sales@milan.finance' 
    LIMIT 1;

    RAISE NOTICE '🚀 Creating loan demo data...';
    RAISE NOTICE '📌 Tenant: %', v_tenant_id;

    -- ============================================================
    -- SECTION 1: Additional Customers
    -- ============================================================
    
    INSERT INTO contact (tenant_id, id, is_company, name, display_name, email, phone, mobile, street, city, country_code, created_by, assignee_id, created_at)
    VALUES 
        (v_tenant_id, v_cust4_id, FALSE, 'Trần Văn B', 'Trần Văn B', 'tranvanb@gmail.com', NULL, '0909111222', '100 Lê Duẩn', 'Hồ Chí Minh', 'VN', v_admin_id, v_admin_id, now()),
        (v_tenant_id, v_cust5_id, TRUE, 'Công ty TNHH DEF', 'DEF Company', 'info@def.com', '0283456789', NULL, '200 Điện Biên Phủ', 'Hà Nội', 'VN', v_admin_id, v_admin_id, now()),
        (v_tenant_id, v_cust6_id, FALSE, 'Nguyễn Thị C', 'Nguyễn Thị C', 'nguyenthic@yahoo.com', NULL, '0912345678', '300 Hoàng Văn Thụ', 'Đà Nẵng', 'VN', v_admin_id, v_admin_id, now()),
        (v_tenant_id, v_cust7_id, TRUE, 'Công ty CP GHI', 'GHI Corp', 'contact@ghi.vn', '0287654321', NULL, '400 Nguyễn Trãi', 'Hồ Chí Minh', 'VN', v_admin_id, v_admin_id, now()),
        (v_tenant_id, v_cust8_id, FALSE, 'Phạm Văn D', 'Phạm Văn D', 'phamvand@hotmail.com', NULL, '0908765432', '500 Lý Tự Trọng', 'Cần Thơ', 'VN', v_admin_id, v_admin_id, now()),
        (v_tenant_id, v_cust9_id, TRUE, 'Công ty TNHH JKL', 'JKL Ltd', 'sales@jkl.vn', '0289876543', NULL, '600 Hai Bà Trưng', 'Hà Nội', 'VN', v_admin_id, v_admin_id, now()),
        (v_tenant_id, v_cust10_id, FALSE, 'Lê Thị E', 'Lê Thị E', 'lethie@outlook.com', NULL, '0901122334', '700 Trần Phú', 'Huế', 'VN', v_admin_id, v_admin_id, now())
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    RAISE NOTICE '✅ Created 7 additional customers';

    -- ============================================================
    -- SECTION 2: 10 Loan Contracts with Transactions
    -- ============================================================
    
    -- Contract 1: 100M VND, 18%, Active (LOAN/2025/0001)
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start, date_end,
        current_principal, current_interest, accumulated_interest,
        total_paid_interest, total_settlement_amount,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan1_id, v_customer1_id, 'LOAN/2025/0001',
        18.0, 12, '2025-09-01'::date, '2026-09-01'::date,
        100000000, 5000000, 15000000, 10000000, 0,
        'active', v_admin_id, v_manager_id, '2025-09-01'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- Transactions for Loan 1
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan1_id, v_customer1_id, 'disbursement', 100000000, '2025-09-01'::date, 'Giải ngân lần 1', 0, 0, 0, 100000000, v_admin_id, '2025-09-01'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan1_id, v_customer1_id, 'interest', 5000000, '2025-09-15'::date, 'Trả lãi tháng 9/2025', 15, 5000000, 10000000, 100000000, v_admin_id, '2025-09-15'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan1_id, v_customer1_id, 'interest', 5000000, '2025-09-30'::date, 'Trả lãi tháng 9/2025 (cuối tháng)', 15, 5000000, 15000000, 100000000, v_admin_id, '2025-09-30'::timestamptz)
    ON CONFLICT DO NOTHING;
    
    -- Contract 2: 50M VND, 15%, Active (LOAN/2025/0002)
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan2_id, v_customer2_id, 'LOAN/2025/0002',
        15.0, 24, '2025-09-10'::date,
        50000000, 2000000, 8000000,
        'active', v_admin_id, v_manager_id, '2025-09-10'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- Transactions for Loan 2
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan2_id, v_customer2_id, 'disbursement', 50000000, '2025-09-10'::date, 'Giải ngân', 0, 0, 0, 50000000, v_admin_id, '2025-09-10'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan2_id, v_customer2_id, 'interest', 2000000, '2025-09-20'::date, 'Trả lãi lần 1', 10, 2000000, 2000000, 50000000, v_admin_id, '2025-09-20'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan2_id, v_customer2_id, 'interest', 2000000, '2025-10-01'::date, 'Trả lãi lần 2', 11, 2000000, 4000000, 50000000, v_admin_id, '2025-10-01'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan2_id, v_customer2_id, 'interest', 2000000, '2025-10-10'::date, 'Trả lãi lần 3', 9, 2000000, 6000000, 50000000, v_admin_id, '2025-10-10'::timestamptz)
    ON CONFLICT DO NOTHING;
    
    -- Contract 3: 20M VND, 20%, Draft (LOAN/2025/0003)
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan3_id, v_customer3_id, 'LOAN/2025/0003',
        20.0, 6, '2025-10-01'::date,
        20000000, 'draft', v_admin_id, v_sales_id, '2025-10-01'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    RAISE NOTICE '✅ Loan 1-3 created (LOAN/2025/0001-0003)';

    -- Contract 4: 80M VND, 16%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start, date_end,
        current_principal, current_interest, accumulated_interest,
        total_paid_interest, total_settlement_amount,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan4_id, v_cust4_id, 'LOAN/2025/0004',
        16.0, 12, '2025-09-05'::date, '2026-09-05'::date,
        80000000, 4000000, 12000000, 8000000, 0,
        'active', v_admin_id, v_admin_id, '2025-09-05'::timestamptz
    )
    ON CONFLICT (tenant_id, id) DO NOTHING;
    
    -- Transactions for Loan 4
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan4_id, v_cust4_id, 'disbursement', 80000000, '2025-09-05'::date, 'Giải ngân', 0, 0, 0, 80000000, v_admin_id, '2025-09-05'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan4_id, v_cust4_id, 'interest', 3000000, '2025-09-15'::date, 'Trả lãi lần 1', 10, 3000000, 3000000, 80000000, v_admin_id, '2025-09-15'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan4_id, v_cust4_id, 'interest', 3000000, '2025-09-25'::date, 'Trả lãi lần 2', 10, 3000000, 6000000, 80000000, v_admin_id, '2025-09-25'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan4_id, v_cust4_id, 'interest', 2000000, '2025-10-01'::date, 'Trả lãi tháng 10', 6, 3000000, 9000000, 80000000, v_admin_id, '2025-10-01'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan4_id, v_cust4_id, 'principal', 10000000, '2025-10-02'::date, 'Trả gốc một phần', 1, 1000000, 10000000, 70000000, v_admin_id, '2025-10-02'::timestamptz);

    -- Contract 5: 150M VND, 14%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan5_id, v_cust5_id, 'LOAN/2025/0005',
        14.0, 24, '2025-09-08'::date,
        150000000, 8000000, 20000000,
        'active', v_admin_id, v_admin_id, '2025-09-08'::timestamptz
    );
    
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan5_id, v_cust5_id, 'disbursement', 150000000, '2025-09-08'::date, 'Giải ngân đầy đủ', 0, 0, 0, 150000000, v_admin_id, '2025-09-08'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan5_id, v_cust5_id, 'interest', 5000000, '2025-09-18'::date, 'Trả lãi kỳ 1', 10, 5000000, 5000000, 150000000, v_admin_id, '2025-09-18'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan5_id, v_cust5_id, 'interest', 5000000, '2025-09-28'::date, 'Trả lãi kỳ 2', 10, 5000000, 10000000, 150000000, v_admin_id, '2025-09-28'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan5_id, v_cust5_id, 'additional', 30000000, '2025-10-03'::date, 'Giải ngân bổ sung', 5, 2000000, 12000000, 180000000, v_admin_id, '2025-10-03'::timestamptz);

    -- Contract 6: 60M VND, 19%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan6_id, v_cust6_id, 'LOAN/2025/0006',
        19.0, 6, '2025-09-12'::date,
        60000000, 3000000, 9000000,
        'active', v_admin_id, v_admin_id, '2025-09-12'::timestamptz
    );
    
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan6_id, v_cust6_id, 'disbursement', 60000000, '2025-09-12'::date, 'Giải ngân', 0, 0, 0, 60000000, v_admin_id, '2025-09-12'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan6_id, v_cust6_id, 'interest', 3000000, '2025-09-20'::date, 'Trả lãi lần 1', 8, 3000000, 3000000, 60000000, v_admin_id, '2025-09-20'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan6_id, v_cust6_id, 'interest', 3000000, '2025-09-28'::date, 'Trả lãi lần 2', 8, 3000000, 6000000, 60000000, v_admin_id, '2025-09-28'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan6_id, v_cust6_id, 'interest', 3000000, '2025-10-03'::date, 'Trả lãi tháng 10', 5, 3000000, 9000000, 60000000, v_admin_id, '2025-10-03'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan6_id, v_cust6_id, 'principal', 20000000, '2025-10-04'::date, 'Trả gốc', 1, 1000000, 10000000, 40000000, v_admin_id, '2025-10-04'::timestamptz);

    -- Contract 7: 200M VND, 13%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan7_id, v_cust7_id, 'LOAN/2025/0007',
        13.0, 36, '2025-09-15'::date,
        200000000, 7000000, 25000000,
        'active', v_admin_id, v_admin_id, '2025-09-15'::timestamptz
    );
    
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan7_id, v_cust7_id, 'disbursement', 200000000, '2025-09-15'::date, 'Giải ngân', 0, 0, 0, 200000000, v_admin_id, '2025-09-15'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan7_id, v_cust7_id, 'interest', 7000000, '2025-09-22'::date, 'Trả lãi lần 1', 7, 7000000, 7000000, 200000000, v_admin_id, '2025-09-22'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan7_id, v_cust7_id, 'interest', 7000000, '2025-09-29'::date, 'Trả lãi lần 2', 7, 7000000, 14000000, 200000000, v_admin_id, '2025-09-29'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan7_id, v_cust7_id, 'interest', 6000000, '2025-10-02'::date, 'Trả lãi', 3, 6000000, 20000000, 200000000, v_admin_id, '2025-10-02'::timestamptz);

    -- Contract 8: 40M VND, 21%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan8_id, v_cust8_id, 'LOAN/2025/0008',
        21.0, 3, '2025-09-18'::date,
        40000000, 2000000, 4000000,
        'active', v_admin_id, v_admin_id, '2025-09-18'::timestamptz
    );
    
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan8_id, v_cust8_id, 'disbursement', 40000000, '2025-09-18'::date, 'Giải ngân', 0, 0, 0, 40000000, v_admin_id, '2025-09-18'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan8_id, v_cust8_id, 'interest', 2000000, '2025-09-25'::date, 'Trả lãi lần 1', 7, 2000000, 2000000, 40000000, v_admin_id, '2025-09-25'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan8_id, v_cust8_id, 'interest', 2000000, '2025-10-01'::date, 'Trả lãi tháng 10', 6, 2000000, 4000000, 40000000, v_admin_id, '2025-10-01'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan8_id, v_cust8_id, 'principal', 10000000, '2025-10-03'::date, 'Trả gốc một phần', 2, 500000, 4500000, 30000000, v_admin_id, '2025-10-03'::timestamptz);

    -- Contract 9: 120M VND, 17%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan9_id, v_cust9_id, 'LOAN/2025/0009',
        17.0, 18, '2025-09-20'::date,
        120000000, 5000000, 18000000,
        'active', v_admin_id, v_admin_id, '2025-09-20'::timestamptz
    );
    
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan9_id, v_cust9_id, 'disbursement', 120000000, '2025-09-20'::date, 'Giải ngân', 0, 0, 0, 120000000, v_admin_id, '2025-09-20'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan9_id, v_cust9_id, 'interest', 5000000, '2025-09-27'::date, 'Trả lãi', 7, 5000000, 5000000, 120000000, v_admin_id, '2025-09-27'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan9_id, v_cust9_id, 'additional', 20000000, '2025-09-30'::date, 'Giải ngân bổ sung', 3, 3000000, 8000000, 140000000, v_admin_id, '2025-09-30'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan9_id, v_cust9_id, 'interest', 5000000, '2025-10-02'::date, 'Trả lãi', 2, 5000000, 13000000, 140000000, v_admin_id, '2025-10-02'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan9_id, v_cust9_id, 'interest', 5000000, '2025-10-04'::date, 'Trả lãi', 2, 5000000, 18000000, 140000000, v_admin_id, '2025-10-04'::timestamptz);

    -- Contract 10: 90M VND, 15%, Active
    INSERT INTO loan_contract (
        tenant_id, id, contact_id, contract_number,
        interest_rate, term_months, date_start,
        current_principal, current_interest, accumulated_interest,
        state, created_by, assignee_id, created_at
    )
    VALUES (
        v_tenant_id, v_loan10_id, v_cust10_id, 'LOAN/2025/0010',
        15.0, 12, '2025-09-25'::date,
        90000000, 4000000, 12000000,
        'active', v_admin_id, v_admin_id, '2025-09-25'::timestamptz
    );
    
    INSERT INTO loan_transaction (tenant_id, id, contract_id, contact_id, transaction_type, amount, date, note, days_from_prev, interest_for_period, accumulated_interest, principal_balance, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), v_loan10_id, v_cust10_id, 'disbursement', 90000000, '2025-09-25'::date, 'Giải ngân', 0, 0, 0, 90000000, v_admin_id, '2025-09-25'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan10_id, v_cust10_id, 'interest', 4000000, '2025-09-28'::date, 'Trả lãi lần 1', 3, 4000000, 4000000, 90000000, v_admin_id, '2025-09-28'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan10_id, v_cust10_id, 'interest', 4000000, '2025-10-01'::date, 'Trả lãi tháng 10', 3, 4000000, 8000000, 90000000, v_admin_id, '2025-10-01'::timestamptz),
        (v_tenant_id, gen_random_uuid(), v_loan10_id, v_cust10_id, 'interest', 4000000, '2025-10-04'::date, 'Trả lãi lần 3', 3, 4000000, 12000000, 90000000, v_admin_id, '2025-10-04'::timestamptz);

    RAISE NOTICE '✅ Created 7 new loan contracts (total 10)';
    RAISE NOTICE '   - Each with 4-5 transactions';

    -- ============================================================
    -- SECTION 3: Collateral Assets (3-4 per contract)
    -- ============================================================
    
    -- Collaterals for Loan 4
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe ô tô Honda City 2020', 450000000, v_cust4_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'property', 'Nhà cấp 4 tại Q.Bình Thạnh', 2500000000, v_cust4_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'gold', 'Vàng SJC 5 chỉ', 150000000, v_cust4_id, 'pledged', v_admin_id, now());

    -- Link to contract 4
    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan4_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust4_id AND status = 'pledged';

    -- Collaterals for Loan 5
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'property', 'Đất nông nghiệp 500m2 tại Long An', 800000000, v_cust5_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'equipment', 'Máy móc sản xuất nhựa', 600000000, v_cust5_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe tải Hyundai 5 tấn', 350000000, v_cust5_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'stock', 'Cổ phiếu VNM 10,000 cp', 1200000000, v_cust5_id, 'pledged', v_admin_id, now());

    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan5_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust5_id AND status = 'pledged';

    -- Collaterals for Loan 6
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'jewelry', 'Nhẫn kim cương 3 carat', 300000000, v_cust6_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'watch', 'Đồng hồ Rolex Submariner', 250000000, v_cust6_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe máy SH 2023', 80000000, v_cust6_id, 'pledged', v_admin_id, now());

    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan6_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust6_id AND status = 'pledged';

    -- Collaterals for Loan 7
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'property', 'Căn hộ chung cư 80m2 Q.2', 4500000000, v_cust7_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe ô tô Mercedes C200', 1200000000, v_cust7_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'equipment', 'Hệ thống máy tính văn phòng', 200000000, v_cust7_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'gold', 'Vàng 9999 - 10 chỉ', 300000000, v_cust7_id, 'pledged', v_admin_id, now());

    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan7_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust7_id AND status = 'pledged';

    -- Collaterals for Loan 8
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'electronics', 'Laptop MacBook Pro 2023', 50000000, v_cust8_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'jewelry', 'Dây chuyền vàng 5 chỉ', 100000000, v_cust8_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe máy Yamaha Exciter', 45000000, v_cust8_id, 'pledged', v_admin_id, now());

    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan8_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust8_id AND status = 'pledged';

    -- Collaterals for Loan 9
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'property', 'Nhà phố 1 trệt 1 lầu tại Gò Vấp', 3200000000, v_cust9_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe ô tô Toyota Vios 2021', 500000000, v_cust9_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'equipment', 'Máy photocopy Ricoh', 80000000, v_cust9_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'stock', 'Cổ phiếu FPT 5,000 cp', 400000000, v_cust9_id, 'pledged', v_admin_id, now());

    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan9_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust9_id AND status = 'pledged';

    -- Collaterals for Loan 10
    INSERT INTO collateral_assets (tenant_id, asset_id, asset_type, description, value_estimate, owner_contact_id, status, created_by, created_at)
    VALUES 
        (v_tenant_id, gen_random_uuid(), 'property', 'Đất thổ cư 200m2 tại Bình Dương', 1800000000, v_cust10_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'gold', 'Vàng SJC 8 chỉ', 240000000, v_cust10_id, 'pledged', v_admin_id, now()),
        (v_tenant_id, gen_random_uuid(), 'vehicle', 'Xe máy Honda Vision', 35000000, v_cust10_id, 'pledged', v_admin_id, now());

    INSERT INTO loan_collateral (tenant_id, contract_id, asset_id, status, created_by, created_at)
    SELECT v_tenant_id, v_loan10_id, asset_id, 'active', v_admin_id, now()
    FROM collateral_assets 
    WHERE tenant_id = v_tenant_id AND owner_contact_id = v_cust10_id AND status = 'pledged';

    RAISE NOTICE '✅ Created collateral assets (3-4 per contract)';

    -- ============================================================
    -- FINAL SUMMARY
    -- ============================================================
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ============================================================';
    RAISE NOTICE '🎉 LOAN DEMO DATA CREATED SUCCESSFULLY!';
    RAISE NOTICE '🎉 ============================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '   - Additional Customers: 7';
    RAISE NOTICE '   - Total Loan Contracts: 10 (LOAN/2025/0001 - LOAN/2025/0010)';
    RAISE NOTICE '   - Transactions per contract: 4-5';
    RAISE NOTICE '   - Collateral assets per contract: 3-4';
    RAISE NOTICE '   - Tenant: system (%)', v_tenant_id;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Ready to test with comprehensive loan data!';
    RAISE NOTICE '';
    
END $$;

-- ============================================================
-- ✅ DONE: More Loan Data Creation Complete
-- ============================================================

