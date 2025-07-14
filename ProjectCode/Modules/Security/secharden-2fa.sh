#!/bin/bash

# TSYS Security Hardening - Two-Factor Authentication
# Implements 2FA for SSH, Cockpit, and Webmin services
# Uses Google Authenticator (TOTP) for time-based tokens

set -euo pipefail

# Source framework functions
PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."
source "$PROJECT_ROOT/Framework-Includes/PrettyPrint.sh"
source "$PROJECT_ROOT/Framework-Includes/Logging.sh"
source "$PROJECT_ROOT/Framework-Includes/ErrorHandling.sh"

# 2FA Configuration
BACKUP_DIR="/root/backup/2fa-$(date +%Y%m%d-%H%M%S)"
PAM_CONFIG_DIR="/etc/pam.d"
SSH_CONFIG="/etc/ssh/sshd_config"
COCKPIT_CONFIG="/etc/cockpit/cockpit.conf"

# Create backup directory
mkdir -p "$BACKUP_DIR"

print_header "TSYS Two-Factor Authentication Setup"

# Backup existing configurations
function backup_configs() {
    print_info "Creating backup of existing configurations..."
    
    # Backup SSH configuration
    if [[ -f "$SSH_CONFIG" ]]; then
        cp "$SSH_CONFIG" "$BACKUP_DIR/sshd_config.bak"
        print_success "SSH config backed up"
    fi
    
    # Backup PAM configurations
    if [[ -d "$PAM_CONFIG_DIR" ]]; then
        cp -r "$PAM_CONFIG_DIR" "$BACKUP_DIR/pam.d.bak"
        print_success "PAM configs backed up"
    fi
    
    # Backup Cockpit configuration if exists
    if [[ -f "$COCKPIT_CONFIG" ]]; then
        cp "$COCKPIT_CONFIG" "$BACKUP_DIR/cockpit.conf.bak"
        print_success "Cockpit config backed up"
    fi
    
    print_info "Backup completed: $BACKUP_DIR"
}

# Install required packages
function install_2fa_packages() {
    print_info "Installing 2FA packages..."
    
    # Update package cache
    apt-get update
    
    # Install Google Authenticator PAM module
    # Install QR code generator for terminal display
    apt-get install -y libpam-google-authenticator qrencode
    
    print_success "2FA packages installed successfully"
}

# Configure SSH for 2FA
function configure_ssh_2fa() {
    print_info "Configuring SSH for 2FA..."
    
    # Configure SSH daemon
    print_info "Updating SSH configuration..."
    
    # Enable challenge-response authentication
    if ! grep -q "^ChallengeResponseAuthentication yes" "$SSH_CONFIG"; then
        sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' "$SSH_CONFIG" || \
        echo "ChallengeResponseAuthentication yes" >> "$SSH_CONFIG"
    fi
    
    # Enable PAM authentication
    if ! grep -q "^UsePAM yes" "$SSH_CONFIG"; then
        sed -i 's/^UsePAM.*/UsePAM yes/' "$SSH_CONFIG" || \
        echo "UsePAM yes" >> "$SSH_CONFIG"
    fi
    
    # Configure authentication methods (key + 2FA)
    if ! grep -q "^AuthenticationMethods" "$SSH_CONFIG"; then
        echo "AuthenticationMethods publickey,keyboard-interactive" >> "$SSH_CONFIG"
    else
        sed -i 's/^AuthenticationMethods.*/AuthenticationMethods publickey,keyboard-interactive/' "$SSH_CONFIG"
    fi
    
    print_success "SSH configuration updated"
}

