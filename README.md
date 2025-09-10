# Extract ENV Variables Action

[![GitHub release](https://img.shields.io/github/v/release/rohit267/parse-env-action)](https://github.com/rohit267/parse-env-action/releases)
[![GitHub marketplace](https://img.shields.io/badge/marketplace-extract--env--variables-blue?logo=github)](https://github.com/marketplace/actions/extract-env-variables-from-pr-body)

A GitHub Action that extracts KEY=VALUE pairs from markdown code blocks in pull
request bodies or any text input and makes them available as JSON output for use
in subsequent workflow steps.

## Features

- 🔍 **Parse ENV blocks**: Extracts variables from ````ENV` markdown code blocks
- 📝 **Multiple output formats**: Returns variables as a properly formatted `json`, `env`, `dotenv`, `shell`, or `yaml`
- 🛡️ **Safe parsing**: Handles quotes, comments, and malformed lines gracefully
- 🚀 **Easy integration**: Simple input/output interface for GitHub workflows
- ✨ **Flexible**: Works with any text input, not just PR bodies

## Usage

### Basic Example

```yaml
name: Deploy with Environment Variables
on:
  pull_request:
    types: [opened, edited]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Extract ENV variables as JSON
        id: extract-env
        uses: rohit267/parse-env@latest
        with:
          to-parse: ${{ github.event.pull_request.body }}
          output-format: json # Optional, defaults to json

      - name: Use extracted variables
        run: |
          echo "Extracted variables: ${{ steps.extract-env.outputs.VARS }}"
          # Parse JSON and use variables
          API_KEY=$(echo '${{ steps.extract-env.outputs.VARS }}' | jq -r '.API_KEY // empty')
          if [ -n "$API_KEY" ]; then
            echo "API_KEY found: $API_KEY"
          fi
```

### Example with Different Output Formats

```yaml
name: Multi-format Environment Setup
on:
  pull_request:
    types: [opened, edited]

jobs:
  setup-environments:
    runs-on: ubuntu-latest
    steps:
      - name: Extract as shell exports
        id: shell-vars
        uses: rohit267/parse-env@latest
        with:
          to-parse: ${{ github.event.pull_request.body }}
          output-format: shell

      - name: Load into environment
        run: |
          # Load all variables into current shell
          eval '${{ steps.shell-vars.outputs.VARS }}'
          echo "Database: $DATABASE_URL"
          echo "API Key: $API_KEY"

      - name: Extract as dotenv for Docker
        id: dotenv-vars
        uses: rohit267/parse-env@latest
        with:
          to-parse: ${{ github.event.pull_request.body }}
          output-format: env

      - name: Create .env file and run Docker
        run: |
          echo '${{ steps.dotenv-vars.outputs.VARS }}' > .env
          docker run --env-file .env myapp:latest
```

### Advanced Example with Multiple Steps

```yaml
name: Dynamic Environment Deployment
on:
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  extract-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Extract environment variables from PR body
        id: extract-env
        uses: yourusername/parse-env@v1
        with:
          to-parse: ${{ github.event.pull_request.body }}

      - name: Set up environment
        id: setup-env
        run: |
          # Parse the JSON output and set as environment variables
          echo '${{ steps.extract-env.outputs.VARS }}' | jq -r 'to_entries[] | "\(.key)=\(.value)"' >> $GITHUB_ENV

      - name: Deploy application
        run: |
          echo "Deploying with extracted configuration..."
          echo "Database URL: $DATABASE_URL"
          echo "API Key: $API_KEY"
          echo "Debug mode: $DEBUG"
          # Your deployment commands here
```

## Input Format

The action looks for environment variables defined within ````ENV` code blocks
in your text. Here's the expected format:

### Pull Request Body Example

````markdown
## Description

This PR adds new features and requires specific environment configuration.

## Environment Variables

Please configure the following variables for this deployment:

```ENV
# Database configuration
DATABASE_URL=postgres://user:pass@localhost:5432/myapp
DATABASE_POOL_SIZE=10

# API configuration
API_KEY=your-secret-api-key-here
API_TIMEOUT=30

# Feature flags
DEBUG=true
ENABLE_LOGGING=false
PORT=3000
```
````

## Additional Notes

The deployment will use the above configuration.

````

### Supported Variable Formats

- `KEY=value` - Simple key-value pairs
- `KEY="quoted value"` - Values with quotes (quotes are removed)
- `KEY='single quoted'` - Single quoted values
- `KEY=` - Empty values (results in empty string)
- `# Comments` - Comments are ignored
- Empty lines are ignored

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `to-parse` | The string containing the markdown code block to parse (e.g., `${{ github.event.pull_request.body }}`) | ✅ | - |
| `output-format` | Output format for the variables. Supported: `json`, `env`, `dotenv`, `shell`, `yaml` | ❌ | `json` |

## Outputs

| Output | Description | Type |
|--------|-------------|------|
| `VARS` | The extracted key-value pairs in the specified format | string |

## Output Formats

### JSON Format (default)
```json
{
  "DATABASE_URL": "postgres://user:pass@localhost:5432/myapp",
  "API_KEY": "your-secret-api-key-here",
  "DEBUG": "true",
  "PORT": "3000"
}
```

### ENV/DotEnv Format
```
DATABASE_URL=postgres://user:pass@localhost:5432/myapp
API_KEY=your-secret-api-key-here
DEBUG=true
PORT=3000
```

### Shell Export Format
```bash
export DATABASE_URL=postgres://user:pass@localhost:5432/myapp
export API_KEY=your-secret-api-key-here
export DEBUG=true
export PORT=3000
```

### YAML Format
```yaml
DATABASE_URL: postgres://user:pass@localhost:5432/myapp
API_KEY: your-secret-api-key-here
DEBUG: "true"
PORT: "3000"
```

## Popular CI/CD Use Cases by Format

### JSON Format
- **GitHub Actions**: Parse with `jq` for conditional logic
- **Generic workflows**: Easy to parse in most programming languages

```yaml
- name: Extract variables as JSON
  id: vars
  uses: rohit267/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}
    output-format: json

- name: Use specific variable
  run: |
    API_KEY=$(echo '${{ steps.vars.outputs.VARS }}' | jq -r '.API_KEY // "default"')
    echo "Using API Key: $API_KEY"
```

### ENV/DotEnv Format
- **Docker**: Can be saved as `.env` file
- **Node.js**: Compatible with `dotenv` package
- **General**: Standard environment variable format

```yaml
- name: Extract as env format
  id: vars
  uses: rohit267/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}
    output-format: env

- name: Save as .env file
  run: |
    echo '${{ steps.vars.outputs.VARS }}' > .env
    docker run --env-file .env myapp
```

### Shell Export Format
- **Bash/Shell scripts**: Direct source-able format
- **CI environments**: Easy to load into shell environment

```yaml
- name: Extract as shell exports
  id: vars
  uses: rohit267/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}
    output-format: shell

- name: Load into environment
  run: |
    eval '${{ steps.vars.outputs.VARS }}'
    echo "Database URL: $DATABASE_URL"
```

### YAML Format
- **Kubernetes**: ConfigMaps and other YAML configs
- **Ansible**: Variable files
- **CI configs**: Many CI systems use YAML for configuration

```yaml
- name: Extract as YAML
  id: vars
  uses: rohit267/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}
    output-format: yaml

- name: Create ConfigMap
  run: |
    cat << EOF > configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: app-config
    data:
    $(echo '${{ steps.vars.outputs.VARS }}' | sed 's/^/  /')
    EOF
````

## Use Cases

### 1. Dynamic Environment Configuration

Allow developers to specify environment-specific configuration directly in pull
requests:

```yaml
- name: Configure environment from PR
  uses: yourusername/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}
```

### 2. Feature Flag Management

Enable/disable features based on PR specifications:

```yaml
- name: Extract feature flags
  id: flags
  uses: yourusername/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}

- name: Deploy with feature flags
  run: |
    ENABLE_FEATURE_X=$(echo '${{ steps.flags.outputs.VARS }}' | jq -r '.ENABLE_FEATURE_X // "false"')
    # Use the feature flag in deployment
```

### 3. Custom Deployment Parameters

Specify deployment parameters per PR:

```yaml
- name: Get deployment config
  id: config
  uses: yourusername/parse-env@v1
  with:
    to-parse: ${{ github.event.pull_request.body }}

- name: Deploy to custom environment
  run: |
    ENVIRONMENT=$(echo '${{ steps.config.outputs.VARS }}' | jq -r '.ENVIRONMENT // "staging"')
    REPLICAS=$(echo '${{ steps.config.outputs.VARS }}' | jq -r '.REPLICAS // "1"')
    # Deploy with custom parameters
```

## Error Handling

- **No ENV block found**: Returns empty JSON object `{}`
- **Malformed lines**: Skipped with warning message
- **Invalid syntax**: Lines not matching `KEY=VALUE` format are ignored
- **Empty values**: Preserved as empty strings in JSON

## Security Considerations

⚠️ **Important**: Be cautious when using this action with sensitive data:

- Avoid putting secrets directly in PR bodies
- Use GitHub Secrets for sensitive configuration
- Consider using this action only for non-sensitive environment configuration
- Review PR content before merging when using extracted variables

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major
changes, please open an issue first to discuss what you would like to change.

### Development

1. Clone the repository
2. Make your changes
3. Test with `./test.sh`
4. Submit a pull request

### Testing

Run the test suite:

```bash
chmod +x test.sh
./test.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## Changelog

### v1.0.0

- Initial release
- Support for extracting KEY=VALUE pairs from `ENV` blocks
- JSON output format
- Comprehensive error handling

## Support

If you encounter any issues or have questions, please
[open an issue](https://github.com/yourusername/parse-env/issues) on GitHub.

---

**Made with ❤️ for the GitHub Actions community**
