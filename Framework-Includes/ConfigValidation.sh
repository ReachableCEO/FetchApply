#!/bin/bash

# Configuration Validation Framework
# Pre-flight checks for system compatibility and requirements

set -euo pipefail

# Source framework dependencies
source "$(dirname "${BASH_SOURCE[0]}")/PrettyPrint.sh" 2>/dev/null || echo "Warning: PrettyPrint.sh not found"
source "$(dirname "${BASH_SOURCE[0]}")/Logging.sh" 2>/dev/null || echo "Warning: Logging.sh not found"

# Configuration validation settings
declare -g VALIDATION_FAILED=0
declare -g VALIDATION_WARNINGS=0

# System requirements
declare -g MIN_RAM_GB=2
declare -g MIN_DISK_GB=10
declare -g REQUIRED_COMMANDS=("curl" "wget" "git" "systemctl" "apt-get" "dmidecode")

# Network endpoints to validate
declare -g REQUIRED_ENDPOINTS=(
    "https://archive.ubuntu.com"
    "https://linux.dell.com"
    "https://download.proxmox.com"
    "https://github.com"
)

# Validation functions
function validate_system_requirements() {
    print_info "Validating system requirements..."
    
    # Check RAM
    local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    if [[ $total_mem_gb -ge $MIN_RAM_GB ]]; then
        print_success "RAM requirement met: ${total_mem_gb}GB >= ${MIN_RAM_GB}GB"
    else
        print_error "RAM requirement not met: ${total_mem_gb}GB < ${MIN_RAM_GB}GB"
        ((VALIDATION_FAILED++))
    fi
    
    # Check disk space
    local available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    
    if [[ $available_gb -ge $MIN_DISK_GB ]]; then
        print_success "Disk space requirement met: ${available_gb}GB >= ${MIN_DISK_GB}GB"
    else
        print_error "Disk space requirement not met: ${available_gb}GB < ${MIN_DISK_GB}GB"
        ((VALIDATION_FAILED++))
    fi
}

function validate_required_commands() {
    print_info "Validating required commands..."
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_success "Required command available: $cmd"
        else
            print_error "Required command missing: $cmd"
            ((VALIDATION_FAILED++))
        fi
    done
}

function validate_os_compatibility() {
    print_info "Validating OS compatibility..."
    
    if [[ -f /etc/os-release ]]; then
        local os_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        local os_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        
        case "$os_id" in
            ubuntu)
                if [[ "${os_version%%.*}" -ge 18 ]]; then
                    print_success "OS compatibility: Ubuntu $os_version (fully supported)"
                else
                    print_warning "OS compatibility: Ubuntu $os_version (may have issues)"
                    ((VALIDATION_WARNINGS++))
                fi
                ;;
            debian)
                if [[ "${os_version%%.*}" -ge 10 ]]; then
                    print_success "OS compatibility: Debian $os_version (fully supported)"
                else
                    print_warning "OS compatibility: Debian $os_version (may have issues)"
                    ((VALIDATION_WARNINGS++))
                fi
                ;;
            *)
                print_warning "OS compatibility: $os_id $os_version (not tested, may work)"
                ((VALIDATION_WARNINGS++))
                ;;
        esac
    else
        print_error "Cannot determine OS version"
        ((VALIDATION_FAILED++))
    fi
}

function validate_network_connectivity() {
    print_info "Validating network connectivity..."
    
    for endpoint in "${REQUIRED_ENDPOINTS[@]}"; do
        if curl -s --connect-timeout 10 --max-time 30 --head "$endpoint" >/dev/null 2>&1; then
            print_success "Network connectivity: $endpoint"
        else
            print_error "Network connectivity failed: $endpoint"
            ((VALIDATION_FAILED++))
        fi
    done
}