# Configure PAM for 2FA
function configure_pam_2fa() {
    print_info "Configuring PAM for 2FA..."
    
    # Create backup of original PAM SSH config
    cp "$PAM_CONFIG_DIR/sshd" "$PAM_CONFIG_DIR/sshd.bak.$(date +%Y%m%d)"
    
    # Configure PAM to use Google Authenticator
    cat > "$PAM_CONFIG_DIR/sshd" << 'EOF'
# PAM configuration for SSH with 2FA
# Standard Un*x authentication
@include common-auth

# Google Authenticator 2FA
auth required pam_google_authenticator.so nullok

# Standard Un*x authorization
@include common-account

# SELinux needs to be the first session rule
session required pam_selinux.so close
session required pam_loginuid.so

# Standard Un*x session setup and teardown
@include common-session

# Print the message of the day upon successful login
session optional pam_motd.so motd=/run/motd.dynamic
session optional pam_motd.so noupdate

# Print the status of the user's mailbox upon successful login
session optional pam_mail.so standard noenv

# Set up user limits from /etc/security/limits.conf
session required pam_limits.so

# SELinux needs to intervene at login time
session required pam_selinux.so open

# Standard Un*x password updating
@include common-password
EOF
    
    print_success "PAM configuration updated for SSH 2FA"
}

# Configure Cockpit for 2FA
function configure_cockpit_2fa() {
    print_info "Configuring Cockpit for 2FA..."
    
    # Create Cockpit config directory if it doesn't exist
    mkdir -p "$(dirname "$COCKPIT_CONFIG")"
    
    # Configure Cockpit to use PAM with 2FA
    cat > "$COCKPIT_CONFIG" << 'EOF'
[WebService]
# Enable 2FA for Cockpit web interface
LoginTitle = TSYS Server Management
LoginTo = 300
RequireHost = true

[Session]
# Use PAM for authentication (includes 2FA)
Banner = /etc/cockpit/issue.cockpit
IdleTimeout = 15
EOF
    
    # Create PAM configuration for Cockpit
    cat > "$PAM_CONFIG_DIR/cockpit" << 'EOF'
# PAM configuration for Cockpit with 2FA
auth requisite pam_nologin.so
auth required pam_env.so
auth required pam_faillock.so preauth
auth sufficient pam_unix.so try_first_pass
auth required pam_google_authenticator.so nullok
auth required pam_faillock.so authfail
auth required pam_deny.so

account required pam_nologin.so
account include system-auth
account required pam_faillock.so

session required pam_selinux.so close
session required pam_loginuid.so
session optional pam_keyinit.so force revoke
session include system-auth
session required pam_selinux.so open
session optional pam_motd.so
EOF
    
    print_success "Cockpit 2FA configuration completed"
}

# Configure Webmin for 2FA (if installed)
function configure_webmin_2fa() {
    print_info "Checking for Webmin installation..."
    
    local webmin_config="/etc/webmin/miniserv.conf"
    
    if [[ -f "$webmin_config" ]]; then
        print_info "Webmin found, configuring 2FA..."
        
        # Stop webmin service
        systemctl stop webmin || true
        
        # Enable 2FA in Webmin configuration
        sed -i 's/^twofactor_provider=.*/twofactor_provider=totp/' "$webmin_config" || \
        echo "twofactor_provider=totp" >> "$webmin_config"
        
        # Enable 2FA requirement
        sed -i 's/^twofactor=.*/twofactor=1/' "$webmin_config" || \
        echo "twofactor=1" >> "$webmin_config"
        
        # Start webmin service
        systemctl start webmin || true
        
        print_success "Webmin 2FA configuration completed"
    else
        print_info "Webmin not found, skipping configuration"
    fi
}

