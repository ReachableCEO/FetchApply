# Charles TODO - TSYS FetchApply Security Improvements

**Priority Order:** High → Medium → Low  
**Target:** Address security vulnerabilities and operational improvements

## 🚨 HIGH PRIORITY (Security Critical)

### 1. Replace Insecure Deployment Method
**Current Issue:** `curl https://dl.knownelement.com/KNEL/FetchApply/SetupNewSystem.sh | bash`
**Action Required:**
- Create signed packages (`.deb`/`.rpm`) for distribution
- Implement GPG signature verification for scripts
- Consider using configuration management tools (Ansible, Puppet, Salt)
- Add cryptographic checksums for all downloadable components

**Files to modify:**
- `README.md` (line 19) - update deployment instructions
- `ProjectCode/SetupNewSystem.sh` - add integrity checks

### 2. Enforce HTTPS for All Downloads
**Current Issue:** HTTP URLs in Dell OMSA and some repository setups
**Action Required:**
- Replace HTTP URLs with HTTPS equivalents in:
  - `ProjectCode/Dell/Server/omsa.sh` (lines 19-28)
  - `ProjectCode/legacy/prox7.sh` (line 3)
- Verify SSL certificate validation is enabled
- Add fallback mechanisms for certificate failures

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

**Week 1:** Items 1-2 (Critical security fixes)  
**Week 2:** Item 3 (Secrets management)  
**Week 3-4:** Items 4-5 (Operational improvements)  
**Month 2:** Items 6-10 (Quality and monitoring)

## Success Criteria

- [ ] No plaintext secrets in repository
- [ ] All downloads use HTTPS with verification
- [ ] Deployment method is cryptographically secure
- [ ] Automated testing validates security configurations
- [ ] Rollback capability exists for all changes
- [ ] Comprehensive documentation covers security implications

## Resources Needed

- Access to package repository for signed distributions
- GPG key infrastructure for signing
- Secrets management service (Vault/Bitwarden)
- Test environment infrastructure
- Security scanning tools integration