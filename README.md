Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Tests

Use `bin/test` for local test runs. It sets `DISABLE_SPRING=1` automatically to avoid hangs from stale Spring processes.

## Sidekiq

The app uses Sidekiq for background jobs in development and production.

1. Start Redis locally (example with Homebrew): `brew services start redis`
2. Run Rails + Sidekiq together: `bin/dev`
3. Alternative: run Rails in one terminal (`bin/rails server`) and Sidekiq in another (`bundle exec sidekiq -C config/sidekiq.yml`)
4. In development, Sidekiq Web is available at `/sidekiq` for signed-in users.

## Deferred Security Follow-up

One dependency advisory is intentionally deferred for a later PR:

- `webrick` via `rackup 1.x` in the current Rails 7.2 / Rack 2 dependency line.

Current status:

- `yarn audit` is clean.
- `nokogiri` has been upgraded to a patched release.
- `bundler-audit` still reports `webrick` because `rackup 1.x` depends on it.

Follow-up plan and acceptance criteria are documented in `docs/webrick-rack3-followup.md`.