# Setup 2FA for users
function setup_user_2fa() {
    print_info "Setting up 2FA for system users..."
    
    local users=("localuser" "root")
    
    for user in "${users[@]}"; do
        if id "$user" &>/dev/null; then
            print_info "Setting up 2FA for user: $user"
            
            # Create 2FA setup script for user
            cat > "/tmp/setup-2fa-$user.sh" << 'EOF'
#!/bin/bash
echo "Setting up Google Authenticator for user: $USER"
echo "Please follow the prompts to configure 2FA:"
echo "1. Answer 'y' to update your time-based token"
echo "2. Scan the QR code with your authenticator app"
echo "3. Save the backup codes in a secure location"
echo "4. Answer 'y' to the remaining questions for security"
echo ""
google-authenticator -t -d -f -r 3 -R 30 -W
EOF
            
            chmod +x "/tmp/setup-2fa-$user.sh"
            
            # Instructions for user setup
            cat > "/home/$user/2fa-setup-instructions.txt" << EOF
TSYS Two-Factor Authentication Setup Instructions
==============================================

Your system has been configured for 2FA. To complete setup:

1. Install an authenticator app on your phone:
   - Google Authenticator
   - Authy
   - Microsoft Authenticator

2. Run the setup command:
   sudo /tmp/setup-2fa-$user.sh

3. Follow the prompts:
   - Scan the QR code with your app
   - Save the backup codes securely
   - Answer 'y' to security questions

4. Test your setup:
   - SSH to the server
   - Enter your 6-digit code when prompted

IMPORTANT: Save backup codes in a secure location!
Without them, you may be locked out if you lose your phone.

For support, contact your system administrator.
EOF
            
            chown "$user:$user" "/home/$user/2fa-setup-instructions.txt"
            print_success "2FA setup prepared for user: $user"
        else
            print_warning "User $user not found, skipping"
        fi
    done
}

# Restart services
function restart_services() {
    print_info "Restarting services..."
    
    # Test SSH configuration
    if sshd -t; then
        systemctl restart sshd
        print_success "SSH service restarted"
    else
        print_error "SSH configuration test failed"
        return 1
    fi
    
    # Restart Cockpit if installed
    if systemctl is-enabled cockpit.socket &>/dev/null; then
        systemctl restart cockpit.socket
        print_success "Cockpit service restarted"
    fi
    
    # Restart Webmin if installed
    if systemctl is-enabled webmin &>/dev/null; then
        systemctl restart webmin
        print_success "Webmin service restarted"
    fi
}

# Validation and testing
function validate_2fa_setup() {
    print_info "Validating 2FA setup..."
    
    # Check if Google Authenticator is installed
    if command -v google-authenticator &>/dev/null; then
        print_success "Google Authenticator installed"
    else
        print_error "Google Authenticator not found"
        return 1
    fi
    
    # Check SSH configuration
    if grep -q "AuthenticationMethods publickey,keyboard-interactive" "$SSH_CONFIG"; then
        print_success "SSH 2FA configuration valid"
    else
        print_error "SSH 2FA configuration invalid"
        return 1
    fi
    
    # Check PAM configuration
    if grep -q "pam_google_authenticator.so" "$PAM_CONFIG_DIR/sshd"; then
        print_success "PAM 2FA configuration valid"
    else
        print_error "PAM 2FA configuration invalid"
        return 1
    fi
    
    # Check service status
    if systemctl is-active sshd &>/dev/null; then
        print_success "SSH service is running"
    else
        print_error "SSH service is not running"
        return 1
    fi
    
    print_success "2FA validation completed successfully"
}

# Display final instructions
function show_final_instructions() {
    print_header "2FA Setup Completed"
    
    print_info "Two-Factor Authentication has been configured for:"
    print_info "- SSH (requires key + 2FA token)"
    print_info "- Cockpit web interface"
    if [[ -f "/etc/webmin/miniserv.conf" ]]; then
        print_info "- Webmin administration panel"
    fi
    
    print_warning "IMPORTANT: Complete user setup immediately!"
    print_warning "1. Check /home/*/2fa-setup-instructions.txt for user setup"
    print_warning "2. Run setup scripts for each user"
    print_warning "3. Test 2FA before logging out"
    
    print_info "Backup location: $BACKUP_DIR"
    print_info "To disable 2FA, restore configurations from backup"
    
    print_success "2FA setup completed successfully!"
}

# Main execution
function main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Execute setup steps
    backup_configs
    install_2fa_packages
    configure_ssh_2fa
    configure_pam_2fa
    configure_cockpit_2fa
    configure_webmin_2fa
    setup_user_2fa
    restart_services
    validate_2fa_setup
    show_final_instructions
}

# Run main function
main "$@"