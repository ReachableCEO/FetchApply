#!/bin/bash

# Two-Factor Authentication Validation Test
# Validates 2FA configuration for SSH, Cockpit, and Webmin

set -euo pipefail

PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."

function test_2fa_packages() {
    echo "🔍 Testing 2FA package installation..."
    
    local packages=("libpam-google-authenticator" "qrencode")
    local failed=0
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            echo "✅ Package installed: $package"
        else
            echo "❌ Package missing: $package"
            ((failed++))
        fi
    done
    
    # Check if google-authenticator command exists
    if command -v google-authenticator >/dev/null 2>&1; then
        echo "✅ Google Authenticator command available"
    else
        echo "❌ Google Authenticator command not found"
        ((failed++))
    fi
    
    return $failed
}

function test_ssh_2fa_config() {
    echo "🔍 Testing SSH 2FA configuration..."
    
    local ssh_config="/etc/ssh/sshd_config"
    local failed=0
    
    # Check required SSH settings
    if grep -q "^ChallengeResponseAuthentication yes" "$ssh_config"; then
        echo "✅ ChallengeResponseAuthentication enabled"
    else
        echo "❌ ChallengeResponseAuthentication not enabled"
        ((failed++))
    fi
    
    if grep -q "^UsePAM yes" "$ssh_config"; then
        echo "✅ UsePAM enabled"
    else
        echo "❌ UsePAM not enabled"
        ((failed++))
    fi
    
    if grep -q "^AuthenticationMethods publickey,keyboard-interactive" "$ssh_config"; then
        echo "✅ AuthenticationMethods configured for 2FA"
    else
        echo "❌ AuthenticationMethods not configured for 2FA"
        ((failed++))
    fi
    
    return $failed
}

function test_pam_2fa_config() {
    echo "🔍 Testing PAM 2FA configuration..."
    
    local pam_sshd="/etc/pam.d/sshd"
    local failed=0
    
    # Check if PAM includes Google Authenticator
    if grep -q "pam_google_authenticator.so" "$pam_sshd"; then
        echo "✅ PAM Google Authenticator module configured"
    else
        echo "❌ PAM Google Authenticator module not configured"
        ((failed++))
    fi
    
    # Check if nullok is present (allows users without 2FA setup)
    if grep -q "pam_google_authenticator.so nullok" "$pam_sshd"; then
        echo "✅ PAM nullok option configured (allows gradual rollout)"
    else
        echo "⚠️  PAM nullok option not configured (immediate enforcement)"
    fi
    
    return $failed
}

function test_cockpit_2fa_config() {
    echo "🔍 Testing Cockpit 2FA configuration..."
    
    local cockpit_config="/etc/cockpit/cockpit.conf"
    local cockpit_pam="/etc/pam.d/cockpit"
    local failed=0
    
    # Check if Cockpit is installed
    if ! command -v cockpit-ws >/dev/null 2>&1; then
        echo "⚠️  Cockpit not installed, skipping test"
        return 0
    fi
    
    # Check Cockpit configuration
    if [[ -f "$cockpit_config" ]]; then
        echo "✅ Cockpit configuration file exists"
    else
        echo "❌ Cockpit configuration file missing"
        ((failed++))
    fi
    
    # Check Cockpit PAM configuration
    if [[ -f "$cockpit_pam" ]] && grep -q "pam_google_authenticator.so" "$cockpit_pam"; then
        echo "✅ Cockpit PAM 2FA configured"
    else
        echo "❌ Cockpit PAM 2FA not configured"
        ((failed++))
    fi
    
    return $failed
}

function test_webmin_2fa_config() {
    echo "🔍 Testing Webmin 2FA configuration..."
    
    local webmin_config="/etc/webmin/miniserv.conf"
    local failed=0
    
    # Check if Webmin is installed
    if [[ ! -f "$webmin_config" ]]; then
        echo "⚠️  Webmin not installed, skipping test"
        return 0
    fi
    
    # Check Webmin 2FA settings
    if grep -q "^twofactor_provider=totp" "$webmin_config"; then
        echo "✅ Webmin TOTP provider configured"
    else
        echo "❌ Webmin TOTP provider not configured"
        ((failed++))
    fi
    
    if grep -q "^twofactor=1" "$webmin_config"; then
        echo "✅ Webmin 2FA enabled"
    else
        echo "❌ Webmin 2FA not enabled"
        ((failed++))
    fi
    
    return $failed
}

