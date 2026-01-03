# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project basics
- Framework: Ruby on Rails 7.2 with Postgres, Propshaft, Turbo/Stimulus frontend, Tailwind CSS via cssbundling-rails, esbuild+TypeScript via jsbundling-rails.
- Background/cron: good_job is present for async jobs (see config/initializers, jobs under app/jobs if added).
- Authentication/identity: email/password flows under `app/controllers/identity/*`, OmniAuth providers under `app/controllers/sessions/omniauth_controller.rb`, session handling in `app/controllers/sessions_controller.rb` and `app/models/session.rb`.
- Admin back office: controllers under `app/controllers/admin/*`, views in `app/views/admin/*`; default superuser admin/admin, login at `/admin` (see README).
- Public/API: API endpoints under `app/controllers/api/v1/*`; web-facing flows (registrations, passwords, invitations) under `app/controllers/*` plus concerns for Turbo rendering and friendly errors.
- Domain models: flights/bookings/passengers (`app/models/flight*.rb`, `booking.rb`, `passenger.rb`), hotels (`hotel*.rb`, `hotel_booking.rb`), travel content (`destination.rb`, `deep_travel_*`, `tour_product.rb`), memberships/notifications.
- Frontend assets: TypeScript entrypoints in `app/javascript/*.ts` bundled to `app/assets/builds`; Tailwind styles in `app/assets/stylesheets/*.css`; images under `app/assets/images/`.

## Setup & environment
- Install system deps: Postgres, Ruby 3.x with Rails 7, Node/npm.
- App setup (deps, DB, seeds):
  ```bash
  ./bin/setup
  ```
- Local development server (runs Rails + asset watchers via Procfile.dev):
  ```bash
  bin/dev
  ```
- Alternate manual start: `bin/rails server` plus `npm run watch:css` and `npm run watch:js`.

## Package/asset commands
- Build assets (runs lint + JS bundle): `npm run build`
- JS only: `npm run build:js` (prod minified: `npm run build:js:prod`)
- CSS only: `npm run build:css` (app/admin targets); watch in dev: `npm run watch:css`
- JS watch: `npm run watch:js`

## Linting & type checks
- Full lint (ESLint + TS noEmit): `npm run lint`
- ESLint only: `npm run lint:eslint`
- TS types only: `npm run lint:types` or `npm run type-check`
- Auto-fix lint: `npm run lint:fix`

## Tests
- RSpec suite: `bundle exec rspec`
- Single file: `bundle exec rspec spec/validators/flight_booking_task_validator.rb`
- Rails tasks also available via `bundle exec rake spec` if needed.

## Domain-specific validation tool
- CLI validation for flight booking tasks lives in `lib/tasks/vision_validate.rake` with validator at `spec/validators/flight_booking_task_validator.rb`.
- Common commands:
  ```bash
  bundle exec rake vision:help
  bundle exec rake vision:validate departure_city=深圳 arrival_city=武汉 departure_date=2025-01-15
  ```
- Refer to `VISION_VALIDATION.md` and docs/CLI_VALIDATION_GUIDE.md for parameter options (passenger_name, contact_phone, insurance flags, should_complete_payment, etc.).

## Key docs to consult
- Root README.md: installation prerequisites, admin defaults, tech stack, quick start (`./bin/setup`, `bin/dev`).
- IMPLEMENTATION_SUMMARY.md: overview of the vision validation tool, file map, and usage examples.
- docs/PROJECT_STRUCTURE.md: curated map of docs and core files.
- docs/CLI_VALIDATION_GUIDE.md, docs/README.md, VISION_VALIDATION.md: detailed guidance on the validation workflow and task definitions.

## Architectural map
- Controllers:
  - `app/controllers/admin/*`: admin dashboard CRUD for users, bookings, flights, etc.
  - `app/controllers/api/v1/*`: JSON auth/profile endpoints; API base at `app/controllers/api/base_controller.rb`.
  - `app/controllers/identity/*`: email/password lifecycle (verification, reset, update) using Devise-like flows without Devise.
  - General web controllers (registrations, sessions, invitations) plus concerns for Turbo rendering (`turbo_compatible_render_concern.rb`), friendly errors, and CSRF dev bypass.
- Models: core booking/flight/hotel/membership/notification entities under `app/models` with standard ActiveRecord relations; `Current` used for per-request context.
- Views: HTML/Turbo in `app/views`; admin views under `app/views/admin`; mailers in `app/views/*mailer*` (if present).
- Assets: Tailwind CSS and TypeScript/Stimulus entrypoints compiled by esbuild into Propshaft pipeline (`app/assets/builds`).
- Background jobs: good_job configured (check `config/initializers/good_job.rb` if modifying queues/crons).

## Notes for Claude
- Prefer using `bundle exec` for Ruby tasks to match locked gem versions.
- When touching validation tooling, mirror docs in `VISION_VALIDATION.md` and `docs/*GUIDE*.md` to keep CLI examples consistent.
- Keep admin defaults (admin/admin) only in dev context; avoid altering without coordination.
