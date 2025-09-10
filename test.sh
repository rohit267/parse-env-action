#!/bin/bash

echo "Testing parse-env script with multiple output formats..."
echo "======================================================"

# Test data
export INPUT_TO_PARSE='Some intro text

```ENV
# This is a comment
API_KEY="secret-key-123"
DATABASE_URL=postgres://user:pass@localhost:5432/db
PORT=3000
DEBUG=true
EMPTY_VALUE=
```

Some trailing text'

echo "Test 1: JSON format (default)"
echo "------------------------------"
export INPUT_OUTPUT_FORMAT="json"
result=$(./entrypoint.sh 2>/dev/null)
echo "Result: $result"
echo

echo "Test 2: ENV/dotenv format"
echo "-------------------------"
export INPUT_OUTPUT_FORMAT="env"
result=$(./entrypoint.sh 2>/dev/null)
echo "Result:"
echo "$result"
echo

echo "Test 3: Shell export format"
echo "---------------------------"
export INPUT_OUTPUT_FORMAT="shell"
result=$(./entrypoint.sh 2>/dev/null)
echo "Result:"
echo "$result"
echo

echo "Test 4: YAML format"
echo "-------------------"
export INPUT_OUTPUT_FORMAT="yaml"
result=$(./entrypoint.sh 2>/dev/null)
echo "Result:"
echo "$result"
echo

echo "Test 5: Using test.md file with JSON"
echo "------------------------------------"
export INPUT_TO_PARSE="$(cat test.md)"
export INPUT_OUTPUT_FORMAT="json"
result=$(./entrypoint.sh 2>/dev/null)
echo "Result: $result"
echo

echo "Test 6: Invalid format"
echo "----------------------"
export INPUT_OUTPUT_FORMAT="invalid"
result=$(./entrypoint.sh 2>&1)
echo "Result: $result"
echo

echo "Test 7: No ENV block found"
echo "--------------------------"
export INPUT_TO_PARSE='Just some regular text without any ENV block'
export INPUT_OUTPUT_FORMAT="json"
result=$(./entrypoint.sh 2>/dev/null)
echo "Result: $result"

echo
echo "Testing complete!"
