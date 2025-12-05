#!/usr/bin/env python3
"""Restore missing CHECK constraints from original Odoo schema"""

import re
from pathlib import Path

# Missing constraints to restore
CONSTRAINTS = {
    'purchase_order_line': [
        "CONSTRAINT purchase_order_line_accountable_required_fields CHECK ((display_type IS NOT NULL) OR is_downpayment OR ((product_id IS NOT NULL) AND (product_uom_id IS NOT NULL) AND (date_planned IS NOT NULL)))",
        "CONSTRAINT purchase_order_line_non_accountable_null_fields CHECK ((display_type IS NULL) OR ((product_id IS NULL) AND (price_unit = 0) AND (product_uom_qty = 0) AND (product_uom_id IS NULL) AND (date_planned IS NULL)))"
    ],
    'stock_location': [
        "CONSTRAINT stock_location_inventory_freq_nonneg CHECK (cyclic_inventory_frequency >= 0)"
    ],
    'sale_order': [
        "CONSTRAINT sale_order_date_order_conditional_required CHECK (((state = 'sale' AND date_order IS NOT NULL) OR state != 'sale'))"
    ],
    'sale_order_line': [
        "CONSTRAINT sale_order_line_accountable_required_fields CHECK ((display_type IS NOT NULL) OR is_downpayment OR ((product_id IS NOT NULL) AND (product_uom_id IS NOT NULL)))",
        "CONSTRAINT sale_order_line_non_accountable_null_fields CHECK ((display_type IS NULL) OR ((product_id IS NULL) AND (price_unit = 0) AND (product_uom_qty = 0) AND (product_uom_id IS NULL)))"
    ],
    'sale_order_template_line': [
        "CONSTRAINT sale_order_template_line_accountable_product_id_required CHECK ((display_type IS NOT NULL) OR ((product_id IS NOT NULL) AND (product_uom_id IS NOT NULL)))",
        "CONSTRAINT sale_order_template_line_non_accountable_fields_null CHECK ((display_type IS NULL) OR ((product_id IS NULL) AND (product_uom_qty = 0) AND (product_uom_id IS NULL)))"
    ],
    'stock_package_type': [
        "CONSTRAINT stock_package_type_positive_height CHECK (height >= 0.0)",
        "CONSTRAINT stock_package_type_positive_length CHECK (packaging_length >= 0.0)",
        "CONSTRAINT stock_package_type_positive_max_weight CHECK (max_weight >= 0.0)",
        "CONSTRAINT stock_package_type_positive_width CHECK (width >= 0.0)"
    ]
}

def add_constraint_to_table(content: str, table_name: str, constraints: list) -> str:
    """Add constraints to a table's CREATE TABLE statement"""
    # Find the CREATE TABLE block for this table
    pattern = rf'(CREATE TABLE public\.{table_name} \([^;]+?)\);'
    
    def replace_table(match):
        table_def = match.group(1)
        
        # Check if constraints already exist
        for constraint in constraints:
            if constraint in table_def:
                continue
            
            # Add comma and constraint
            table_def += ',\n    ' + constraint
        
        return table_def + '\n);'
    
    content = re.sub(pattern, replace_table, content, flags=re.DOTALL)
    return content

def process_file(file_path: Path) -> int:
    """Process a migration file"""
    print(f"\n📝 Processing: {file_path.name}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    count = 0
    for table_name, constraints in CONSTRAINTS.items():
        if table_name in content:
            print(f"  → Restoring constraints for {table_name}")
            content = add_constraint_to_table(content, table_name, constraints)
            count += len(constraints)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return count

def main():
    migrations_dir = Path('/home/milan/milan/backend/migrations')
    
    print("=" * 70)
    print("🔧 RESTORING MISSING CHECK CONSTRAINTS")
    print("=" * 70)
    
    files = {
        '20251205000000_product.sql': ['product_attribute'],
        '20251205000001_stock.sql': ['stock_location', 'stock_package_type'],
        '20251205000002_sale.sql': ['sale_order', 'sale_order_line', 'sale_order_template_line'],
        '20251205000003_purchase.sql': ['purchase_order_line'],
    }
    
    total = 0
    for filename, tables in files.items():
        filepath = migrations_dir / filename
        if filepath.exists():
            count = process_file(filepath)
            total += count
            print(f"  ✓ Added {count} constraints")
    
    print("\n" + "=" * 70)
    print(f"✅ Restored {total} CHECK constraints!")
    print("=" * 70)

if __name__ == '__main__':
    main()

