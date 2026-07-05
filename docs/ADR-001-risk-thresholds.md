# ADR-001: Identity Protection Risk Threshold Decision

## Status
Accepted

## Context
We needed to decide at which risk level to block access vs. step-up with MFA.

## Decision
- HIGH user risk: Block until password change (not just MFA)
  - Rationale: High risk = probable compromise. MFA alone doesn't help if 
    the attacker also has the victim's phone (MFA fatigue / SIM swap)
  - Forcing a password change resets the credential material itself
  
- MEDIUM+ sign-in risk: Require MFA only
  - Rationale: Medium risk = suspicious but not confirmed compromise
  - MFA step-up challenges the actor without locking out a potentially 
    legitimate user

## Trade-offs Considered
- Blocking at MEDIUM risk: too many false positives for a working org
- MFA only at HIGH risk: insufficient if attacker has both password and phone
- No automation: requires analyst review per incident (not scalable)

## Consequences
Legitimate users with HIGH risk detections will be blocked until 
password reset — expect help desk calls. Accept this trade-off for 
security posture improvement.