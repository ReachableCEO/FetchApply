# Charles TODO - TSYS FetchApply Security Improvements

**Priority Order:** High → Medium → Low  
**Target:** Address security vulnerabilities and operational improvements

## 🚨 HIGH PRIORITY (Security Critical)

### ✅ 1. Replace Insecure Deployment Method - RESOLVED
**Previous Issue:** `curl https://dl.knownelement.com/KNEL/FetchApply/SetupNewSystem.sh | bash`
**Status:** Fixed in README.md - now uses secure git clone approach
**Current Method:** `git clone this repo` → `cd FetchApply/ProjectCode` → `bash SetupNewSystem.sh`

**Remaining considerations:**
- Consider implementing GPG signature verification for tagged releases
- Add cryptographic checksums for external downloads within scripts

### ✅ 2. Enforce HTTPS for All Downloads - RESOLVED
**Previous Issue:** HTTP URLs in Dell OMSA and some repository setups
**Status:** All HTTP URLs converted to HTTPS across:
  - `ProjectCode/Dell/Server/omsa.sh` - Ubuntu archive and Dell repo URLs
  - `ProjectCode/legacy/prox7.sh` - Proxmox download URLs
  - `ProjectCode/Modules/RandD/sslStackFromSource.sh` - Apache source URLs

**Remaining considerations:**
- SSL certificate validation is enabled by default in wget/curl
- Consider adding retry logic for certificate failures

### 3. Implement Secrets Management
**Current Issue:** SSH keys committed to repository, no secrets rotation
**Action Required:**
- Deploy Bitwarden CLI or HashiCorp Vault integration
- Remove SSH public keys from repository
- Create secure key distribution mechanism
- Implement key rotation procedures
- Add environment variable support for sensitive data

**Files to secure:**
- `ProjectCode/ConfigFiles/SSH/AuthorizedKeys/` (entire directory)
- Hard-coded hostnames in various scripts

## 🔶 MEDIUM PRIORITY (Operational Security)

### 4. Add Script Integrity Verification
**Action Required:**
- Generate SHA256 checksums for all scripts
- Create checksum verification function in Framework-Includes
- Add signature verification for external downloads
- Implement rollback capability on verification failure

### 5. Enhanced Error Recovery
**Action Required:**
- Add state tracking for partial deployments
- Implement resume functionality for interrupted installations
- Create system restoration points before major changes
- Add dependency checking before module execution

### 6. Security Testing Framework
**Action Required:**
- Create integration tests for security configurations
- Add compliance validation (CIS benchmarks, STIG)
- Implement automated security scanning post-deployment
- Create test environments for validation

### 7. Configuration Validation
**Action Required:**
- Add pre-flight checks for system compatibility
- Validate network connectivity to required services
- Check for conflicting software before installation
- Verify sufficient disk space and system resources

## 🔹 LOW PRIORITY (Quality Improvements)

### 8. Documentation Enhancement
**Action Required:**
- Create detailed security architecture documentation
- Add troubleshooting guides for common issues
- Document security implications of each module
- Create deployment runbooks for different environments

### 9. Monitoring and Alerting
**Action Required:**
- Add deployment success/failure reporting
- Implement centralized logging for all installations
- Create dashboards for deployment status
- Add alerting for security configuration drift

### 10. User Experience Improvements
**Action Required:**
- Create web-based deployment interface
- Add progress indicators for long-running operations
- Implement dry-run mode for testing configurations
- Add interactive configuration selection

## Implementation Timeline

**✅ COMPLETED:** Item 1 (Secure deployment method)  
**✅ COMPLETED:** Item 2 (HTTPS enforcement)  
**Week 1:** Item 3 (Secrets management)  
**Week 2-3:** Items 4-5 (Operational improvements)  
**Month 2:** Items 6-10 (Quality and monitoring)

## Success Criteria

- [ ] No plaintext secrets in repository
- [x] All downloads use HTTPS with verification ✅
- [x] Deployment method is cryptographically secure ✅
- [ ] Automated testing validates security configurations
- [ ] Rollback capability exists for all changes
- [ ] Comprehensive documentation covers security implications

## Resources Needed

- Access to package repository for signed distributions
- GPG key infrastructure for signing
- Secrets management service (Vault/Bitwarden)
- Test environment infrastructure
- Security scanning tools integration