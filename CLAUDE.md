# CLAUDE.md — Bluethumb Art Nano

Entry point for Claude sessions. Canonical agent instructions live in **[AGENTS.md](./AGENTS.md)** — read that first. Deeper context: `tmp/PROJECT_CONTEXT.md` (gitignored — ask the user if missing); current state in `tmp/PHASE2_HANDOFF.md` and `tmp/FEATURE_AUDIT.md`.

## Quick facts

- Monorepo: `apps/web` (Rails 8 — Slim, Tailwind, Hotwire, Vue 3 islands) + `apps/palette` (Hanami 2 — dry-rb). One PostgreSQL database; Rails owns catalogue migrations; colour logic lives **only** in Hanami; `artworks.palette_data` jsonb is the shared surface.
- `bin/test` is the quality gate (RSpec in both apps, swaps DATABASE_URL to the test DB) — run it before calling anything done. `bin/dev` runs Rails :3000 + Hanami :9292 + Tailwind watch.
- SSR is the point: the first page of `/artworks` renders tiles, result count, facets and pagination in HTML with no JS required. Facet state lives in composable URL path segments (`/artworks/style/abstract/price/500-1000`) — the URL is the source of truth.

## Conventions (mirrored from `.cursor/rules/` — keep the two in sync)

| Scope | Rule file |
| --- | --- |
| Always on: phases, constraints, commit style | `.cursor/rules/project-core.mdc` |
| Always on: Rails vs Hanami ownership | `.cursor/rules/monorepo-boundaries.mdc` |
| `apps/web/**` | `.cursor/rules/rails-web.mdc` |
| `apps/palette/**` | `.cursor/rules/hanami-palette.mdc` |
| `apps/web/app/javascript/**` | `.cursor/rules/frontend-vue.mdc` |
| `**/*_spec.rb` | `.cursor/rules/rspec-testing.mdc` |
| seeds & lib/tasks | `.cursor/rules/seed-data.mdc` |

Claude does not auto-apply `.mdc` globs — read the matching rule file before editing files in its scope.

## Non-negotiables

- Synthetic/procedural artwork and artists only — never scrape bluethumb.com.au, never use real artists' names or works.
- Committed files stay engineering-only; internal notes live in `tmp/` (gitignored).
- Specs accompany every new service, action, and non-trivial model change; keep `bin/test` green at every step.
- Stay in the active phase — no payments, OAuth, messaging, or Elasticsearch unless asked.
- Small, logical commits; the message explains *why*.

## Known gotchas

- Hanami action instances are frozen — do not memoize with `@ivar` inside actions.
- Slim rejects bracketed Tailwind utilities in dot-chains (`.lg:max-h-[...]`) — use `class="..."` attribute syntax.
- `pg_search` is in `apps/web/Gemfile` — `bundle install` if gems are stale.
- Palette extraction reads ActiveStorage from `apps/web/storage` over the shared database; expect 404s when an artwork or image is missing.
