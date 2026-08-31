# Agent instructions — Bluethumb Art Nano

Read this before making changes. Public README is engineering-only; deeper context lives in `tmp/PROJECT_CONTEXT.md` (gitignored, ask the user if missing).

## Project

Monorepo art marketplace demo: **Rails 8** (`apps/web`) + **Hanami 2** (`apps/palette`). Synthetic catalogue only. Specs required from the first commit.

## Before coding

1. Read `README.md` for stack and architecture.
2. Read `tmp/PROJECT_CONTEXT.md` for phase checklist, scope, and constraints.
3. Confirm which phase (0 = marketplace shell, 1 = colour search) the task belongs to.
4. Do not expand scope into payments, messaging, OAuth, or Elasticsearch unless asked.

## App boundaries

| App            | Owns                                                                      |
| -------------- | ------------------------------------------------------------------------- |
| `apps/web`     | HTML, sessions, cart, catalogue models, Slim views, Hotwire, Vue islands  |
| `apps/palette` | Palette extraction, CIELAB similarity, colour JSON API, dry-rb validation |

Rails persists catalogue data. Hanami reads/writes `palette_data` and serves colour endpoints. No business logic duplicated across both apps.

## Non-negotiables

- **Server-render** the first page of `/artworks` (tiles, count, facets, pagination in HTML).
- **Composable facet URLs** — `/artworks/style/abstract/price/500-1000`, URL is source of truth.
- **Procedural images only** — never scrape Bluethumb or use real artists' work.
- **RSpec** for every new service, action, and non-trivial model logic.
- **Public docs stay professional** — no interview, recruiter, or job-search content in committed files.

## Commands (once scaffolded)

```bash
bundle install
bin/rails db:setup    # from apps/web
bin/rails db:seed
bin/dev               # Rails + Hanami + assets
bundle exec rspec     # both apps
```

## Cursor rules

Detailed conventions live in `.cursor/rules/` — file-specific rules apply automatically when editing matching paths.
