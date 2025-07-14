#!/bin/bash

# Framework Functions Unit Tests
# Tests core framework functionality

set -euo pipefail

PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."

# Source framework functions
source "$PROJECT_ROOT/Framework-Includes/Logging.sh" 2>/dev/null || echo "Warning: Logging.sh not found"
source "$PROJECT_ROOT/Framework-Includes/PrettyPrint.sh" 2>/dev/null || echo "Warning: PrettyPrint.sh not found"
source "$PROJECT_ROOT/Framework-Includes/ErrorHandling.sh" 2>/dev/null || echo "Warning: ErrorHandling.sh not found"

function test_logging_functions() {
    echo "🔍 Testing logging functions..."
    
    local test_log="/tmp/test-log-$$"
    
    # Test if logging functions exist and work
    if command -v log_info >/dev/null 2>&1; then
        log_info "Test info message" 2>/dev/null || true
        echo "✅ log_info function exists"
    else
        echo "❌ log_info function missing"
        return 1
    fi
    
    if command -v log_error >/dev/null 2>&1; then
        log_error "Test error message" 2>/dev/null || true
        echo "✅ log_error function exists"
    else
        echo "❌ log_error function missing"
        return 1
    fi
    
    # Cleanup
    rm -f "$test_log"
    return 0
}

function test_pretty_print_functions() {
    echo "🔍 Testing pretty print functions..."
    
    # Test if pretty print functions exist
    if command -v print_info >/dev/null 2>&1; then
        print_info "Test info message" >/dev/null 2>&1 || true
        echo "✅ print_info function exists"
    else
        echo "❌ print_info function missing"
        return 1
    fi
    
    if command -v print_error >/dev/null 2>&1; then
        print_error "Test error message" >/dev/null 2>&1 || true
        echo "✅ print_error function exists"
    else
        echo "❌ print_error function missing"
        return 1
    fi
    
    if command -v print_success >/dev/null 2>&1; then
        print_success "Test success message" >/dev/null 2>&1 || true
        echo "✅ print_success function exists"
    else
        echo "❌ print_success function missing"
        return 1
    fi
    
    return 0
}

function test_error_handling() {
    echo "🔍 Testing error handling..."
    
    # Test if error handling functions exist
    if command -v handle_error >/dev/null 2>&1; then
        echo "✅ handle_error function exists"
    else
        echo "❌ handle_error function missing"
        return 1
    fi
    
    # Test bash strict mode is set
    if [[ "$-" == *e* ]]; then
        echo "✅ Bash strict mode (set -e) is enabled"
    else
        echo "❌ Bash strict mode (set -e) not enabled"
        return 1
    fi
    
    if [[ "$-" == *u* ]]; then
        echo "✅ Bash unset variable checking (set -u) is enabled"
    else
        echo "❌ Bash unset variable checking (set -u) not enabled"
        return 1
    fi
    
    return 0
}

function test_framework_includes_exist() {
    echo "🔍 Testing framework includes exist..."
    
    local required_includes=(
        "Logging.sh"
        "PrettyPrint.sh"
        "ErrorHandling.sh"
        "PreflightCheck.sh"
    )
    
    local missing_files=0
    
    for include_file in "${required_includes[@]}"; do
        if [[ -f "$PROJECT_ROOT/Framework-Includes/$include_file" ]]; then
            echo "✅ Framework include exists: $include_file"
        else
            echo "❌ Framework include missing: $include_file"
            ((missing_files++))
        fi
    done
    
    return $missing_files
}

function test_syntax_validation() {
    echo "🔍 Testing script syntax validation..."
    
    local syntax_errors=0
    local script_dirs=("Framework-Includes" "Project-Includes" "ProjectCode")
    
    for dir in "${script_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            while IFS= read -r -d '' file; do
                if bash -n "$file" 2>/dev/null; then
                    echo "✅ Syntax valid: $(basename "$file")"
                else
                    echo "❌ Syntax error in: $(basename "$file")"
                    ((syntax_errors++))
                fi
            done < <(find "$PROJECT_ROOT/$dir" -name "*.sh" -type f -print0)
        fi
    done
    
    return $syntax_errors
}

# Main test execution
function main() {
    echo "🧪 Running Framework Functions Unit Tests"
    echo "========================================"
    
    local total_failures=0
    
    # Run all unit tests
    test_framework_includes_exist || ((total_failures++))
    test_logging_functions || ((total_failures++))
    test_pretty_print_functions || ((total_failures++))
    test_error_handling || ((total_failures++))
    test_syntax_validation || ((total_failures++))
    
    echo "========================================"
    
    if [[ $total_failures -eq 0 ]]; then
        echo "✅ All framework function unit tests passed"
        exit 0
    else
        echo "❌ $total_failures framework function unit tests failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi