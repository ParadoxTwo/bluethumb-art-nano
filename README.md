# Bluethumb Art Nano

A small art marketplace built with Ruby on Rails and Hanami. Procedurally generated artwork, server-rendered discovery, and palette-based search.

Not affiliated with [Bluethumb](https://bluethumb.com.au). All catalogue data and images are synthetic.

## Stack

| Layer            | Technology                                |
| ---------------- | ----------------------------------------- |
| Runtime          | Ruby 3.4                                  |
| Web app          | Rails 8                                   |
| Services         | Hanami 3                                  |
| Validation / DI  | dry-rb (dry-validation, dry-monads)       |
| Database         | PostgreSQL                                |
| Templates        | Slim                                      |
| Styles           | Tailwind CSS                              |
| Interactivity    | Vue 3 islands, Hotwire (Turbo + Stimulus) |
| Tests            | RSpec                                     |
| Image processing | libvips (`ruby-vips`) — optional          |

## Features

### Marketplace (Phase 2)

- **Home page** — hero, prominent style-quiz CTA, staff picks grid, shop-by-style tiles
- **Faceted browse** — composable URL filters: medium, style, price, size, orientation, colour, sort
- **SSR listings** — artwork tiles, result count, sort links, and pagination in initial HTML
- **Full-text search** — `pg_search` on title, description, and artist name (`?q=` or `/q/term` facet)
- **Style quiz** — 3-step guided discovery at `/discover` → composed facet URL
- **Artwork detail** — gallery thumbnails, breadcrumbs, trust badges, delivery estimate, framing selector (+$250 stub)
- **Cart & checkout** — line items, subtotal, remove items, single-page checkout stub, thank-you page (no payment)
- **Favourites** — session-scoped save/unsave on artwork detail
- **Login stub** — placeholder at `/login`

### Colour (Phase 1+)

- Palette data seeded per artwork (`palette_data` jsonb + CIELAB centroid)
- Hanami `/colour/similar/:id` — nearest-neighbour ranking by CIELAB distance
- Hanami `/colour/extract` — libvips histogram quantization (MMCQ-style) with procedural fallback
- Hanami `/colour/match-room` — room photo upload → palette extract → ranked artworks
- `bin/rails palettes:extract` — batch extraction via palette service
- Colour picker island on artwork detail (wires to palette proxy)
- Match my room page + Vue island at `/match-room`

## Requirements

- Ruby 3.4
- PostgreSQL 14+
- libvips (optional — seeds include procedural palette data without it)

## Setup

```bash
cp .env.example .env   # set DATABASE_URL for your PostgreSQL
bin/setup              # bundle, db:prepare, seed
bin/test               # RSpec in apps/web and apps/palette
bin/dev                # Rails :3000 + Hanami :9292 + Tailwind watch
```

Visit `http://localhost:3000` — home page and browse at `/artworks` render in HTML without JavaScript.

## Demo path (~3 min)

Home → Style quiz **or** Match my room **or** Browse → Artwork detail → Similar by colour → Cart → Checkout → Thank you

## Testing

`bin/test` is the canonical quality gate. It swaps `DATABASE_URL` to the test database when `.env` is present, prepares the test schema, and runs RSpec in both apps including Capybara system specs.

```bash
bin/test    # web + palette specs; must pass before merge
```

## Development

```bash
bin/rails db:seed
bin/rails artworks:regenerate ARTWORK_COUNT=200
bin/rails palettes:extract
bin/palette routes
```

See [AGENTS.md](./AGENTS.md) for architecture boundaries and agent workflow.

## Deploying to Render

`render.yaml` is a Blueprint for two free web services sharing one free Postgres: `bluethumb-nano` (Rails) and `bluethumb-nano-palette` (Hanami). In the Render dashboard choose **New → Blueprint**, point it at this repository, and supply `RAILS_MASTER_KEY` (the contents of `apps/web/config/master.key`) when prompted.

What the free tier dictates, and how the Blueprint answers it:

- **Ephemeral disk.** Free instances lose their filesystem on every deploy, restart and spin-down, so `apps/web/bin/render-build` regenerates the procedural catalogue during the build; the images ship inside the deploy image. Catalogue size is `SEED_ARTWORK_COUNT` (default 150).
- **Cold starts.** Free services spin down after 15 idle minutes and take about a minute to wake. `PaletteClient` uses short timeouts so an artwork page degrades to its server-rendered content immediately rather than hanging while the palette service wakes; the colour island recovers on the next tap. Open the site a few minutes before showing it.
- **No private network for free services.** Rails calls the palette service over its public HTTPS address (`PALETTE_SERVICE_URL`). If Render had to suffix the palette service's name, update that variable after the first deploy.
- **No shared disk.** `POST /colour/extract` can either name an artwork (and read the file itself) or take the image bytes as a multipart upload. On Render the services have separate filesystems, so the build waits for the palette service and then runs `PALETTE_EXTRACT_UPLOAD=1 bin/rails palettes:extract`, which sends each image. If the service never answers the deploy still succeeds, with the generator's single-colour palettes.
- **Free Postgres expires 30 days after creation** (14-day grace, then deleted). Recreate or upgrade it if the demo needs to outlive that.

## Architecture

Monorepo with two Ruby apps:

```
apps/web/              Rails 8 — marketplace UI, cart, faceted browse, checkout
apps/palette/          Hanami 3 — palette extraction and colour search API
```

Rails owns HTML, sessions, and catalogue persistence. Hanami owns the colour domain: extracting palettes, computing CIELAB similarity, and serving JSON endpoints consumed by the Rails app and Vue islands.

## Seed data

Artists and artworks are generated programmatically — gradient meshes, noise fields, and geometric compositions — so the catalogue is reproducible and free of third-party copyright. Default seed target: **200 artworks** with palette data and staff picks.

```bash
bin/rails artworks:regenerate ARTWORK_COUNT=200
bin/rails palettes:extract
```

## License

MIT
