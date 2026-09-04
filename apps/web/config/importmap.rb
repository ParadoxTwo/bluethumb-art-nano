# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Vue 3, vendored into vendor/javascript (no build step, no CDN at runtime).
# Islands use render functions so the runtime-only build would suffice; the full
# browser build is pinned for now in case a second island wants template strings.
pin "vue", to: "vue.esm-browser.prod.js"
pin "islands", to: "islands/index.js"
pin "islands/colour_picker", to: "islands/colour_picker.js"
