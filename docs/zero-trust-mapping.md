# Zero Trust Principle Mapping

## Verify Explicitly
Every sign-in is evaluated against:
- User identity (Entra ID authentication)
- MFA (Conditional Access CA-001, CA-002, CA-005)
- Location (Named locations: trusted vs blocked vs unknown)
- Sign-in risk (Identity Protection signals → CA-005)
- Device compliance (CA-002 for admins)

## Use Least Privilege
- No user has permanent admin access (PIM eligible assignments)
- Admin access is granted only when needed, for limited duration
- Each role has minimum necessary permissions (User Admin ≠ Global Admin)
- JIT access requires justification, MFA, and manager approval

## Assume Breach
- High user risk triggers automatic account block (assume credential stolen)
- Sign-in risk triggers MFA step-up (assume session may be hijacked)
- High-risk country access is blocked (assume network may be hostile)
- Identity Protection continuously monitors for indicators of compromise