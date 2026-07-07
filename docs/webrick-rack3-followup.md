# Webrick Advisory Follow-up (Deferred)

## Why This Is Deferred

`bundler-audit` currently reports `webrick` (`CVE-2026-38969`) from a transitive path:

- `railties` -> `rackup 1.0.1` -> `webrick`

In the current dependency stack, `rackup 2.x` is not directly available because it requires `rack >= 3`, while this app is on Rails 7.2 with Rack 2.

## Target Follow-up PR Scope

1. Evaluate and execute framework upgrade path that allows `rack >= 3`.
2. Move from `rackup 1.x` to `rackup 2.x` (or a Rails version that removes this path).
3. Remove `webrick` from the resolved dependency graph.
4. Preserve current app behavior (auth, background jobs, webpack/shakapacker build, tests).

## Acceptance Criteria

- `bundler-audit check --update` reports no `webrick` advisory.
- `bundle exec rails runner 'puts "boot-ok"'` passes.
- `bin/test` passes.
- `yarn audit --level moderate` remains clean.
- `brakeman -q` has no new app-code security warnings.

## Suggested PR Title

`chore(security): remove transitive webrick advisory by upgrading Rack/Rails dependency line`

## Suggested PR Checklist

- [ ] Confirm upgrade compatibility matrix for Rails/Rack/rackup.
- [ ] Apply Gemfile/Gemfile.lock upgrades.
- [ ] Run full validation suite.
- [ ] Add migration notes for deployment/runtime changes.
