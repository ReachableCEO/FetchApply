#!/bin/bash

# Safe Download Framework
# Provides robust download operations with error handling, retries, and validation
# Author: TSYS Development Team

set -euo pipefail

# Source framework dependencies
source "$(dirname "${BASH_SOURCE[0]}")/PrettyPrint.sh" 2>/dev/null || echo "Warning: PrettyPrint.sh not found"
source "$(dirname "${BASH_SOURCE[0]}")/Logging.sh" 2>/dev/null || echo "Warning: Logging.sh not found"

# Download configuration
declare -g DOWNLOAD_TIMEOUT=60
declare -g DOWNLOAD_CONNECT_TIMEOUT=30
declare -g DOWNLOAD_MAX_ATTEMPTS=3
declare -g DOWNLOAD_RETRY_DELAY=5

# Safe download with retry logic and error handling
function safe_download() {
    local url="$1"
    local dest="$2"
    local expected_checksum="${3:-}"
    local max_attempts="${4:-$DOWNLOAD_MAX_ATTEMPTS}"
    
    local attempt=1
    local temp_file="${dest}.tmp.$$"
    
    # Validate inputs
    if [[ -z "$url" || -z "$dest" ]]; then
        print_error "safe_download: URL and destination are required"
        return 1
    fi
    
    # Create destination directory if needed
    local dest_dir
    dest_dir="$(dirname "$dest")"
    if [[ ! -d "$dest_dir" ]]; then
        if ! mkdir -p "$dest_dir"; then
            print_error "Failed to create directory: $dest_dir"
            return 1
        fi
    fi
    
    print_info "Downloading: $(basename "$dest") from $url"
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl --silent --show-error --fail \
                --connect-timeout "$DOWNLOAD_CONNECT_TIMEOUT" \
                --max-time "$DOWNLOAD_TIMEOUT" \
                --location \
                --user-agent "TSYS-FetchApply/1.0" \
                "$url" > "$temp_file"; then
            
            # Verify checksum if provided
            if [[ -n "$expected_checksum" ]]; then
                if verify_checksum "$temp_file" "$expected_checksum"; then
                    mv "$temp_file" "$dest"
                    print_success "Downloaded and verified: $(basename "$dest")"
                    return 0
                else
                    print_error "Checksum verification failed for: $(basename "$dest")"
                    rm -f "$temp_file"
                    return 1
                fi
            else
                mv "$temp_file" "$dest"
                print_success "Downloaded: $(basename "$dest")"
                return 0
            fi
        else
            print_warning "Download attempt $attempt failed: $(basename "$dest")"
            rm -f "$temp_file"
            
            if [[ $attempt -lt $max_attempts ]]; then
                print_info "Retrying in ${DOWNLOAD_RETRY_DELAY}s..."
                sleep "$DOWNLOAD_RETRY_DELAY"
            fi
            
            ((attempt++))
        fi
    done
    
    print_error "Failed to download after $max_attempts attempts: $(basename "$dest")"
    return 1
}

# Verify file checksum
function verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found for checksum verification: $file"
        return 1
    fi
    
    local actual_checksum
    actual_checksum=$(sha256sum "$file" | cut -d' ' -f1)
    
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        print_success "Checksum verified: $(basename "$file")"
        return 0
    else
        print_error "Checksum mismatch for $(basename "$file")"
        print_error "Expected: $expected_checksum"
        print_error "Actual:   $actual_checksum"
        return 1
    fi
}

# Batch download multiple files
function batch_download() {
    local -n download_map=$1
    local failed_downloads=0
    
    print_info "Starting batch download of ${#download_map[@]} files..."
    
    for url in "${!download_map[@]}"; do
        local dest="${download_map[$url]}"
        if ! safe_download "$url" "$dest"; then
            ((failed_downloads++))
        fi
    done
    
    if [[ $failed_downloads -eq 0 ]]; then
        print_success "All batch downloads completed successfully"
        return 0
    else
        print_error "$failed_downloads batch downloads failed"
        return 1
    fi
}

# Download with progress indication for large files
function safe_download_with_progress() {
    local url="$1"
    local dest="$2"
    local expected_checksum="${3:-}"
    
    print_info "Downloading with progress: $(basename "$dest")"
    
    if curl --progress-bar --show-error --fail \
            --connect-timeout "$DOWNLOAD_CONNECT_TIMEOUT" \
            --max-time "$DOWNLOAD_TIMEOUT" \
            --location \
            --user-agent "TSYS-FetchApply/1.0" \
            "$url" -o "$dest"; then
        
        # Verify checksum if provided
        if [[ -n "$expected_checksum" ]]; then
            if verify_checksum "$dest" "$expected_checksum"; then
                print_success "Downloaded and verified: $(basename "$dest")"
                return 0
            else
                rm -f "$dest"
                return 1
            fi
        else
            print_success "Downloaded: $(basename "$dest")"
            return 0
        fi
    else
        print_error "Failed to download: $(basename "$dest")"
        rm -f "$dest"
        return 1
    fi
}

# Check if URL is accessible
function check_url_accessibility() {
    local url="$1"
    
    if curl --silent --head --fail \
            --connect-timeout "$DOWNLOAD_CONNECT_TIMEOUT" \
            --max-time 10 \
            "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Validate all required URLs before starting deployment
function validate_required_urls() {
    local -a urls=("$@")
    local failed_urls=0
    
    print_info "Validating accessibility of ${#urls[@]} URLs..."
    
    for url in "${urls[@]}"; do
        if check_url_accessibility "$url"; then
            print_success "✓ $url"
        else
            print_error "✗ $url"
            ((failed_urls++))
        fi
    done
    
    if [[ $failed_urls -eq 0 ]]; then
        print_success "All URLs are accessible"
        return 0
    else
        print_error "$failed_urls URLs are not accessible"
        return 1
    fi
}

# Download configuration files with backup
function safe_config_download() {
    local url="$1"
    local dest="$2"
    local backup_suffix="${3:-.bak.$(date +%Y%m%d-%H%M%S)}"
    
    # Backup existing file if it exists
    if [[ -f "$dest" ]]; then
        local backup_file="${dest}${backup_suffix}"
        if cp "$dest" "$backup_file"; then
            print_info "Backed up existing config: $backup_file"
        else
            print_error "Failed to backup existing config: $dest"
            return 1
        fi
    fi
    
    # Download new configuration
    if safe_download "$url" "$dest"; then
        print_success "Configuration updated: $(basename "$dest")"
        return 0
    else
        # Restore backup if download failed and backup exists
        local backup_file="${dest}${backup_suffix}"
        if [[ -f "$backup_file" ]]; then
            if mv "$backup_file" "$dest"; then
                print_warning "Restored backup after failed download: $(basename "$dest")"
            else
                print_error "Failed to restore backup: $(basename "$dest")"
            fi
        fi
        return 1
    fi
}

# Test network connectivity to common endpoints
function test_network_connectivity() {
    local test_urls=(
        "https://archive.ubuntu.com"
        "https://github.com"
        "https://curl.haxx.se"
    )
    
    print_info "Testing network connectivity..."
    
    for url in "${test_urls[@]}"; do
        if check_url_accessibility "$url"; then
            print_success "Network connectivity confirmed: $url"
            return 0
        fi
    done
    
    print_error "No network connectivity detected"
    return 1
}

# Export functions for use in other scripts
export -f safe_download
export -f verify_checksum
export -f batch_download
export -f safe_download_with_progress
export -f check_url_accessibility
export -f validate_required_urls
export -f safe_config_download
export -f test_network_connectivity