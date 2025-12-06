#!/bin/bash

# Test WASM Integration Script
# Test các WASM functions của sale module

BASE_URL="http://localhost:3000"
MODULE="sale"

echo "🧪 Testing WASM Integration for $MODULE module"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Get module metadata
echo "📋 Test 1: Get module metadata"
echo "GET $BASE_URL/$MODULE/metadata"
RESPONSE=$(curl -s "$BASE_URL/$MODULE/metadata")
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo "Response: $RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${RED}✗ Failed${NC}"
fi
echo ""

# Test 2: Calculate line totals
echo "📊 Test 2: Calculate line totals"
echo "POST $BASE_URL/$MODULE/wasm/calculate_line"
echo "Args: qty=10, unit_price=100, tax_rate=10"
RESPONSE=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/calculate_line" \
    -H "Content-Type: application/json" \
    -d '{"args": [10.0, 100.0, 10.0]}')
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo "Response: $RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${RED}✗ Failed${NC}"
fi
echo ""

# Test 3: Validate state transition (valid)
echo "✅ Test 3: Validate state transition (valid: draft → sent)"
RESPONSE=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/validate_transition" \
    -H "Content-Type: application/json" \
    -d '{"args": ["draft", "sent"]}')
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo "Response: $RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${RED}✗ Failed${NC}"
fi
echo ""

# Test 4: Validate state transition (invalid)
echo "❌ Test 4: Validate state transition (invalid: draft → done)"
RESPONSE=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/validate_transition" \
    -H "Content-Type: application/json" \
    -d '{"args": ["draft", "done"]}')
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo "Response: $RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${RED}✗ Failed${NC}"
fi
echo ""

# Test 5: Apply discount
echo "💰 Test 5: Apply discount"
echo "Args: price_unit=100, discount_percent=10"
RESPONSE=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/apply_line_discount" \
    -H "Content-Type: application/json" \
    -d '{"args": [100.0, 10.0]}')
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo "Response: $RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${RED}✗ Failed${NC}"
fi
echo ""

# Test 6: Calculate multiple lines
echo "📝 Test 6: Calculate multiple lines"
echo "Line 1: qty=5, price=200, tax=5%"
RESPONSE1=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/calculate_line" \
    -H "Content-Type: application/json" \
    -d '{"args": [5.0, 200.0, 5.0]}')
echo "Response: $RESPONSE1" | jq '.' 2>/dev/null || echo "$RESPONSE1"

echo "Line 2: qty=3, price=150, tax=10%"
RESPONSE2=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/calculate_line" \
    -H "Content-Type: application/json" \
    -d '{"args": [3.0, 150.0, 10.0]}')
echo "Response: $RESPONSE2" | jq '.' 2>/dev/null || echo "$RESPONSE2"
echo ""

# Test 7: State flow validation
echo "🔄 Test 7: Complete state flow validation"
STATES=("draft->sent" "sent->sale" "sale->done" "done->cancel")
for STATE_PAIR in "${STATES[@]}"; do
    IFS='->' read -r FROM TO <<< "$STATE_PAIR"
    echo "   Testing: $FROM → $TO"
    RESPONSE=$(curl -s -X POST "$BASE_URL/$MODULE/wasm/validate_transition" \
        -H "Content-Type: application/json" \
        -d "{\"args\": [\"$FROM\", \"$TO\"]}")
    VALID=$(echo "$RESPONSE" | jq -r '.result' | jq -r '.valid' 2>/dev/null)
    if [ "$VALID" == "true" ]; then
        echo -e "   ${GREEN}✓ Valid${NC}"
    else
        echo -e "   ${RED}✗ Invalid${NC}"
    fi
done
echo ""

echo "=============================================="
echo -e "${YELLOW}🎉 Tests completed!${NC}"
echo ""
echo "Để xem logs backend: tail -f logs/app.log"
echo "Để rebuild WASM: cd modules/sale && ./build.sh"

