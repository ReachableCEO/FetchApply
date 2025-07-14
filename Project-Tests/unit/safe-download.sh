#!/bin/bash

# Safe Download Framework Unit Tests
# Tests the SafeDownload.sh framework functionality

set -euo pipefail

PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."

# Source framework functions
source "$PROJECT_ROOT/Framework-Includes/SafeDownload.sh"

function test_network_connectivity() {
    echo "🔍 Testing network connectivity..."
    
    if test_network_connectivity; then
        echo "✅ Network connectivity test passed"
        return 0
    else
        echo "❌ Network connectivity test failed"
        return 1
    fi
}

function test_url_accessibility() {
    echo "🔍 Testing URL accessibility..."
    
    local test_urls=(
        "https://archive.ubuntu.com"
        "https://github.com"
    )
    
    local failed=0
    
    for url in "${test_urls[@]}"; do
        if check_url_accessibility "$url"; then
            echo "✅ URL accessible: $url"
        else
            echo "❌ URL not accessible: $url"
            ((failed++))
        fi
    done
    
    return $failed
}

function test_safe_download() {
    echo "🔍 Testing safe download functionality..."
    
    local test_url="https://raw.githubusercontent.com/torvalds/linux/master/README"
    local test_dest="/tmp/test-download-$$"
    local failed=0
    
    # Test successful download
    if safe_download "$test_url" "$test_dest"; then
        echo "✅ Safe download successful"
        
        # Verify file exists and has content
        if [[ -f "$test_dest" && -s "$test_dest" ]]; then
            echo "✅ Downloaded file exists and has content"
        else
            echo "❌ Downloaded file is missing or empty"
            ((failed++))
        fi
        
        # Cleanup
        rm -f "$test_dest"
    else
        echo "❌ Safe download failed"
        ((failed++))
    fi
    
    # Test download with invalid URL
    if safe_download "https://invalid.example.com/nonexistent" "/tmp/test-invalid-$$" 2>/dev/null; then
        echo "❌ Invalid URL download should have failed"
        ((failed++))
    else
        echo "✅ Invalid URL download failed as expected"
    fi
    
    return $failed
}

function test_checksum_verification() {
    echo "🔍 Testing checksum verification..."
    
    local test_file="/tmp/test-checksum-$$"
    local test_content="Hello, World!"
    local expected_checksum="dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f"
    local failed=0
    
    # Create test file with known content
    echo -n "$test_content" > "$test_file"
    
    # Test correct checksum
    if verify_checksum "$test_file" "$expected_checksum"; then
        echo "✅ Correct checksum verification passed"
    else
        echo "❌ Correct checksum verification failed"
        ((failed++))
    fi
    
    # Test incorrect checksum
    if verify_checksum "$test_file" "invalid_checksum" 2>/dev/null; then
        echo "❌ Incorrect checksum should have failed"
        ((failed++))
    else
        echo "✅ Incorrect checksum verification failed as expected"
    fi
    
    # Test missing file
    if verify_checksum "/tmp/nonexistent-file-$$" "$expected_checksum" 2>/dev/null; then
        echo "❌ Missing file checksum should have failed"
        ((failed++))
    else
        echo "✅ Missing file checksum verification failed as expected"
    fi
    
    # Cleanup
    rm -f "$test_file"
    
    return $failed
}

function test_batch_download() {
    echo "🔍 Testing batch download functionality..."
    
    # Create test download map
    declare -A test_downloads=(
        ["https://raw.githubusercontent.com/torvalds/linux/master/README"]="/tmp/batch-test-1-$$"
        ["https://raw.githubusercontent.com/torvalds/linux/master/COPYING"]="/tmp/batch-test-2-$$"
    )
    
    local failed=0
    
    # Test batch download
    if batch_download test_downloads; then
        echo "✅ Batch download successful"
        
        # Verify all files were downloaded
        for file in "${test_downloads[@]}"; do
            if [[ -f "$file" && -s "$file" ]]; then
                echo "✅ Batch file downloaded: $(basename "$file")"
            else
                echo "❌ Batch file missing: $(basename "$file")"
                ((failed++))
            fi
        done
        
        # Cleanup
        for file in "${test_downloads[@]}"; do
            rm -f "$file"
        done
    else
        echo "❌ Batch download failed"
        ((failed++))
    fi
    
    return $failed
}

function test_config_backup_and_restore() {
    echo "🔍 Testing config backup and restore..."
    
    local test_config="/tmp/test-config-$$"
    local original_content="Original configuration"
    local failed=0
    
    # Create original config file
    echo "$original_content" > "$test_config"
    
    # Test safe config download (this will fail with invalid URL, triggering restore)
    if safe_config_download "https://invalid.example.com/config" "$test_config" ".test-backup" 2>/dev/null; then
        echo "❌ Invalid config download should have failed"
        ((failed++))
    else
        echo "✅ Invalid config download failed as expected"
        
        # Verify original file was restored
        if [[ -f "$test_config" ]] && grep -q "$original_content" "$test_config"; then
            echo "✅ Original config was restored after failed download"
        else
            echo "❌ Original config was not restored properly"
            ((failed++))
        fi
    fi
    
    # Cleanup
    rm -f "$test_config" "$test_config.test-backup"
    
    return $failed
}

function test_download_error_handling() {
    echo "🔍 Testing download error handling..."
    
    local failed=0
    
    # Test download with missing parameters
    if safe_download "" "/tmp/test" 2>/dev/null; then
        echo "❌ Download with empty URL should have failed"
        ((failed++))
    else
        echo "✅ Download with empty URL failed as expected"
    fi
    
    if safe_download "https://example.com" "" 2>/dev/null; then
        echo "❌ Download with empty destination should have failed"
        ((failed++))
    else
        echo "✅ Download with empty destination failed as expected"
    fi
    
    # Test download to read-only location (should fail)
    if safe_download "https://github.com" "/test-readonly-$$" 2>/dev/null; then
        echo "❌ Download to read-only location should have failed"
        ((failed++))
    else
        echo "✅ Download to read-only location failed as expected"
    fi
    
    return $failed
}

function test_download_performance() {
    echo "🔍 Testing download performance..."
    
    local test_url="https://raw.githubusercontent.com/torvalds/linux/master/README"
    local test_dest="/tmp/perf-test-$$"
    local start_time end_time duration
    
    start_time=$(date +%s)
    
    if safe_download "$test_url" "$test_dest"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        echo "✅ Download completed in ${duration}s"
        
        if [[ $duration -gt 30 ]]; then
            echo "⚠️  Download took longer than expected (>30s)"
        else
            echo "✅ Download performance acceptable"
        fi
        
        # Cleanup
        rm -f "$test_dest"
        return 0
    else
        echo "❌ Performance test download failed"
        return 1
    fi
}

# Main test execution
function main() {
    echo "🧪 Running Safe Download Framework Unit Tests"
    echo "==========================================="
    
    local total_failures=0
    
    # Run all tests
    test_network_connectivity || ((total_failures++))
    test_url_accessibility || ((total_failures++))
    test_safe_download || ((total_failures++))
    test_checksum_verification || ((total_failures++))
    test_batch_download || ((total_failures++))
    test_config_backup_and_restore || ((total_failures++))
    test_download_error_handling || ((total_failures++))
    test_download_performance || ((total_failures++))
    
    echo "==========================================="
    
    if [[ $total_failures -eq 0 ]]; then
        echo "✅ All safe download framework tests passed"
        exit 0
    else
        echo "❌ $total_failures safe download framework tests failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi