# Bluethumb Art Nano

A small art marketplace built with Ruby on Rails and Hanami. Procedurally generated artwork, server-rendered discovery, and palette-based search.

Not affiliated with [Bluethumb](https://bluethumb.com.au). All catalogue data and images are synthetic.

## Stack

| Layer            | Technology                                |
| ---------------- | ----------------------------------------- |
| Runtime          | Ruby 3.4                                  |
| Web app          | Rails 8                                   |
| Services         | Hanami 2                                  |
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
- Hanami `/colour/extract` — procedural extraction from ActiveStorage images
- `bin/rails palettes:extract` — batch extraction via palette service
- Colour picker island stub on artwork detail (wires to palette proxy)

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

Home → Style quiz **or** Browse → Artwork detail → Similar by colour → Cart → Checkout → Thank you

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

## Architecture

Monorepo with two Ruby apps:

```
apps/web/              Rails 8 — marketplace UI, cart, faceted browse, checkout
apps/palette/          Hanami 2 — palette extraction and colour search API
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
