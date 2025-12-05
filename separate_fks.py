#!/usr/bin/env python3
"""
Separate FK constraints into separate migration file
This allows all tables to be created first, then FKs added later
"""

import re
from pathlib import Path

def extract_fks_from_file(file_path: Path) -> list:
    """Extract all FK constraints from a file"""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find FK section
    fk_section_pattern = r'-- ={60,}\n-- FOREIGN KEY CONSTRAINTS.*?\n-- ={60,}(.*?)(?=\n-- ={60,}|\Z)'
    
    fks = []
    match = re.search(fk_section_pattern, content, re.DOTALL)
    
    if match:
        fk_section = match.group(1)
        
        # Extract individual FK statements
        fk_pattern = r'(-- .*?\n)?ALTER TABLE public\.\w+[^;]+;'
        for fk_match in re.finditer(fk_pattern, fk_section, re.DOTALL):
            fks.append(fk_match.group(0).strip())
    
    # Remove FK section from original file
    content = re.sub(fk_section_pattern, '', content, flags=re.DOTALL)
    
    # Clean up extra blank lines
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return fks

def main():
    migrations_dir = Path('/home/milan/milan/backend/migrations')
    
    print("=" * 70)
    print("📦 SEPARATING FK CONSTRAINTS INTO SEPARATE FILE")
    print("=" * 70)
    
    files = [
        '20251205000000_product.sql',
        '20251205000001_stock.sql',
        '20251205000002_sale.sql',
        '20251205000003_purchase.sql',
    ]
    
    all_fks = []
    
    # Extract FKs from each file
    for filename in files:
        filepath = migrations_dir / filename
        if filepath.exists():
            fks = extract_fks_from_file(filepath)
            print(f"\n📝 {filename}")
            print(f"  ✓ Extracted {len(fks)} FK constraints")
            all_fks.extend(fks)
    
    # Create new FK migration file
    fk_file = migrations_dir / '20251205000004_add_foreign_keys.sql'
    
    with open(fk_file, 'w', encoding='utf-8') as f:
        f.write("""-- ============================================================
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
-- ============================================================

""")
        
        # Group FKs by module
        product_fks = [fk for fk in all_fks if 'product_' in fk]
        stock_fks = [fk for fk in all_fks if 'stock_' in fk]
        sale_fks = [fk for fk in all_fks if 'sale_' in fk]
        purchase_fks = [fk for fk in all_fks if 'purchase_' in fk]
        
        if product_fks:
            f.write("-- ============================================================\n")
            f.write("-- PRODUCT MODULE FOREIGN KEYS\n")
            f.write("-- ============================================================\n\n")
            for fk in product_fks:
                f.write(fk + "\n\n")
        
        if stock_fks:
            f.write("\n-- ============================================================\n")
            f.write("-- STOCK MODULE FOREIGN KEYS\n")
            f.write("-- ============================================================\n\n")
            for fk in stock_fks:
                f.write(fk + "\n\n")
        
        if sale_fks:
            f.write("\n-- ============================================================\n")
            f.write("-- SALE MODULE FOREIGN KEYS\n")
            f.write("-- ============================================================\n\n")
            for fk in sale_fks:
                f.write(fk + "\n\n")
        
        if purchase_fks:
            f.write("\n-- ============================================================\n")
            f.write("-- PURCHASE MODULE FOREIGN KEYS\n")
            f.write("-- ============================================================\n\n")
            for fk in purchase_fks:
                f.write(fk + "\n\n")
    
    print("\n" + "=" * 70)
    print(f"✅ Created: 20251205000004_add_foreign_keys.sql")
    print("=" * 70)
    print(f"\nTotal FK constraints: {len(all_fks)}")
    print(f"  • Product: {len(product_fks)}")
    print(f"  • Stock: {len(stock_fks)}")
    print(f"  • Sale: {len(sale_fks)}")
    print(f"  • Purchase: {len(purchase_fks)}")
    print("\n📝 Migration order:")
    print("  1. Tables created (files 0-3)")
    print("  2. FKs added (file 4)")
    print("\nThis resolves all dependency issues! 🎉")

if __name__ == '__main__':
    main()

