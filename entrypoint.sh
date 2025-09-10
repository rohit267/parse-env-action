#!/bin/bash

# Exit immediately if a command fails
set -e

# --- Core Parsing Logic ---
# This function reads from standard input, finds KEY=VALUE pairs,
# and collects them into the specified output format.
parse_and_collect_outputs() {
  local format="${INPUT_OUTPUT_FORMAT:-json}"
  local json_pairs=()
  local env_pairs=()
  
  while IFS= read -r line || [[ -n "$line" ]]; do
      # Trim leading/trailing whitespace
      trimmed_line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

      # Ignore comments and empty lines
      if [[ -z "$trimmed_line" || "$trimmed_line" =~ ^# ]]; then
          continue
      fi

      # Check for KEY=VALUE format
      if [[ "$trimmed_line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
          key=$(echo "$trimmed_line" | cut -d '=' -f 1)
          value=$(echo "$trimmed_line" | cut -d '=' -f 2-)

          # Remove potential surrounding quotes from the value
          value=$(echo "$value" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')

          echo "Found variable: $key" >&2

          # Store for different output formats
          env_pairs+=("$key=$value")
          
          # Escape special characters for JSON
          escaped_key=$(echo "$key" | sed 's/\\/\\\\/g; s/"/\\"/g')
          escaped_value=$(echo "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
          json_pairs+=("\"$escaped_key\":\"$escaped_value\"")
      else
          echo "::warning::Skipping malformed line: '$trimmed_line'" >&2
      fi
  done
  
  # Output in the requested format
  case "$format" in
    "json")
      if [ ${#json_pairs[@]} -eq 0 ]; then
          echo "{}"
      else
          IFS=','
          echo "{${json_pairs[*]}}"
      fi
      ;;
    "env"|"dotenv")
      printf '%s\n' "${env_pairs[@]}"
      ;;
    "shell")
      for pair in "${env_pairs[@]}"; do
        echo "export $pair"
      done
      ;;
    "yaml")
      if [ ${#env_pairs[@]} -eq 0 ]; then
          echo "{}"
      else
          for pair in "${env_pairs[@]}"; do
            key=$(echo "$pair" | cut -d '=' -f 1)
            value=$(echo "$pair" | cut -d '=' -f 2-)
            # Escape special YAML characters in value
            escaped_value=$(echo "$value" | sed 's/"/\\"/g')
            # Quote value if it contains special characters
            if [[ "$escaped_value" =~ [[:space:]:\[\]{}] ]] || [[ "$escaped_value" =~ ^[0-9] ]] || [[ "$escaped_value" =~ ^(true|false|null)$ ]]; then
              echo "$key: \"$escaped_value\""
            else
              echo "$key: $escaped_value"
            fi
          done
      fi
      ;;
    *)
      echo "::error::Unsupported output format: $format. Supported formats: json, env, dotenv, shell, yaml" >&2
      exit 1
      ;;
  esac
}

# --- Main Script Execution ---

echo "Parsing variables from 'to-parse' input..." >&2
echo "Looking for content within a '\`\`\`ENV' block..." >&2
echo "Output format: ${INPUT_OUTPUT_FORMAT:-json}" >&2

# Use awk to extract the content between the ENV markdown fences.
# For example, ```ENV ... ```
EXTRACTED_CONTENT=$(echo "$INPUT_TO_PARSE" | awk '
    # Match the opening fence ```ENV
    /^```ENV$/ { 
        in_block=1; 
        next 
    }
    # Match the closing fence
    in_block && /^```$/ { 
        exit 
    }
    # If we are in the block, print the line
    in_block { 
        print 
    }
')

if [ -z "$EXTRACTED_CONTENT" ]; then
    echo "::notice::Could not find a '\`\`\`ENV' block to parse. Returning empty result." >&2
    case "${INPUT_OUTPUT_FORMAT:-json}" in
        "json") echo "{}" ;;
        "env"|"dotenv"|"shell") echo "" ;;
        "yaml") echo "{}" ;;
    esac
    exit 0
fi

echo "Successfully extracted content from ENV block. Now parsing for variables." >&2

# Pipe the extracted content into our parsing function and capture output
OUTPUT=$(echo "$EXTRACTED_CONTENT" | parse_and_collect_outputs)

# Output the result
echo "$OUTPUT"

# Also set as GitHub Action output if GITHUB_OUTPUT is available
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "VARS<<EOF" >> "$GITHUB_OUTPUT"
    echo "$OUTPUT" >> "$GITHUB_OUTPUT"
    echo "EOF" >> "$GITHUB_OUTPUT"
    echo "Set VARS output for GitHub Actions." >&2
fi

echo "Parsing complete." >&2

