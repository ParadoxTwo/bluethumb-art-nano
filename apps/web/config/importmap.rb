# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Vue 3, vendored into vendor/javascript (no build step, no CDN at runtime).
# This is the full browser build: it carries the template compiler, which is
# what lets islands be plain .js modules with template strings instead of
# single-file components. A bundler earns its place when a second island does.
pin "vue", to: "vue.esm-browser.prod.js"
pin "islands", to: "islands/index.js"
pin "islands/colour_picker", to: "islands/colour_picker.js"
