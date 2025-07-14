#!/bin/bash

# TSYS FetchApply Testing Framework
# Main test runner script

set -euo pipefail

# Source framework includes
PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
source "$PROJECT_ROOT/Framework-Includes/Logging.sh"
source "$PROJECT_ROOT/Framework-Includes/PrettyPrint.sh"

# Test configuration
TEST_LOG_DIR="$PROJECT_ROOT/logs/tests"
TEST_RESULTS_FILE="$TEST_LOG_DIR/test-results-$(date +%Y%m%d-%H%M%S).json"

# Ensure test log directory exists
mkdir -p "$TEST_LOG_DIR"

# Test counters
declare -g TESTS_PASSED=0
declare -g TESTS_FAILED=0
declare -g TESTS_SKIPPED=0

# Test runner functions
function run_test_suite() {
    local suite_name="$1"
    local test_dir="$2"
    
    print_header "Running $suite_name Tests"
    
    if [[ ! -d "$test_dir" ]]; then
        print_warning "Test directory $test_dir not found, skipping"
        return 0
    fi
    
    for test_file in "$test_dir"/*.sh; do
        if [[ -f "$test_file" ]]; then
            run_single_test "$test_file"
        fi
    done
}

function run_single_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .sh)"
    
    print_info "Running test: $test_name"
    
    if timeout 300 bash "$test_file"; then
        print_success "✅ $test_name PASSED"
        ((TESTS_PASSED++))
    else
        print_error "❌ $test_name FAILED"
        ((TESTS_FAILED++))
    fi
}

function generate_test_report() {
    local total_tests=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    
    print_header "Test Results Summary"
    print_info "Total Tests: $total_tests"
    print_success "Passed: $TESTS_PASSED"
    print_error "Failed: $TESTS_FAILED"
    print_warning "Skipped: $TESTS_SKIPPED"
    
    # Generate JSON report
    cat > "$TEST_RESULTS_FILE" <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "total_tests": $total_tests,
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "skipped": $TESTS_SKIPPED,
    "success_rate": $(awk "BEGIN {printf \"%.2f\", ($TESTS_PASSED/$total_tests)*100}")
}
EOF
    
    print_info "Test report saved to: $TEST_RESULTS_FILE"
}

# Main execution
function main() {
    print_header "TSYS FetchApply Test Suite"
    
    # Parse command line arguments
    local test_type="${1:-all}"
    
    case "$test_type" in
        "unit")
            run_test_suite "Unit" "$(dirname "$0")/unit"
            ;;
        "integration")
            run_test_suite "Integration" "$(dirname "$0")/integration"
            ;;
        "security")
            run_test_suite "Security" "$(dirname "$0")/security"
            ;;
        "validation")
            run_test_suite "Validation" "$(dirname "$0")/validation"
            ;;
        "all")
            run_test_suite "Unit" "$(dirname "$0")/unit"
            run_test_suite "Integration" "$(dirname "$0")/integration"
            run_test_suite "Security" "$(dirname "$0")/security"
            run_test_suite "Validation" "$(dirname "$0")/validation"
            ;;
        *)
            print_error "Usage: $0 [unit|integration|security|validation|all]"
            exit 1
            ;;
    esac
    
    generate_test_report
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi