#!/bin/bash

# HTTPS Enforcement Security Test
# Validates that all scripts use HTTPS instead of HTTP

set -euo pipefail

PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."

function test_no_http_urls() {
    echo "🔍 Checking for HTTP URLs in scripts..."
    
    local http_violations=0
    local script_dirs=("ProjectCode" "Framework-Includes" "Project-Includes")
    
    for dir in "${script_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            # Find HTTP URLs in shell scripts (excluding comments)
            while IFS= read -r -d '' file; do
                if grep -n "http://" "$file" | grep -v "^[[:space:]]*#" | grep -v "schema.org" | grep -v "xmlns"; then
                    echo "❌ HTTP URL found in: $file"
                    ((http_violations++))
                fi
            done < <(find "$PROJECT_ROOT/$dir" -name "*.sh" -type f -print0)
        fi
    done
    
    if [[ $http_violations -eq 0 ]]; then
        echo "✅ No HTTP URLs found in active scripts"
        return 0
    else
        echo "❌ Found $http_violations HTTP URL violations"
        return 1
    fi
}

function test_https_urls_valid() {
    echo "🔍 Validating HTTPS URLs are accessible..."
    
    local script_dirs=("ProjectCode" "Framework-Includes" "Project-Includes")
    local https_failures=0
    
    # Extract HTTPS URLs from scripts
    for dir in "${script_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            while IFS= read -r -d '' file; do
                # Extract HTTPS URLs from non-comment lines
                grep -o "https://[^[:space:]\"']*" "$file" | grep -v "schema.org" | while read -r url; do
                    # Test connectivity with timeout
                    if timeout 30 curl -s --head --fail "$url" >/dev/null 2>&1; then
                        echo "✅ HTTPS URL accessible: $url"
                    else
                        echo "❌ HTTPS URL not accessible: $url"
                        ((https_failures++))
                    fi
                done
            done < <(find "$PROJECT_ROOT/$dir" -name "*.sh" -type f -print0)
        fi
    done
    
    return $https_failures
}

function test_ssl_certificate_validation() {
    echo "🔍 Testing SSL certificate validation..."
    
    local test_urls=(
        "https://archive.ubuntu.com"
        "https://linux.dell.com"
        "https://download.proxmox.com"
    )
    
    local ssl_failures=0
    
    for url in "${test_urls[@]}"; do
        # Test with strict SSL verification
        if curl -s --fail --ssl-reqd --cert-status "$url" >/dev/null 2>&1; then
            echo "✅ SSL certificate valid: $url"
        else
            echo "❌ SSL certificate validation failed: $url"
            ((ssl_failures++))
        fi
    done
    
    return $ssl_failures
}

function test_deployment_security() {
    echo "🔍 Testing deployment method security..."
    
    local readme_file="$PROJECT_ROOT/README.md"
    
    if [[ -f "$readme_file" ]]; then
        # Check for insecure curl | bash patterns
        if grep -q "curl.*|.*bash" "$readme_file" || grep -q "wget.*|.*bash" "$readme_file"; then
            echo "❌ Insecure deployment method found in README.md"
            return 1
        else
            echo "✅ Secure deployment method in README.md"
        fi
        
        # Check for git clone method
        if grep -q "git clone" "$readme_file"; then
            echo "✅ Git clone deployment method found"
            return 0
        else
            echo "⚠️  No git clone method found in README.md"
            return 1
        fi
    else
        echo "❌ README.md not found"
        return 1
    fi
}

# Main test execution
function main() {
    echo "🔒 Running HTTPS Enforcement Security Tests"
    echo "=========================================="
    
    local total_failures=0
    
    # Run all security tests
    test_no_http_urls || ((total_failures++))
    test_https_urls_valid || ((total_failures++))
    test_ssl_certificate_validation || ((total_failures++))
    test_deployment_security || ((total_failures++))
    
    echo "=========================================="
    
    if [[ $total_failures -eq 0 ]]; then
        echo "✅ All HTTPS enforcement security tests passed"
        exit 0
    else
        echo "❌ $total_failures HTTPS enforcement security tests failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi