# Claude TODO - TSYS FetchApply Automation Tasks

**Purpose:** Actionable items optimized for AI assistant implementation  
**Priority:** Critical → High → Medium → Low

## 🚨 CRITICAL (Immediate Security Fixes)

### TASK-001: Replace HTTP URLs with HTTPS
**Files to modify:**
- `ProjectCode/Dell/Server/omsa.sh:19-28` - Replace `http://archive.ubuntu.com` with `https://archive.ubuntu.com`
- `ProjectCode/legacy/prox7.sh:3` - Replace `http://download.proxmox.com` with `https://download.proxmox.com`

**Implementation:**
```bash
# Search and replace HTTP URLs
sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g' ProjectCode/Dell/Server/omsa.sh
sed -i 's|http://download.proxmox.com|https://download.proxmox.com|g' ProjectCode/legacy/prox7.sh
```

### TASK-002: Add Download Integrity Verification
**Create new function in:** `Framework-Includes/VerifyDownload.sh`
**Function to implement:**
```bash
function verify_download() {
    local url="$1"
    local expected_hash="$2"
    local output_file="$3"
    
    curl -fsSL "$url" -o "$output_file"
    local actual_hash=$(sha256sum "$output_file" | cut -d' ' -f1)
    
    if [ "$actual_hash" != "$expected_hash" ]; then
        print_error "Hash verification failed for $output_file"
        rm -f "$output_file"
        return 1
    fi
    print_info "Download verified: $output_file"
}
```

### TASK-003: Create Secure Deployment Script
**Create:** `ProjectCode/SecureSetupNewSystem.sh`
**Features to implement:**
- GPG signature verification
- SHA256 checksum validation
- HTTPS-only downloads
- Rollback capability

## 🔶 HIGH (Security Enhancements)

### TASK-004: Remove Hardcoded SSH Keys
**Files to modify:**
- `ProjectCode/ConfigFiles/SSH/AuthorizedKeys/root-ssh-authorized-keys`
- `ProjectCode/ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys`
- `ProjectCode/Modules/Security/secharden-ssh.sh:31,40,51`

**Implementation approach:**
1. Create environment variable support: `SSH_KEYS_URL` or `SSH_KEYS_VAULT_PATH`
2. Modify secharden-ssh.sh to fetch keys from secure source
3. Add key validation before deployment

### TASK-005: Add Secrets Management Framework
**Create:** `Framework-Includes/SecretsManager.sh`
**Functions to implement:**
```bash
function get_secret() { }           # Retrieve secret from vault
function validate_secret() { }      # Validate secret format
function rotate_secret() { }        # Trigger secret rotation
```

### TASK-006: Enhanced Preflight Checks
**Modify:** `Framework-Includes/PreflightCheck.sh`
**Add checks for:**
- Network connectivity to required hosts
- Disk space requirements
- Existing conflicting software
- Required system capabilities

## 🔹 MEDIUM (Operational Improvements)

### TASK-007: Add Configuration Backup
**Create:** `Framework-Includes/ConfigBackup.sh`
**Functions:**
```bash
function backup_config() { }        # Create timestamped backup
function restore_config() { }       # Restore from backup
function list_backups() { }         # Show available backups
```

### TASK-008: Implement State Tracking
**Create:** `Framework-Includes/StateManager.sh`
**Track:**
- Deployment progress
- Module completion status
- Rollback points
- System changes made

### TASK-009: Add Retry Logic
**Enhance existing scripts with:**
- Configurable retry attempts for network operations
- Exponential backoff for failed operations
- Circuit breaker for repeatedly failing services

## 🔸 LOW (Quality of Life)

### TASK-010: Enhanced Logging
**Modify:** `Framework-Includes/Logging.sh`
**Add:**
- Structured logging (JSON format option)
- Log levels (DEBUG, INFO, WARN, ERROR)
- Remote logging capability
- Log rotation management

### TASK-011: Progress Indicators
**Add to:** `Framework-Includes/PrettyPrint.sh`
```bash
function show_progress() { }        # Display progress bar
function update_status() { }        # Update current operation
```

### TASK-012: Dry Run Mode
**Add to:** `ProjectCode/SetupNewSystem.sh`
**Implementation:**
- `--dry-run` flag support
- Preview of changes without execution
- Dependency analysis output

## Implementation Order for Claude

1. **Start with TASK-001** (simple find/replace operations)
2. **Create framework functions** (TASK-002, TASK-005, TASK-007)
3. **Enhance existing modules** (TASK-004, TASK-006)
4. **Add operational features** (TASK-008, TASK-009)
5. **Improve user experience** (TASK-010, TASK-011, TASK-012)

## File Location Patterns

- **Framework components:** `Framework-Includes/*.sh`
- **Security modules:** `ProjectCode/Modules/Security/*.sh`
- **Configuration files:** `ProjectCode/ConfigFiles/*/`
- **Main entry point:** `ProjectCode/SetupNewSystem.sh`

## Testing Strategy

For each task:
1. Create backup of original files
2. Implement changes incrementally
3. Test with `bash -n` for syntax validation
4. Verify functionality with controlled test runs
5. Document changes made

## Error Handling Requirements

All new functions must:
- Use `set -euo pipefail` compatibility
- Integrate with existing error handling framework
- Log errors to `$LOGFILENAME`
- Return appropriate exit codes
- Clean up temporary files on failure