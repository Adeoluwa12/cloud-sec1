# Project 01 — Zero Trust Identity & Access Platform


## Overview

Designed and deployed a production-grade Zero Trust identity platform on Microsoft Entra ID 
for a simulated 10-user organisation across 4 departments. The platform enforces all three 
Zero Trust principles across every authentication event — verified explicitly through 
Conditional Access, least privilege through Privileged Identity Management, and assume breach 
through risk-based automated response.

This is not a tutorial follow-along. Every design decision has a documented rationale. Every 
control was validated to work before being switched to enforcement mode.

---

## Architecture
Every Sign-in Attempt
│
▼
┌─────────────────────────────────────────────────┐
│           CONDITIONAL ACCESS ENGINE             │
│                                                 │
│  Signal 1: Location (Named Locations)           │
│  Signal 2: User Risk (Identity Protection)      │
│  Signal 3: Sign-in Risk (Identity Protection)   │
│  Signal 4: Device Compliance                    │
│                                                 │
│  → Evaluate all 8 CA policies                  │
│  → Grant / Block / Step-up MFA / Force reset    │
└─────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────┐
│         PRIVILEGED IDENTITY MANAGEMENT          │
│                                                 │
│  Zero standing admin privileges                 │
│  JIT activation: MFA + Justification + Approval │
│  Max duration: 4 hours                          │
│  Auto-expires — no manual cleanup needed        │
└─────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────┐
│           IDENTITY PROTECTION                   │
│                                                 │
│  Continuously monitors every sign-in            │
│  Feeds risk signals back into CA policies       │
│  High user risk → block + force password reset  │
│  Medium sign-in risk → step-up MFA              │
└─────────────────────────────────────────────────┘

---

## Zero Trust Principle Mapping

| Control | Zero Trust Principle | What It Enforces |
|---------|---------------------|-----------------|
| CA-001: Baseline MFA | Verify Explicitly | Every untrusted location requires MFA |
| CA-002: Admin hardening | Verify Explicitly | Admins need MFA everywhere, no exceptions |
| CA-003: Country block | Verify Explicitly | 5 high-risk countries blocked outright |
| CA-004: User risk block | Assume Breach | High-risk accounts blocked automatically |
| CA-005: Sign-in risk MFA | Assume Breach | Suspicious sign-ins challenged immediately |
| CA-006: Service principal exclusion | Verify Explicitly | Automation excluded from interactive MFA |
| CA-007: Force password change | Assume Breach | Compromised credentials reset immediately |
| CA-008: Risk-based MFA | Assume Breach | Risky sign-ins require MFA + password change |
| PIM: JIT activation | Use Least Privilege | Zero standing admin access |
| Named Locations | Verify Explicitly | Trust boundaries explicitly defined |

---

## What Was Built

### Users and Groups

10 test users provisioned via Microsoft Graph PowerShell across 4 departments:

| Department | Users | Group |
|-----------|-------|-------|
| IT / Security | Halima Musa, Ife Adeleke, Jide Babatunde | sg-admins |
| Engineering | Ada Okonkwo, Bola Adeyemi, Chidi Nwosu | sg-engineers |
| Finance | Dami Oladele, Emeka Eze | sg-finance |
| HR / Sales | Fatima Aliyu, Gbenga Afolabi | sg-all-users |

All users assigned Microsoft Entra ID P2 licenses with Nigeria (NG) usage location.

---

### Named Locations — Trust Boundaries

| Name | Type | Trusted | Purpose |
|------|------|---------|---------|
| NL-TRUSTED-HomeOffice | IP range | ✅ Yes | Home/office IP — MFA excluded |
| NL-BLOCKED-HighRisk | Countries | ❌ No | CN, RU, KP, IR, SY — access blocked |
| NL-CORP-VPN | IP range | ✅ Yes | Corporate VPN range — MFA excluded |

---

### Conditional Access Policies — 8 Policies

| Policy | Scope | Condition | Action | Status |
|--------|-------|-----------|--------|--------|
| CA-001-Baseline-MFA-AllUsers | All users | Untrusted location | Require MFA | ✅ On |
| CA-002-Admins-MFA-CompliantDevice | sg-admins | Everywhere | MFA + compliant device | ✅ On |
| CA-003-Block-HighRisk-Countries | All users | NL-BLOCKED-HighRisk | Block | ✅ On |
| CA-004-Block-HighUserRisk | All users | User risk: High | Block | ✅ On |
| CA-005-MFA-MediumSigninRisk | All users | Sign-in risk: Medium+ | Require MFA | ✅ On |
| CA-006-Exclude-ServicePrincipals | Service accounts | All apps | Allow (no MFA) | ✅ On |
| CA-007-HighUserRisk-ForcePasswordChange | All users | User risk: High | Force password change | ✅ On |
| CA-008-MediumHighSigninRisk-RequireMFA | All users | Sign-in risk: Medium+ | MFA + password change | ✅ On |

All policies validated using the Conditional Access **What If** tool across 3 scenarios
before switching from Report-only to Enforcement mode.

> **Note:** CA-007 and CA-008 replace the deprecated standalone Identity Protection 
> risk policy blades, which Microsoft migrated into Conditional Access in 2025. 
> This reflects the current recommended Microsoft architecture.

---

### Privileged Identity Management

**Before PIM:** 3 users held permanent User Administrator access.  
**After PIM:** 0 users hold permanent admin access. All access is just-in-time.

