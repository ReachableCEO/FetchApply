# TSYS FetchApply Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the TSYS FetchApply infrastructure provisioning system on Linux servers.

## Prerequisites

### System Requirements
- **Operating System:** Ubuntu 18.04+ or Debian 10+ (recommended)
- **RAM:** Minimum 2GB, recommended 4GB
- **Disk Space:** Minimum 10GB free space
- **Network:** Internet connectivity for package downloads
- **Privileges:** Root or sudo access required

### Required Tools
- `git` - Version control system
- `curl` - HTTP client for downloads
- `wget` - Alternative download tool
- `systemctl` - System service management
- `apt-get` - Package management (Debian/Ubuntu)

### Network Requirements
- **HTTPS access** to:
  - `https://archive.ubuntu.com` (Ubuntu packages)
  - `https://linux.dell.com` (Dell hardware support)
  - `https://download.proxmox.com` (Proxmox packages)
  - `https://github.com` (Git repositories)

## Pre-Deployment Validation

### 1. System Compatibility Check
```bash
# Clone repository
git clone [repository-url]
cd FetchApply

# Run system validation
./Project-Tests/validation/system-requirements.sh
```

### 2. Network Connectivity Test
```bash
# Test network connectivity
curl -I https://archive.ubuntu.com
curl -I https://linux.dell.com
curl -I https://download.proxmox.com
```

### 3. Permission Verification
```bash
# Verify write permissions
test -w /etc && echo "✅ /etc writable" || echo "❌ /etc not writable"
test -w /usr/local/bin && echo "✅ /usr/local/bin writable" || echo "❌ /usr/local/bin not writable"
```

## Deployment Methods

### Method 1: Standard Deployment (Recommended)
```bash
# 1. Clone repository
git clone [repository-url]
cd FetchApply

# 2. Run pre-deployment tests
./Project-Tests/run-tests.sh validation

# 3. Execute deployment
cd ProjectCode
sudo bash SetupNewSystem.sh
```

### Method 2: Dry Run Mode
```bash
# 1. Clone repository
git clone [repository-url]
cd FetchApply

# 2. Review configuration
cat ProjectCode/SetupNewSystem.sh

# 3. Execute with manual review
cd ProjectCode
sudo bash -x SetupNewSystem.sh  # Debug mode
```

## Deployment Process

### Phase 1: Framework Initialization
1. **Environment Setup**
   - Load framework variables
   - Source framework includes
   - Initialize logging system

2. **System Detection**
   - Detect physical vs virtual hardware
   - Identify operating system
   - Check for existing users

### Phase 2: Base System Configuration
1. **Package Installation**
   - Update package repositories
   - Install essential packages
   - Configure package sources

2. **User Management**
   - Create required user accounts
   - Configure SSH access
   - Set up sudo permissions

### Phase 3: Security Hardening
1. **SSH Configuration**
   - Deploy hardened SSH configuration
   - Install SSH keys
   - Disable password authentication

2. **System Hardening**
   - Configure firewall rules
   - Enable audit logging
   - Install security tools

### Phase 4: Monitoring and Management
1. **Monitoring Agents**
   - Deploy LibreNMS agents
   - Configure SNMP
   - Set up system monitoring

2. **Management Tools**
   - Install Cockpit dashboard
   - Configure remote access
   - Set up maintenance scripts

## Post-Deployment Verification

### 1. Security Validation
```bash
# Run security tests
./Project-Tests/run-tests.sh security

# Verify SSH configuration
ssh -T [server-ip]  # Should work with key authentication
```

### 2. Service Status Check
```bash
# Check critical services
sudo systemctl status ssh
sudo systemctl status auditd
sudo systemctl status snmpd
```

### 3. Network Connectivity
```bash
# Test internal services
curl -k https://localhost:9090  # Cockpit
snmpwalk -v2c -c public localhost system
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors
```bash
# Solution: Run with sudo
sudo bash SetupNewSystem.sh
```

#### 2. Network Connectivity Issues
```bash
# Check DNS resolution
nslookup archive.ubuntu.com

# Test direct IP access
curl -I 91.189.91.26  # Ubuntu archive IP
```

#### 3. Package Installation Failures
```bash
# Update package cache
sudo apt-get update

# Fix broken packages
sudo apt-get -f install
```

#### 4. SSH Key Issues
```bash
# Verify key permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Debug Mode
```bash
# Enable debug logging
export DEBUG=1
bash -x SetupNewSystem.sh
```

### Log Analysis
```bash
# Check deployment logs
tail -f /var/log/fetchapply/deployment.log

# Review system logs
journalctl -u ssh
journalctl -u auditd
```

## Environment-Specific Configurations

### Physical Dell Servers
- **OMSA Installation:** Dell OpenManage Server Administrator
- **Hardware Monitoring:** iDRAC configuration
- **Performance Tuning:** CPU and memory optimizations

### Virtual Machines
- **Guest Additions:** VMware tools or VirtualBox additions
- **Resource Limits:** Memory and CPU constraints
- **Network Configuration:** Bridge vs NAT settings

### Development Environments
- **SSH Configuration:** Less restrictive settings
- **Development Tools:** Additional packages for development
- **Testing Access:** Enhanced logging and debugging

## Maintenance and Updates

### Regular Maintenance
```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade

# Update monitoring scripts
cd /usr/local/bin
sudo wget https://[repository]/scripts/up2date.sh
sudo chmod +x up2date.sh
```

### Security Updates
```bash
# Check for security updates
sudo apt-get update
sudo apt list --upgradable | grep -i security

# Apply security patches
sudo apt-get upgrade
```

### Configuration Updates
```bash
# Update FetchApply
cd FetchApply
git pull origin main

# Re-run specific modules
cd ProjectCode/Modules/Security
sudo bash secharden-ssh.sh
```

## Best Practices

### 1. Pre-Deployment
- Always test in non-production environment first
- Review all scripts before execution
- Validate network connectivity
- Ensure proper backup procedures

### 2. During Deployment
- Monitor deployment progress
- Check for errors and warnings
- Document any customizations
- Validate each phase completion

### 3. Post-Deployment
- Run full security test suite
- Verify all services are running
- Test remote access
- Document deployment specifics

### 4. Ongoing Operations
- Regular security updates
- Monitor system performance
- Review audit logs
- Maintain deployment documentation

## Support and Resources

### Documentation
- **README.md:** Basic usage instructions
- **SECURITY.md:** Security architecture and guidelines
- **Project-Tests/README.md:** Testing framework documentation

### Community Support
- **Issues:** https://projects.knownelement.com/project/reachableceo-vptechnicaloperations/timeline
- **Discussion:** https://community.turnsys.com/c/chieftechnologyandproductofficer/26

### Professional Support
- **Technical Support:** [Contact information to be added]
- **Consulting Services:** [Contact information to be added]

## Deployment Checklist

### Pre-Deployment
- [ ] System requirements validated
- [ ] Network connectivity tested
- [ ] Backup procedures in place
- [ ] Security review completed

### Deployment
- [ ] Repository cloned successfully
- [ ] Pre-deployment tests passed
- [ ] Deployment executed without errors
- [ ] Post-deployment verification completed

### Post-Deployment
- [ ] Security tests passed
- [ ] All services running
- [ ] Remote access verified
- [ ] Documentation updated

### Maintenance
- [ ] Update schedule established
- [ ] Monitoring configured
- [ ] Backup procedures tested
- [ ] Incident response plan activated

## Version History

- **v1.0:** Initial deployment framework
- **v1.1:** Added security hardening and secrets management
- **v1.2:** Enhanced testing framework and documentation

Last updated: July 14, 2025