function validate_permissions() {
    print_info "Validating system permissions..."
    
    local required_dirs=("/etc" "/usr/local/bin" "/var/log")
    
    for dir in "${required_dirs[@]}"; do
        if [[ -w "$dir" ]]; then
            print_success "Write permission: $dir"
        else
            print_error "Write permission denied: $dir (run with sudo)"
            ((VALIDATION_FAILED++))
        fi
    done
}

function validate_conflicting_software() {
    print_info "Checking for conflicting software..."
    
    # Check for conflicting SSH configurations
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
            print_warning "SSH password authentication is enabled (will be disabled)"
            ((VALIDATION_WARNINGS++))
        fi
    fi
    
    # Check for conflicting firewall rules
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            print_warning "UFW firewall is active (may conflict with iptables rules)"
            ((VALIDATION_WARNINGS++))
        fi
    fi
    
    # Check for conflicting SNMP configurations
    if systemctl is-active snmpd >/dev/null 2>&1; then
        print_warning "SNMP service is already running (will be reconfigured)"
        ((VALIDATION_WARNINGS++))
    fi
}

function validate_hardware_compatibility() {
    print_info "Validating hardware compatibility..."
    
    # Check if this is a Dell server
    if [[ "$IS_PHYSICAL_HOST" -gt 0 ]]; then
        print_info "Dell physical server detected - OMSA will be installed"
    else
        print_info "Virtual machine detected - hardware-specific tools will be skipped"
    fi
    
    # Check for virtualization
    if grep -q "hypervisor" /proc/cpuinfo; then
        print_info "Virtualization detected - optimizations will be applied"
    fi
}

function validate_existing_users() {
    print_info "Validating user configuration..."
    
    # Check for existing users
    if [[ "$LOCALUSER_CHECK" -gt 0 ]]; then
        print_info "User 'localuser' already exists"
    else
        print_info "User 'localuser' will be created"
    fi
    
    if [[ "$SUBODEV_CHECK" -gt 0 ]]; then
        print_info "User 'subodev' already exists"
    else
        print_info "User 'subodev' will be created"
    fi
}

function validate_security_requirements() {
    print_info "Validating security requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_success "Running with root privileges"
    else
        print_error "Must run with root privileges (use sudo)"
        ((VALIDATION_FAILED++))
    fi
    
    # Check for existing SSH keys
    if [[ -f ~/.ssh/id_rsa ]]; then
        print_warning "SSH keys already exist - will be preserved"
        ((VALIDATION_WARNINGS++))
    fi
    
    # Check for secure boot
    if [[ -d /sys/firmware/efi/efivars ]]; then
        print_info "UEFI system detected"
        if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
            print_warning "Secure Boot is enabled - may affect kernel modules"
            ((VALIDATION_WARNINGS++))
        fi
    fi
}

# Main validation function
function run_configuration_validation() {
    print_header "Configuration Validation"
    
    # Reset counters
    VALIDATION_FAILED=0
    VALIDATION_WARNINGS=0
    
    # Run all validation checks
    validate_system_requirements
    validate_required_commands
    validate_os_compatibility
    validate_network_connectivity
    validate_permissions
    validate_conflicting_software
    validate_hardware_compatibility
    validate_existing_users
    validate_security_requirements
    
    # Summary
    print_header "Validation Summary"
    
    if [[ $VALIDATION_FAILED -eq 0 ]]; then
        print_success "All validation checks passed"
        if [[ $VALIDATION_WARNINGS -gt 0 ]]; then
            print_warning "$VALIDATION_WARNINGS warnings - deployment may continue"
        fi
        return 0
    else
        print_error "$VALIDATION_FAILED validation checks failed"
        if [[ $VALIDATION_WARNINGS -gt 0 ]]; then
            print_warning "$VALIDATION_WARNINGS additional warnings"
        fi
        print_error "Please resolve the above issues before deployment"
        return 1
    fi
}

# Export functions for use in other scripts
export -f validate_system_requirements
export -f validate_required_commands
export -f validate_os_compatibility
export -f validate_network_connectivity
export -f validate_permissions
export -f run_configuration_validation