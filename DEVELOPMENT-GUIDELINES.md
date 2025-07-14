# TSYS FetchApply Development Guidelines

## Overview

This document contains development standards and best practices for the TSYS FetchApply infrastructure provisioning system.

## Package Management Best Practices

### Combine apt-get Install Commands

**Rule:** Always combine multiple package installations into a single `apt-get install` command for performance.

**Rationale:** Single command execution is significantly faster than multiple separate commands due to:
- Reduced package cache processing
- Single dependency resolution
- Fewer network connections
- Optimized package download ordering

#### ✅ Correct Implementation
```bash
# Install all packages in one command
apt-get install -y package1 package2 package3 package4

# Real example from 2FA script
apt-get install -y libpam-google-authenticator qrencode
```

#### ❌ Incorrect Implementation
```bash
# Don't use separate commands for each package
apt-get install -y package1
apt-get install -y package2
apt-get install -y package3
```

#### Complex Package Installation Pattern
```bash
function install_security_packages() {
    print_info "Installing security packages..."
    
    # Update package cache once
    apt-get update
    
    # Install all packages in single command
    apt-get install -y \
        auditd \
        fail2ban \
        libpam-google-authenticator \
        lynis \
        rkhunter \
        aide \
        chkrootkit \
        clamav \
        clamav-daemon
    
    print_success "Security packages installed successfully"
}
```

## Script Development Standards

### Error Handling
- Always use `set -euo pipefail` at script start
- Implement proper error trapping
- Use framework error handling functions
- Return appropriate exit codes

### Function Structure
```bash
function function_name() {
    print_info "Description of what function does..."
    
    # Local variables
    local var1="value"
    local var2="value"
    
    # Function logic
    if [[ condition ]]; then
        print_success "Success message"
        return 0
    else
        print_error "Error message"
        return 1
    fi
}
```

### Framework Integration
- Source framework includes at script start
- Use framework logging and pretty print functions
- Follow existing patterns for consistency
- Include proper PROJECT_ROOT path resolution

```bash
# Standard framework sourcing pattern
PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."
source "$PROJECT_ROOT/Framework-Includes/PrettyPrint.sh"
source "$PROJECT_ROOT/Framework-Includes/Logging.sh"
source "$PROJECT_ROOT/Framework-Includes/ErrorHandling.sh"
```

## Code Quality Standards

### ShellCheck Compliance
- All scripts must pass shellcheck validation
- Address shellcheck warnings appropriately
- Use proper quoting for variables
- Handle edge cases and error conditions

### Variable Naming
- Use UPPERCASE for global constants
- Use lowercase for local variables
- Use descriptive names
- Quote all variable expansions

```bash
# Global constants
declare -g BACKUP_DIR="/root/backup"
declare -g CONFIG_FILE="/etc/ssh/sshd_config"

# Local variables
local user_name="localuser"
local temp_file="/tmp/config.tmp"

# Proper quoting
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$BACKUP_DIR/"
fi
```

### Function Documentation
- Include purpose description
- Document parameters if any
- Document return values
- Include usage examples for complex functions

```bash
# Configure SSH hardening settings
# Parameters: none
# Returns: 0 on success, 1 on failure
# Usage: configure_ssh_hardening
function configure_ssh_hardening() {
    print_info "Configuring SSH hardening..."
    # Implementation
}
```

## Testing Requirements

### Test Coverage
- Every new module must include corresponding tests
- Test both success and failure scenarios
- Validate configurations after changes
- Include integration tests for complex workflows

### Test Categories
1. **Unit Tests:** Individual function validation
2. **Integration Tests:** Module interaction testing
3. **Security Tests:** Security configuration validation
4. **Validation Tests:** System requirement checking

### Test Implementation Pattern
```bash
function test_function_name() {
    echo "🔍 Testing specific functionality..."
    
    local failed=0
    
    # Test implementation
    if [[ condition ]]; then
        echo "✅ Test passed"
    else
        echo "❌ Test failed"
        ((failed++))
    fi
    
    return $failed
}
```

## Security Standards

### Configuration Backup
- Always backup configurations before modification
- Use timestamped backup directories
- Provide restore instructions
- Test backup/restore procedures

### Service Management
- Test configurations before restarting services
- Provide rollback procedures
- Validate service status after changes
- Include service dependency handling

### User Safety
- Use `nullok` for gradual 2FA rollout
- Provide clear setup instructions
- Include emergency access procedures
- Test all access methods before enforcement

## Documentation Standards

### Script Headers
```bash
#!/bin/bash

# TSYS Module Name - Brief Description
# Longer description of what this script does
# Author: TSYS Development Team
# Version: 1.0
# Last Updated: YYYY-MM-DD

set -euo pipefail
```

### Inline Documentation
- Comment complex logic
- Explain non-obvious decisions
- Document external dependencies
- Include troubleshooting notes

### User Documentation
- Create comprehensive guides for complex features
- Include step-by-step procedures
- Provide troubleshooting sections
- Include examples and use cases

## Performance Optimization

### Package Management
- Single apt-get commands (as noted above)
- Cache package lists appropriately
- Use specific package versions when stability required
- Clean up package cache when appropriate

### Network Operations
- Use connection timeouts for external requests
- Implement retry logic with backoff
- Cache downloaded resources when possible
- Validate download integrity

### File Operations
- Use efficient file processing tools
- Minimize file system operations
- Use appropriate file permissions
- Clean up temporary files

## Version Control Practices

### Commit Messages
- Use descriptive commit messages
- Include scope of changes
- Reference related issues/requirements
- Follow established commit message format

### Branch Management
- Test changes in feature branches
- Use pull requests for review
- Maintain clean commit history
- Tag releases appropriately

### Code Review Requirements
- All changes require review
- Security changes require security team review
- Test coverage must be maintained
- Documentation must be updated

## Deployment Practices

### Pre-Deployment
- Run full test suite
- Validate in test environment
- Review security implications
- Update documentation

### Deployment Process
- Use configuration validation
- Implement gradual rollout when possible
- Monitor for issues during deployment
- Have rollback procedures ready

### Post-Deployment
- Validate deployment success
- Monitor system performance
- Update operational documentation
- Gather feedback for improvements

## Example Implementation

### Complete Module Template
```bash
#!/bin/bash

# TSYS Security Module - Template
# Template for creating new security modules
# Author: TSYS Development Team

set -euo pipefail

# Source framework functions
PROJECT_ROOT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."
source "$PROJECT_ROOT/Framework-Includes/PrettyPrint.sh"
source "$PROJECT_ROOT/Framework-Includes/Logging.sh"
source "$PROJECT_ROOT/Framework-Includes/ErrorHandling.sh"

# Module configuration
BACKUP_DIR="/root/backup/module-$(date +%Y%m%d-%H%M%S)"
CONFIG_FILE="/etc/example.conf"

# Create backup directory
mkdir -p "$BACKUP_DIR"

print_header "TSYS Module Template"

function backup_configs() {
    print_info "Creating configuration backup..."
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$BACKUP_DIR/"
        print_success "Configuration backed up"
    fi
}

function install_packages() {
    print_info "Installing required packages..."
    
    # Update package cache
    apt-get update
    
    # Install all packages in single command
    apt-get install -y package1 package2 package3
    
    print_success "Packages installed successfully"
}

function configure_module() {
    print_info "Configuring module..."
    
    # Configuration logic here
    
    print_success "Module configured successfully"
}

function validate_configuration() {
    print_info "Validating configuration..."
    
    local failed=0
    
    # Validation logic here
    
    if [[ $failed -eq 0 ]]; then
        print_success "Configuration validation passed"
        return 0
    else
        print_error "Configuration validation failed"
        return 1
    fi
}

function main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Execute module steps
    backup_configs
    install_packages
    configure_module
    validate_configuration
    
    print_success "Module setup completed successfully!"
}

# Run main function
main "$@"
```

## Continuous Improvement

### Regular Reviews
- Review guidelines quarterly
- Update based on lessons learned
- Incorporate new best practices
- Gather team feedback

### Tool Updates
- Keep development tools current
- Adopt new security practices
- Update testing frameworks
- Improve automation

### Knowledge Sharing
- Document lessons learned
- Share best practices
- Provide training materials
- Maintain knowledge base

---

**Last Updated:** July 14, 2025  
**Version:** 1.0  
**Author:** TSYS Development Team

**Note:** These guidelines are living documents and should be updated as the project evolves and new best practices are identified.