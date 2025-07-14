#!/bin/bash

# System Requirements Validation Test
# Validates minimum system requirements before deployment

set -euo pipefail

# Test configuration
MIN_RAM_GB=2
MIN_DISK_GB=10
REQUIRED_COMMANDS=("curl" "wget" "git" "systemctl" "apt-get")

# Test functions
function test_memory_requirements() {
    local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    if [[ $total_mem_gb -ge $MIN_RAM_GB ]]; then
        echo "✅ Memory requirement met: ${total_mem_gb}GB >= ${MIN_RAM_GB}GB"
        return 0
    else
        echo "❌ Memory requirement not met: ${total_mem_gb}GB < ${MIN_RAM_GB}GB"
        return 1
    fi
}

function test_disk_space() {
    local available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    
    if [[ $available_gb -ge $MIN_DISK_GB ]]; then
        echo "✅ Disk space requirement met: ${available_gb}GB >= ${MIN_DISK_GB}GB"
        return 0
    else
        echo "❌ Disk space requirement not met: ${available_gb}GB < ${MIN_DISK_GB}GB"
        return 1
    fi
}

function test_required_commands() {
    local failed=0
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "✅ Required command available: $cmd"
        else
            echo "❌ Required command missing: $cmd"
            ((failed++))
        fi
    done
    
    return $failed
}

function test_os_compatibility() {
    if [[ -f /etc/os-release ]]; then
        local os_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        local os_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        
        case "$os_id" in
            ubuntu|debian)
                echo "✅ OS compatibility: $os_id $os_version (supported)"
                return 0
                ;;
            *)
                echo "⚠️  OS compatibility: $os_id $os_version (may work, not fully tested)"
                return 0
                ;;
        esac
    else
        echo "❌ Cannot determine OS version"
        return 1
    fi
}

function test_network_connectivity() {
    local test_urls=(
        "https://archive.ubuntu.com"
        "https://linux.dell.com"
        "https://download.proxmox.com"
        "https://github.com"
    )
    
    local failed=0
    
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 10 --max-time 30 "$url" >/dev/null 2>&1; then
            echo "✅ Network connectivity: $url"
        else
            echo "❌ Network connectivity failed: $url"
            ((failed++))
        fi
    done
    
    return $failed
}

function test_permissions() {
    local test_dirs=("/etc" "/usr/local/bin" "/var/log")
    local failed=0
    
    for dir in "${test_dirs[@]}"; do
        if [[ -w "$dir" ]]; then
            echo "✅ Write permission: $dir"
        else
            echo "❌ Write permission denied: $dir"
            ((failed++))
        fi
    done
    
    return $failed
}

# Main test execution
function main() {
    echo "🔍 Running System Requirements Validation"
    echo "========================================"
    
    local total_failures=0
    
    # Run all validation tests
    test_memory_requirements || ((total_failures++))
    test_disk_space || ((total_failures++))
    test_required_commands || ((total_failures++))
    test_os_compatibility || ((total_failures++))
    test_network_connectivity || ((total_failures++))
    test_permissions || ((total_failures++))
    
    echo "========================================"
    
    if [[ $total_failures -eq 0 ]]; then
        echo "✅ All system requirements validation tests passed"
        exit 0
    else
        echo "❌ $total_failures system requirements validation tests failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi