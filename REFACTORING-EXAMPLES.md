# Code Refactoring Examples

This document provides specific examples of how to apply the code review findings to improve performance, security, and reliability.

## Package Installation Optimization

### Before (Current - Multiple Commands)
```bash
# Line 27 in SetupNewSystem.sh
apt-get -y install git sudo dmidecode curl

# Lines 117-183 (later in script)
DEBIAN_FRONTEND="noninteractive" apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
  virt-what \
  auditd \
  aide \
  # ... many more packages
```

### After (Optimized - Single Command)
```bash
function install_all_packages() {
    print_info "Installing all required packages..."
    
    # All packages in logical groups for better readability
    local packages=(
        # Core system tools
        git sudo dmidecode curl wget net-tools htop
        
        # Security and auditing
        auditd aide fail2ban lynis rkhunter
        
        # Monitoring and SNMP
        snmpd snmp-mibs-downloader libsnmp-dev
        
        # Virtualization detection
        virt-what
        
        # System utilities
        rsyslog logrotate ntp ntpdate
        cockpit cockpit-ws cockpit-system
        
        # Development and debugging
        build-essential dkms
        
        # Network services
        openssh-server ufw
    )
    
    # Single package installation command with retry logic
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if DEBIAN_FRONTEND="noninteractive" apt-get -qq --yes -o Dpkg::Options::="--force-confold" install "${packages[@]}"; then
            print_success "All packages installed successfully"
            return 0
        else
            print_warning "Package installation attempt $attempt failed"
            if [[ $attempt -lt $max_attempts ]]; then
                print_info "Retrying in 10 seconds..."
                sleep 10
                apt-get update  # Refresh package cache before retry
            fi
            ((attempt++))
        fi
    done
    
    print_error "Package installation failed after $max_attempts attempts"
    return 1
}
```

## Safe Download Implementation

### Before (Current - Unsafe Downloads)
```bash
# Lines 61-63 in SetupNewSystem.sh
curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/ZSH/tsys-zshrc >/etc/zshrc
curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/SMTP/aliases >/etc/aliases
curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/Syslog/rsyslog.conf >/etc/rsyslog.conf
```

### After (Safe Downloads with Error Handling)
```bash
function download_system_configs() {
    print_info "Downloading system configuration files..."
    
    # Source the safe download framework
    source "$PROJECT_ROOT/Framework-Includes/SafeDownload.sh"
    
    # Define configuration downloads with checksums (optional)
    declare -A config_downloads=(
        ["${DL_ROOT}/ProjectCode/ConfigFiles/ZSH/tsys-zshrc"]="/etc/zshrc"
        ["${DL_ROOT}/ProjectCode/ConfigFiles/SMTP/aliases"]="/etc/aliases"
        ["${DL_ROOT}/ProjectCode/ConfigFiles/Syslog/rsyslog.conf"]="/etc/rsyslog.conf"
        ["${DL_ROOT}/ProjectCode/ConfigFiles/SSH/Configs/tsys-sshd-config"]="/etc/ssh/sshd_config.tsys"
    )
    
    # Validate all URLs are accessible before starting
    local urls=()
    for url in "${!config_downloads[@]}"; do
        urls+=("$url")
    done
    
    if ! validate_required_urls "${urls[@]}"; then
        print_error "Some configuration URLs are not accessible"
        return 1
    fi
    
    # Perform batch download with backup
    local failed_downloads=0
    for url in "${!config_downloads[@]}"; do
        local dest="${config_downloads[$url]}"
        if ! safe_config_download "$url" "$dest"; then
            ((failed_downloads++))
        fi
    done
    
    if [[ $failed_downloads -eq 0 ]]; then
        print_success "All configuration files downloaded successfully"
        return 0
    else
        print_error "$failed_downloads configuration downloads failed"
        return 1
    fi
}
```

## Variable Quoting Fixes

### Before (Unsafe Variable Usage)
```bash
# Line 244 in SetupNewSystem.sh
chsh -s $(which zsh) root

# Multiple instances throughout codebase
if [ -f $CONFIG_FILE ]; then
    cp $CONFIG_FILE $BACKUP_DIR
fi
```

### After (Proper Variable Quoting)
```bash
# Safe variable usage with proper quoting
chsh -s "$(which zsh)" root

# Consistent quoting pattern
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$BACKUP_DIR/"
fi

# Function parameter handling
function configure_service() {
    local service_name="$1"
    local config_file="$2"
    
    if [[ -z "$service_name" || -z "$config_file" ]]; then
        print_error "configure_service: service name and config file required"
        return 1
    fi
    
    print_info "Configuring service: $service_name"
    # Safe operations with quoted variables
}
```

## Service Management with Error Handling

### Before (Basic Service Operations)
```bash
# Current pattern in various modules
systemctl restart snmpd
systemctl enable snmpd
```

### After (Robust Service Management)
```bash
function safe_service_restart() {
    local service="$1"
    local config_test_cmd="${2:-}"
    
    if [[ -z "$service" ]]; then
        print_error "safe_service_restart: service name required"
        return 1
    fi
    
    print_info "Managing service: $service"
    
    # Test configuration if test command provided
    if [[ -n "$config_test_cmd" ]]; then
        print_info "Testing $service configuration..."
        if ! eval "$config_test_cmd"; then
            print_error "$service configuration test failed"
            return 1
        fi
        print_success "$service configuration test passed"
    fi
    
    # Check if service exists
    if ! systemctl list-unit-files "$service.service" >/dev/null 2>&1; then
        print_error "Service $service does not exist"
        return 1
    fi
    
    # Stop service if running
    if systemctl is-active "$service" >/dev/null 2>&1; then
        print_info "Stopping $service..."
        if ! systemctl stop "$service"; then
            print_error "Failed to stop $service"
            return 1
        fi
    fi
    
    # Start and enable service
    print_info "Starting and enabling $service..."
    if systemctl start "$service" && systemctl enable "$service"; then
        print_success "$service started and enabled successfully"
        
        # Verify service is running
        sleep 2
        if systemctl is-active "$service" >/dev/null 2>&1; then
            print_success "$service is running properly"
            return 0
        else
            print_error "$service failed to start properly"
            return 1
        fi
    else
        print_error "Failed to start or enable $service"
        return 1
    fi
}

# Usage examples
safe_service_restart "sshd" "sshd -t"
safe_service_restart "snmpd"
safe_service_restart "rsyslog"
```

## Batch Configuration Deployment

### Before (Individual File Operations)
```bash
# Lines 66-77 in secharden-scap-stig.sh
curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/ModProbe/usb_storage.conf > /etc/modprobe.d/usb_storage.conf 
curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/ModProbe/dccp.conf > /etc/modprobe.d/dccp.conf
curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/ModProbe/rds.conf > /etc/modprobe.d/rds.conf
# ... 12 more individual downloads
```

### After (Batch Operations with Error Handling)
```bash
function deploy_modprobe_configs() {
    print_info "Deploying modprobe security configurations..."
    
    source "$PROJECT_ROOT/Framework-Includes/SafeDownload.sh"
    
    local modprobe_configs=(
        "usb_storage" "dccp" "rds" "sctp" "tipc"
        "cramfs" "freevxfs" "hfs" "hfsplus"
        "jffs2" "squashfs" "udf"
    )
    
    # Create download map
    declare -A config_downloads=()
    for config in "${modprobe_configs[@]}"; do
        local url="${DL_ROOT}/ProjectCode/ConfigFiles/ModProbe/${config}.conf"
        local dest="/etc/modprobe.d/${config}.conf"
        config_downloads["$url"]="$dest"
    done
    
    # Validate URLs first
    local urls=()
    for url in "${!config_downloads[@]}"; do
        urls+=("$url")
    done
    
    if ! validate_required_urls "${urls[@]}"; then
        print_error "Some modprobe configuration URLs are not accessible"
        return 1
    fi
    
    # Perform batch download
    if batch_download config_downloads; then
        print_success "All modprobe configurations deployed"
        
        # Update initramfs to apply changes
        if update-initramfs -u; then
            print_success "Initramfs updated with new module configurations"
        else
            print_warning "Failed to update initramfs - reboot may be required"
        fi
        
        return 0
    else
        print_error "Failed to deploy some modprobe configurations"
        return 1
    fi
}
```

## Input Validation and Error Handling

### Before (Minimal Validation)
```bash
# pi-detect.sh current implementation
function pi-detect() {
  print_info Now running "$FUNCNAME"....
  if [ -f /sys/firmware/devicetree/base/model ] ; then
    export IS_RASPI="1"
  fi
}
```

### After (Comprehensive Validation)
```bash
function pi-detect() {
    print_info "Now running $FUNCNAME..."
    
    # Initialize variables with default values
    export IS_RASPI="0"
    export PI_MODEL=""
    export PI_REVISION=""
    
    # Check for Raspberry Pi detection file
    local device_tree_model="/sys/firmware/devicetree/base/model"
    local cpuinfo_file="/proc/cpuinfo"
    
    if [[ -f "$device_tree_model" ]]; then
        # Try device tree method first (most reliable)
        local model_info
        model_info=$(tr -d '\0' < "$device_tree_model" 2>/dev/null)
        
        if [[ "$model_info" =~ [Rr]aspberry.*[Pp]i ]]; then
            export IS_RASPI="1"
            export PI_MODEL="$model_info"
            print_success "Raspberry Pi detected via device tree: $PI_MODEL"
        fi
    elif [[ -f "$cpuinfo_file" ]]; then
        # Fallback to cpuinfo method
        if grep -qi "raspberry" "$cpuinfo_file"; then
            export IS_RASPI="1"
            PI_MODEL=$(grep "^Model" "$cpuinfo_file" | cut -d: -f2 | sed 's/^[[:space:]]*//' 2>/dev/null || echo "Unknown Pi Model")
            PI_REVISION=$(grep "^Revision" "$cpuinfo_file" | cut -d: -f2 | sed 's/^[[:space:]]*//' 2>/dev/null || echo "Unknown")
            export PI_MODEL
            export PI_REVISION
            print_success "Raspberry Pi detected via cpuinfo: $PI_MODEL (Rev: $PI_REVISION)"
        fi
    fi
    
    if [[ "$IS_RASPI" == "1" ]]; then
        print_info "Raspberry Pi specific optimizations will be applied"
    else
        print_info "Standard x86/x64 system detected"
    fi
    
    return 0
}
```

