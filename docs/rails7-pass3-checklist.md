# Rails 7 Defaults Pass 3 Checklist

This checklist assumes pass 1 and pass 2 are already merged.

## Branch setup

1. Create a new branch from latest master.
2. Toggle one default at a time.
3. Run validation after each toggle.
4. Commit each toggle separately.

Suggested commands:

- git checkout master
- git pull origin master
- git checkout -b rails7-defaults-pass3

## Validation commands after each toggle

- DISABLE_SPRING=1 bundle _2.4.22_ exec rails runner 'puts "boot-ok"'
- DISABLE_SPRING=1 bundle _2.4.22_ exec rails zeitwerk:check
- DISABLE_SPRING=1 bundle _2.4.22_ exec rails test
- DISABLE_SPRING=1 bundle _2.4.22_ exec rails test test/integration/smoke_routes_test.rb -v

Optional quick endpoint check:

- curl -I --max-time 5 http://127.0.0.1:3000/
- curl -I --max-time 5 http://127.0.0.1:3000/users/sign_in
- curl -I --max-time 5 http://127.0.0.1:3000/users/sign_up
- curl -I --max-time 5 http://127.0.0.1:3000/users/password/new

## Toggle order: low risk to higher risk

Edit: config/initializers/new_framework_defaults_7_0.rb

### Group A: low risk

1. active_support.remove_deprecated_time_with_zone_name = true
2. active_support.executor_around_test_case = true
3. active_record.verify_foreign_keys_for_fixtures = true
4. action_controller.wrap_parameters_by_default = true
5. active_support.use_rfc4122_namespaced_uuids = true
6. action_dispatch.return_only_request_media_type_on_content_type = false

Expected impact:

- Mostly internal behavior alignment and test/runtime consistency.
- Low user-facing UI impact.

### Group B: medium risk

1. active_record.partial_inserts = false
2. action_dispatch.default_headers = { ... Rails 7 defaults ... }
3. active_storage.multiple_file_field_include_hidden = true

Expected impact:

- SQL insert shape changes.
- Security header baseline changes.
- File attachment form behavior changes for multiple uploads.

### Group C: high risk, sequence carefully

1. active_storage.variant_processor = :vips
2. action_dispatch.cookies_serializer = :hybrid (or :json only after verification)
3. active_support.hash_digest_class = OpenSSL::Digest::SHA256
4. active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA256

Expected impact:

- Requires ruby-vips/image processing compatibility for variants.
- Cookie compatibility and session continuity concerns.
- Cache and message digest changes can invalidate existing data and signed/encrypted artifacts.

## Application-level toggles (not in initializer)

Edit: config/application.rb

1. config.active_support.cache_format_version = 7.0
2. config.active_support.disable_to_s_conversion = true

When to apply:

- Apply only after full deployment confidence on Rails 7.
- Treat as final-stage changes with rollback plan.

## Commit strategy

- One commit per toggle, for example:
  - Enable remove_deprecated_time_with_zone_name
  - Enable partial_inserts false
  - Enable default security headers
- Push after each stable group.

## Stop conditions

Stop and revert the last toggle if any of these happen:

1. Boot fails or Zeitwerk fails.
2. Smoke routes fail.
3. Auth session/cookies regress.
4. Active Storage upload or variant rendering regresses.

## Recommended first pass 3 action

Start with Group A item 1 only:

- Rails.application.config.active_support.remove_deprecated_time_with_zone_name = true

Run validation, commit, then continue.
