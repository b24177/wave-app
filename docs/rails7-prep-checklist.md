# Rails 7 Prep Checklist

This document captures the current baseline before attempting a Rails 7 upgrade.

## Current baseline

- Rails framework gems: 6.1.7.10
- Ruby: 3.1.7
- App defaults: 6.1 with compatibility overrides
- Asset pipeline: Shakapacker 6.6.0

## Dependency findings

From `bundle outdated` on this branch:

- `rails` is pinned at `~> 6.1.7`
- `puma` is pinned at `~> 4.1` (very old for Rails 7 era)
- `shakapacker` is pinned at `~> 6.6`
- `devise` has newer major (`5.x`) available, but Rails 7 can still work on recent `4.9.x`
- `pg` is pinned at `~> 1.4.6` for warning cleanup; Rails 7 should still support this range

## Recommended sequence

1. Upgrade Rails from `~> 6.1.7` to `~> 7.0.8` first (not 7.1+ yet).
2. Upgrade Puma to a modern series compatible with Rails 7 (`~> 5.6` or `~> 6.x`).
3. Keep Devise on `4.9.x` unless Rails 7 bundle resolution forces change.
4. Run `rails app:update` and review generated diffs manually.
5. Resolve framework default changes incrementally in config.
6. Re-run smoke checks for:
   - `/`
   - `/users/sign_in`
   - `/users/sign_up`
   - `/users/password/new`
   - POST `/users/auth/spotify`

## Validation commands

- `bundle _2.4.22_ exec rails runner 'puts "boot-ok"'`
- `bundle _2.4.22_ exec rails zeitwerk:check`
- `bundle _2.4.22_ exec rails test`
- Route smoke checks via curl

## Stop conditions

Pause and checkpoint if any of the following happen:

- Boot fails before initialization completes
- OmniAuth route behavior changes regress POST initiation
- Shakapacker compilation fails and blocks page rendering