## Function Framework Integration

### Before (Inconsistent Framework Usage)
```bash
# Mixed patterns throughout codebase
function some_function() {
  echo "Doing something..."
  command_that_might_fail
  echo "Done"
}
```

### After (Standardized Framework Integration)
```bash
function some_function() {
    print_info "Now running $FUNCNAME..."
    
    # Local variables
    local config_file="/etc/example.conf"
    local backup_dir="/root/backup"
    local failed=0
    
    # Validate prerequisites
    if [[ ! -d "$backup_dir" ]]; then
        if ! mkdir -p "$backup_dir"; then
            print_error "Failed to create backup directory: $backup_dir"
            return 1
        fi
    fi
    
    # Backup existing configuration
    if [[ -f "$config_file" ]]; then
        if cp "$config_file" "$backup_dir/$(basename "$config_file").bak.$(date +%Y%m%d-%H%M%S)"; then
            print_info "Backed up existing configuration"
        else
            print_error "Failed to backup existing configuration"
            return 1
        fi
    fi
    
    # Perform main operation with error handling
    if command_that_might_fail; then
        print_success "Operation completed successfully"
    else
        print_error "Operation failed"
        return 1
    fi
    
    print_success "Completed $FUNCNAME"
    return 0
}
```

## Performance Monitoring Integration

### Enhanced Deployment with Metrics
```bash
function deploy_with_metrics() {
    local start_time end_time duration
    local operation_name="$1"
    shift
    local operation_function="$1"
    shift
    
    print_info "Starting $operation_name..."
    start_time=$(date +%s)
    
    # Execute the operation
    if "$operation_function" "$@"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        print_success "$operation_name completed in ${duration}s"
        
        # Log performance metrics
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $operation_name: ${duration}s" >> /var/log/fetchapply-performance.log
        
        # Alert if operation took too long
        case "$operation_name" in
            "Package Installation")
                if [[ $duration -gt 300 ]]; then
                    print_warning "Package installation took longer than expected (${duration}s > 300s)"
                fi
                ;;
            "Configuration Download")
                if [[ $duration -gt 120 ]]; then
                    print_warning "Configuration download took longer than expected (${duration}s > 120s)"
                fi
                ;;
        esac
        
        return 0
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        print_error "$operation_name failed after ${duration}s"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $operation_name: FAILED after ${duration}s" >> /var/log/fetchapply-performance.log
        
        return 1
    fi
}

# Usage example
deploy_with_metrics "Package Installation" install_all_packages
deploy_with_metrics "Configuration Download" download_system_configs
deploy_with_metrics "SSH Hardening" configure_ssh_hardening
```

## Testing Integration

### Comprehensive Validation Function
```bash
function validate_deployment() {
    print_header "Deployment Validation"
    
    local validation_failures=0
    
    # Test package installation
    local required_packages=("git" "curl" "wget" "snmpd" "auditd" "fail2ban")
    for package in "${required_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            print_success "Package installed: $package"
        else
            print_error "Package missing: $package"
            ((validation_failures++))
        fi
    done
    
    # Test service status
    local required_services=("sshd" "snmpd" "auditd" "rsyslog")
    for service in "${required_services[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            print_success "Service running: $service"
        else
            print_error "Service not running: $service"
            ((validation_failures++))
        fi
    done
    
    # Test configuration files
    local required_configs=("/etc/ssh/sshd_config" "/etc/snmp/snmpd.conf" "/etc/rsyslog.conf")
    for config in "${required_configs[@]}"; do
        if [[ -f "$config" && -s "$config" ]]; then
            print_success "Configuration exists: $(basename "$config")"
        else
            print_error "Configuration missing or empty: $(basename "$config")"
            ((validation_failures++))
        fi
    done
    
    # Run security tests
    if command -v lynis >/dev/null 2>&1; then
        print_info "Running basic security audit..."
        if lynis audit system --quick --quiet; then
            print_success "Security audit completed"
        else
            print_warning "Security audit found issues"
        fi
    fi
    
    # Summary
    if [[ $validation_failures -eq 0 ]]; then
        print_success "All deployment validation checks passed"
        return 0
    else
        print_error "$validation_failures deployment validation checks failed"
        return 1
    fi
}
```

These refactoring examples demonstrate how to apply the code review findings to create more robust, performant, and maintainable infrastructure provisioning scripts.