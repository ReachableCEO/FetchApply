# TSYS FetchApply Testing Framework

## Overview

This testing framework provides comprehensive validation for the TSYS FetchApply infrastructure provisioning system. It includes unit tests, integration tests, security tests, and system validation.

## Test Categories

### 1. Unit Tests (`unit/`)
- **Purpose:** Test individual framework functions and components
- **Scope:** Framework includes, helper functions, syntax validation
- **Example:** `framework-functions.sh` - Tests logging, pretty print, and error handling functions

### 2. Integration Tests (`integration/`)
- **Purpose:** Test complete workflows and module interactions
- **Scope:** End-to-end deployment scenarios, module integration
- **Future:** Module interaction testing, deployment workflow validation

### 3. Security Tests (`security/`)
- **Purpose:** Validate security configurations and practices
- **Scope:** HTTPS enforcement, deployment security, SSH hardening
- **Example:** `https-enforcement.sh` - Validates all URLs use HTTPS

### 4. Validation Tests (`validation/`)
- **Purpose:** System compatibility and pre-flight checks
- **Scope:** System requirements, network connectivity, permissions
- **Example:** `system-requirements.sh` - Validates minimum system requirements

## Usage

### Run All Tests
```bash
./Project-Tests/run-tests.sh
```

### Run Specific Test Categories
```bash
./Project-Tests/run-tests.sh unit          # Unit tests only
./Project-Tests/run-tests.sh integration   # Integration tests only
./Project-Tests/run-tests.sh security      # Security tests only
./Project-Tests/run-tests.sh validation    # Validation tests only
```

### Run Individual Tests
```bash
./Project-Tests/validation/system-requirements.sh
./Project-Tests/security/https-enforcement.sh
./Project-Tests/unit/framework-functions.sh
```

## Test Results

- **Console Output:** Real-time test results with color-coded status
- **JSON Reports:** Detailed test reports saved to `logs/tests/`
- **Exit Codes:** 0 for success, 1 for failures

## Configuration Validation

The validation framework performs pre-flight checks to ensure system compatibility:

### System Requirements
- **Memory:** Minimum 2GB RAM
- **Disk Space:** Minimum 10GB available
- **OS Compatibility:** Ubuntu/Debian (tested), others (may work)

### Network Connectivity
- Tests connection to required download sources
- Validates HTTPS endpoints are accessible
- Checks for firewall/proxy issues

### Command Dependencies
- Verifies required tools are installed (`curl`, `wget`, `git`, `systemctl`, `apt-get`)
- Checks for proper versions where applicable

### Permissions
- Validates write access to system directories
- Checks for required administrative privileges

## Adding New Tests

### Test File Structure
```bash
#!/bin/bash
set -euo pipefail

function test_something() {
    echo "🔍 Testing something..."
    
    if [[ condition ]]; then
        echo "✅ Test passed"
        return 0
    else
        echo "❌ Test failed"
        return 1
    fi
}

function main() {
    echo "🧪 Running Test Suite Name"
    echo "=========================="
    
    local total_failures=0
    test_something || ((total_failures++))
    
    echo "=========================="
    if [[ $total_failures -eq 0 ]]; then
        echo "✅ All tests passed"
        exit 0
    else
        echo "❌ $total_failures tests failed"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Test Categories Guidelines

- **Unit Tests:** Focus on individual functions, fast execution
- **Integration Tests:** Test module interactions, longer execution
- **Security Tests:** Validate security configurations
- **Validation Tests:** Pre-flight system checks

## Continuous Integration

The testing framework is designed to integrate with CI/CD pipelines:

```bash
# Example CI script
./Project-Tests/run-tests.sh all
test_exit_code=$?

if [[ $test_exit_code -eq 0 ]]; then
    echo "All tests passed - deployment approved"
else
    echo "Tests failed - deployment blocked"
    exit 1
fi
```

## Test Development Best Practices

1. **Clear Test Names:** Use descriptive function names
2. **Proper Exit Codes:** Return 0 for success, 1 for failure
3. **Informative Output:** Use emoji and clear messages
4. **Timeout Protection:** Use timeout for network operations
5. **Cleanup:** Remove temporary files and resources
6. **Error Handling:** Use `set -euo pipefail` for strict error handling

## Troubleshooting

### Common Issues

- **Permission Denied:** Run tests with appropriate privileges
- **Network Timeouts:** Check firewall and proxy settings
- **Missing Dependencies:** Install required tools before testing
- **Script Errors:** Validate syntax with `bash -n script.sh`

### Debug Mode
```bash
# Enable debug output
export DEBUG=1
./Project-Tests/run-tests.sh
```

## Contributing

When adding new functionality to FetchApply:

1. Add corresponding tests in appropriate category
2. Run full test suite before committing
3. Update documentation for new test cases
4. Ensure tests pass in clean environment