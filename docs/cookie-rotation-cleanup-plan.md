# Cookie Rotation Cleanup Plan

Target removal date: 2026-07-19

Scope:
- Remove config/initializers/cookie_key_rotation_compat.rb after migration safety window.

Verification before removal:
- No recent user reports of unexpected logouts tied to the SHA256 key-generator rollout.
- Sign in, sign out, and authenticated navigation smoke-check passes in production.
- No cookie/message decrypt errors observed in logs.

Removal steps:
- Delete config/initializers/cookie_key_rotation_compat.rb
- Run boot check, Zeitwerk check, and test suite.
- Deploy during normal release window.
