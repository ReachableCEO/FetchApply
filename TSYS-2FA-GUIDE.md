# TSYS Two-Factor Authentication Implementation Guide

## Overview

This guide provides complete instructions for implementing and managing two-factor authentication (2FA) on TSYS servers using Google Authenticator (TOTP).

## What This Implementation Provides

### Services Protected by 2FA
- **SSH Access:** Requires SSH key + 2FA token
- **Cockpit Web Interface:** Requires password + 2FA token
- **Webmin Administration:** Requires password + 2FA token (if installed)

### Security Features
- **Time-based One-Time Passwords (TOTP):** Standard 6-digit codes
- **Backup Codes:** Emergency access codes
- **Gradual Rollout:** Optional nullok mode for phased deployment
- **Configuration Backup:** Automatic backup of all configs

## Implementation Steps

### Step 1: Run the 2FA Setup Script
```bash
# Navigate to the security modules directory
cd ProjectCode/Modules/Security

# Run the 2FA setup script as root
sudo bash secharden-2fa.sh
```

### Step 2: Validate Installation
```bash
# Run 2FA validation tests
./Project-Tests/security/2fa-validation.sh

# Run specific 2FA security test
./Project-Tests/run-tests.sh security
```

### Step 3: Setup Individual Users
For each user that needs 2FA access:

```bash
# Check setup instructions
cat /home/username/2fa-setup-instructions.txt

# Run user setup script
sudo /tmp/setup-2fa-username.sh
```

### Step 4: Test 2FA Access
1. **Test SSH access** from another terminal
2. **Test Cockpit access** via web browser
3. **Test Webmin access** if installed

## User Setup Process

### Installing Authenticator Apps
Users need one of these apps on their phone:
- **Google Authenticator** (Android/iOS)
- **Authy** (Android/iOS)
- **Microsoft Authenticator** (Android/iOS)
- **1Password** (with TOTP support)

### Setting Up 2FA for a User
1. **Run setup script:**
   ```bash
   sudo /tmp/setup-2fa-username.sh
   ```

2. **Follow prompts:**
   - Answer "y" to update time-based token
   - Scan QR code with authenticator app
   - Save emergency backup codes securely
   - Answer "y" to remaining security questions

3. **Test immediately:**
   ```bash
   # Test SSH from another terminal
   ssh username@server-ip
   # You'll be prompted for 6-digit code
   ```

## Configuration Details

### SSH Configuration Changes
File: `/etc/ssh/sshd_config`
```
ChallengeResponseAuthentication yes
UsePAM yes
AuthenticationMethods publickey,keyboard-interactive
```

### PAM Configuration
File: `/etc/pam.d/sshd`
```
auth required pam_google_authenticator.so nullok
```

### Cockpit Configuration
File: `/etc/cockpit/cockpit.conf`
```
[WebService]
LoginTitle = TSYS Server Management
LoginTo = 300
RequireHost = true

[Session]
Banner = /etc/cockpit/issue.cockpit
IdleTimeout = 15
```

### Webmin Configuration
File: `/etc/webmin/miniserv.conf`
```
twofactor_provider=totp
twofactor=1
```

## Security Considerations

### Gradual vs Strict Enforcement

#### Gradual Enforcement (Default)
- Uses `nullok` option in PAM
- Users without 2FA can still log in
- Allows phased rollout
- Good for initial deployment

#### Strict Enforcement
- Remove `nullok` from PAM configuration
- All users must have 2FA configured
- Immediate security enforcement
- Risk of lockout if misconfigured

### Backup and Recovery

#### Emergency Access
- **Backup codes:** Generated during setup
- **Root access:** Can disable 2FA if needed
- **Console access:** Physical/virtual console bypasses SSH

#### Configuration Backup
- Automatic backup to `/root/backup/2fa-TIMESTAMP/`
- Includes all modified configuration files
- Can be restored if needed

## Troubleshooting

### Common Issues

#### 1. User Cannot Generate QR Code
```bash
# Ensure qrencode is installed
sudo apt-get install qrencode

# Re-run user setup
sudo /tmp/setup-2fa-username.sh
```

#### 2. SSH Connection Fails
```bash
# Check SSH service status
sudo systemctl status sshd

# Test SSH configuration
sudo sshd -t

# Check logs
sudo journalctl -u sshd -f
```

#### 3. 2FA Code Not Accepted
- **Check time synchronization** on server and phone
- **Verify app setup** - rescan QR code if needed
- **Try backup codes** if available

#### 4. Locked Out of Server
```bash
# Access via console (physical/virtual)
# Disable 2FA temporarily
sudo cp /root/backup/2fa-*/pam.d.bak/sshd /etc/pam.d/sshd
sudo systemctl restart sshd
```

### Debug Commands

```bash
# Check 2FA status
./Project-Tests/security/2fa-validation.sh

# Check SSH configuration
sudo sshd -T | grep -E "(Challenge|PAM|Authentication)"

# Check PAM configuration
cat /etc/pam.d/sshd | grep google-authenticator

# Check user 2FA status
ls -la ~/.google_authenticator
```

## Management and Maintenance

### Adding New Users
1. Ensure user account exists
2. Run setup script for new user
3. Provide setup instructions
4. Test access

### Removing User 2FA
```bash
# Remove user's 2FA configuration
sudo rm /home/username/.google_authenticator

# User will need to re-setup 2FA
```

### Disabling 2FA System-Wide
```bash
# Restore original configurations
sudo cp /root/backup/2fa-*/sshd_config.bak /etc/ssh/sshd_config
sudo cp /root/backup/2fa-*/pam.d.bak/sshd /etc/pam.d/sshd
sudo systemctl restart sshd
```

### Updating 2FA Configuration
```bash
# Re-run setup script
sudo bash secharden-2fa.sh

# Validate changes
./Project-Tests/security/2fa-validation.sh
```

## Best Practices

### Deployment Strategy
1. **Test in non-production** environment first
2. **Enable gradual rollout** (nullok) initially
3. **Train users** on 2FA setup process
4. **Test emergency procedures** before strict enforcement
5. **Monitor logs** for authentication issues

### Security Recommendations
- **Enforce strict mode** after successful rollout
- **Regular backup code rotation**
- **Monitor failed authentication attempts**
- **Document emergency procedures**
- **Regular security audits**

### User Training
- **Provide clear instructions**
- **Demonstrate setup process**
- **Explain backup code importance**
- **Test login process with users**
- **Establish support procedures**

## Monitoring and Logging

### Authentication Logs
```bash
# SSH authentication logs
sudo journalctl -u sshd | grep -i "authentication"

# PAM authentication logs
sudo journalctl | grep -i "pam_google_authenticator"

# Failed login attempts
sudo journalctl | grep -i "failed"
```

### Security Monitoring
- Monitor for repeated failed 2FA attempts
- Alert on successful logins without 2FA (during gradual rollout)
- Track user 2FA setup completion
- Monitor for emergency access usage

## Integration with Existing Systems

### LDAP/Active Directory
- 2FA works with existing authentication systems
- Users still need local 2FA setup
- Consider centralized 2FA solutions for large deployments

### Monitoring Systems
- LibreNMS: Will continue to work with SNMP
- Wazuh: Will log 2FA authentication events
- Cockpit: Enhanced with 2FA protection

### Backup Systems
- Ensure backup procedures account for 2FA
- Test restore procedures with 2FA enabled
- Document emergency access procedures

## Support and Resources

### Files Created by Setup
- `/tmp/setup-2fa-*.sh` - User setup scripts
- `/home/*/2fa-setup-instructions.txt` - User instructions
- `/root/backup/2fa-*/` - Configuration backups

### Validation Tools
- `./Project-Tests/security/2fa-validation.sh` - Complete 2FA validation
- `./Project-Tests/run-tests.sh security` - Security test suite

### Emergency Contacts
- System Administrator: [Contact Info]
- Security Team: [Contact Info]
- 24/7 Support: [Contact Info]

## Compliance and Audit

### Security Benefits
- Significantly reduces risk of unauthorized access
- Meets multi-factor authentication requirements
- Provides audit trail of authentication events
- Complies with security frameworks (NIST, ISO 27001)

### Audit Trail
- All authentication attempts logged
- 2FA setup events recorded
- Configuration changes tracked
- Emergency access documented

---

**Last Updated:** July 14, 2025  
**Version:** 1.0  
**Author:** TSYS Security Team