| Role | Assigned Users | Type | Max Duration | Requires Approval | Requires MFA |
|------|---------------|------|-------------|------------------|-------------|
| User Administrator | Halima, Ife, Jide | Eligible (JIT) | 4 hours | ✅ Yes | ✅ Yes |
| Global Reader | Halima, Ife, Jide | Eligible (JIT) | 8 hours | ❌ No | ✅ Yes |

**JIT Activation Flow:**
User requests activation
│
▼
Provides written justification
│
▼
Completes MFA verification
│
▼
Approval request sent to admin
│
▼
Admin approves in PIM portal
│
▼
Access granted for 4 hours max
│
▼
Auto-expires — no manual cleanup

Activation tested end-to-end including the full approval workflow.

---

### Identity Protection

Risk policies implemented via Conditional Access (current Microsoft recommended approach):

| Risk Type | Threshold | Automated Response |
|-----------|-----------|-------------------|
| User Risk | High | Block access + force password change |
| Sign-in Risk | Medium and above | Require MFA + require password change |

---

## Validation Results

### What If Tool Test Results

| Scenario | Expected Result | Actual Result |
|----------|----------------|---------------|
| Sign-in from untrusted IP | CA-001 fires, MFA required | ✅ Passed |
| Sign-in from trusted home IP | CA-001 excluded, no MFA | ✅ Passed |
| Sign-in from blocked country | CA-003 fires, access blocked | ✅ Passed |

### Defender for Cloud Secure Score
Score: 56.67%

---

## Architecture Decision Records

### ADR-001: Risk Threshold Selection

**Decision:** High user risk → block + force password reset. Medium sign-in risk → MFA only.

**Rationale:**
- High user risk = probable credential compromise. MFA alone is insufficient because 
  an attacker with both the password AND the victim's phone (MFA fatigue / SIM swap) 
  can still complete MFA. Forcing a password reset invalidates the stolen credential itself.
- Medium sign-in risk = suspicious but not confirmed compromise. MFA step-up challenges 
  the actor without locking out a potentially legitimate user.
- Blocking at Medium risk creates too many false positives for a functioning organisation.

**Trade-off accepted:** Legitimate users with HIGH risk detections will be blocked until 
they reset their password — this will generate help desk calls but is the correct 
security posture trade-off.

---

### ADR-002: Break-Glass Admin Exclusion

**Decision:** Admin account `dave@tearinksoutlook.onmicrosoft.com` excluded from all 
risk-based Conditional Access policies.

**Rationale:** If a risk-based policy incorrectly triggers on the admin account, the 
entire tenant becomes inaccessible with no recovery path. A dedicated break-glass 
exclusion ensures administrative access is always recoverable. This account is monitored 
separately and its sign-ins are reviewed manually.

---

### ADR-003: Deprecated Identity Protection Policy Blades

**Decision:** Implemented risk policies via Conditional Access (CA-007, CA-008) rather 
than the legacy Identity Protection policy blades.

**Rationale:** Microsoft deprecated the standalone risk policy blades in Identity 
Protection in 2025, making them read-only. The current Microsoft-recommended approach 
consolidates all risk-based access controls into Conditional Access, providing a single 
policy enforcement point and consistent audit trail across all access decisions.

---

## Repository Structure
cloud-security-portfolio-01/
├── scripts/
│   └── provision-users.ps1          # Bulk user + group creation via Graph API
├── policies/
│   ├── CA-001-baseline-mfa.json     # Conditional Access policy exports
│   ├── CA-002-admins.json
│   ├── CA-003-block-countries.json
│   ├── CA-004-user-risk-block.json
│   ├── CA-005-signin-risk-mfa.json
│   ├── CA-006-service-principals.json
│   ├── CA-007-user-risk-password.json
│   └── CA-008-signin-risk-mfa.json
├── docs/
│   ├── ADR-001-risk-thresholds.md
│   ├── ADR-002-breakglass-exclusion.md
│   ├── ADR-003-deprecated-ip-blades.md
│   ├── zero-trust-mapping.md
│   └── tenant-ids.json
└── screenshots/
├── named-locations.png
├── conditional-access-final-list.png
├── what-if-results/
├── pim-activation.png
└── identity-protection.png


## CV Bullet Points

- **Architected Zero Trust identity platform** for a simulated organisation on Microsoft 
  Entra ID, eliminating all standing privileged admin accounts by converting 3 permanent 
  User Administrator assignments to PIM just-in-time eligible access requiring MFA 
  verification, written justification, and manager approval — reducing standing privilege 
  exposure to zero

- **Implemented 8 Conditional Access policies** enforcing risk-adaptive MFA, geographic 
  access controls blocking 5 high-risk country codes, device compliance requirements for 
  admin accounts, and automated response to compromised credentials — all validated with 
  the What If tool before enforcement

- **Configured risk-based automated response** using Identity Protection signals integrated 
  into Conditional Access: high user risk triggers account block and forced password reset; 
  medium sign-in risk triggers MFA step-up — implementing the current Microsoft-recommended 
  approach following the 2025 deprecation of standalone Identity Protection policy blades

---

## Links

- **GitHub Repository:** https://github.com/Adeoluwa12/cloud-security-portfolio-01
- **Full Portfolio:** https://github.com/Adeoluwa12

---

*Built by Oluwaferanmi Adeoye — Senior Cloud Security Engineer/DevSecOps Engineer*  