function test_user_2fa_setup() {
    echo "🔍 Testing user 2FA setup preparation..."
    
    local users=("localuser" "root")
    local failed=0
    
    for user in "${users[@]}"; do
        if id "$user" &>/dev/null; then
            # Check if setup script exists
            if [[ -f "/tmp/setup-2fa-$user.sh" ]]; then
                echo "✅ 2FA setup script exists for user: $user"
            else
                echo "❌ 2FA setup script missing for user: $user"
                ((failed++))
            fi
            
            # Check if instructions exist
            if [[ -f "/home/$user/2fa-setup-instructions.txt" ]]; then
                echo "✅ 2FA instructions exist for user: $user"
            else
                echo "❌ 2FA instructions missing for user: $user"
                ((failed++))
            fi
        else
            echo "⚠️  User $user not found, skipping"
        fi
    done
    
    return $failed
}

function test_service_status() {
    echo "🔍 Testing service status..."
    
    local failed=0
    
    # Test SSH service
    if systemctl is-active sshd >/dev/null 2>&1; then
        echo "✅ SSH service is running"
    else
        echo "❌ SSH service is not running"
        ((failed++))
    fi
    
    # Test SSH configuration
    if sshd -t 2>/dev/null; then
        echo "✅ SSH configuration is valid"
    else
        echo "❌ SSH configuration is invalid"
        ((failed++))
    fi
    
    # Test Cockpit service if installed
    if systemctl is-enabled cockpit.socket >/dev/null 2>&1; then
        if systemctl is-active cockpit.socket >/dev/null 2>&1; then
            echo "✅ Cockpit service is running"
        else
            echo "❌ Cockpit service is not running"
            ((failed++))
        fi
    fi
    
    # Test Webmin service if installed
    if systemctl is-enabled webmin >/dev/null 2>&1; then
        if systemctl is-active webmin >/dev/null 2>&1; then
            echo "✅ Webmin service is running"
        else
            echo "❌ Webmin service is not running"
            ((failed++))
        fi
    fi
    
    return $failed
}

function test_backup_existence() {
    echo "🔍 Testing backup existence..."
    
    local backup_dir="/root/backup"
    local failed=0
    
    if [[ -d "$backup_dir" ]]; then
        # Look for recent 2FA backups
        local recent_backups=$(find "$backup_dir" -name "2fa-*" -type d -newer /etc/ssh/sshd_config 2>/dev/null | wc -l)
        
        if [[ $recent_backups -gt 0 ]]; then
            echo "✅ Recent 2FA backup found in $backup_dir"
        else
            echo "⚠️  No recent 2FA backups found"
        fi
    else
        echo "❌ Backup directory does not exist"
        ((failed++))
    fi
    
    return $failed
}

function test_2fa_enforcement() {
    echo "🔍 Testing 2FA enforcement level..."
    
    local pam_sshd="/etc/pam.d/sshd"
    
    # Check if nullok is used (allows users without 2FA)
    if grep -q "pam_google_authenticator.so nullok" "$pam_sshd"; then
        echo "⚠️  2FA enforcement: GRADUAL (nullok allows users without 2FA)"
        echo "    Users can log in without 2FA during setup phase"
    else
        echo "✅ 2FA enforcement: STRICT (all users must have 2FA)"
        echo "    All users must have 2FA configured to log in"
    fi
    
    return 0
}

# Main test execution
function main() {
    echo "🔒 Running Two-Factor Authentication Validation Tests"
    echo "=================================================="
    
    local total_failures=0
    
    # Run all 2FA validation tests
    test_2fa_packages || ((total_failures++))
    test_ssh_2fa_config || ((total_failures++))
    test_pam_2fa_config || ((total_failures++))
    test_cockpit_2fa_config || ((total_failures++))
    test_webmin_2fa_config || ((total_failures++))
    test_user_2fa_setup || ((total_failures++))
    test_service_status || ((total_failures++))
    test_backup_existence || ((total_failures++))
    test_2fa_enforcement || ((total_failures++))
    
    echo "=================================================="
    
    if [[ $total_failures -eq 0 ]]; then
        echo "✅ All 2FA validation tests passed"
        echo ""
        echo "📋 Next Steps:"
        echo "1. Run user setup scripts: /tmp/setup-2fa-*.sh"
        echo "2. Test 2FA login from another terminal"
        echo "3. Remove nullok from PAM config for strict enforcement"
        exit 0
    else
        echo "❌ $total_failures 2FA validation tests failed"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "1. Re-run secharden-2fa.sh script"
        echo "2. Check system logs: journalctl -u sshd"
        echo "3. Verify package installation"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi