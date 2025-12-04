#!/usr/bin/env python3
"""Remove duplicate PRIMARY KEY constraints from migration files"""

import re
from pathlib import Path

def remove_duplicates(file_path):
    """Remove duplicate PRIMARY KEY constraints"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find duplicate ADD CONSTRAINT patterns
    pattern = r'(ALTER TABLE ONLY public\.\w+\s+ADD CONSTRAINT \w+_pkey PRIMARY KEY \([^)]+\);)\s*\n\1'
    
    # Remove duplicates
    content = re.sub(pattern, r'\1', content, flags=re.MULTILINE)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Cleaned: {file_path.name}")

def main():
    migrations_dir = Path('/home/milan/milan/backend/migrations')
    
    files = [
        '20251205000000_product.sql',
        '20251205000001_stock.sql',
        '20251205000002_sale.sql',
        '20251205000003_purchase.sql',
    ]
    
    print("🧹 Removing duplicate PRIMARY KEY constraints...")
    for filename in files:
        filepath = migrations_dir / filename
        if filepath.exists():
            remove_duplicates(filepath)
    
    print("✅ Done!")

if __name__ == '__main__':
    main()

