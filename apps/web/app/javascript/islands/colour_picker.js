// ColourPicker island — pick a colour out of this artwork's palette and see
// what else in the catalogue sits near it perceptually.
//
// Progressive enhancement: the server already rendered "More like this, by
// colour" above this island. This adds the interactive cut, and its absence
// costs the page nothing.
//
// Uses a render function (not an inline template string) so Vue does not need
// the runtime compiler — which would require CSP 'unsafe-eval'.
import { computed, h, ref } from "vue"

export default {
  name: "ColourPicker",

  props: {
    swatches: { type: Array, default: () => [] },
    endpoint: { type: String, required: true }
  },

  setup(props) {
    const activeHex = ref(null)
    const results = ref([])
    const status = ref("idle") // idle | loading | ready | empty | error
    const errorMessage = ref("")

    // Monotonic token: a slow first request must never overwrite the results
    // of a faster second one.
    let latestRequest = 0

    const prompt = computed(() =>
      activeHex.value
        ? "Artworks closest to " + activeHex.value + " across the catalogue."
        : "Tap a colour from this work to find others like it."
    )

    function reset() {
      latestRequest += 1
      activeHex.value = null
      results.value = []
      errorMessage.value = ""
      status.value = "idle"
    }

    async function select(hex) {
      if (activeHex.value === hex) return reset()

      const request = ++latestRequest
      activeHex.value = hex
      errorMessage.value = ""
      status.value = "loading"

      try {
        const url = props.endpoint + "?hex=" + encodeURIComponent(hex)
        const response = await fetch(url, { headers: { Accept: "application/json" } })
        if (request !== latestRequest) return

        if (!response.ok) {
          const body = await response.json().catch(() => ({}))
          throw new Error((body.error && body.error.message) || "Colour search is unavailable right now.")
        }

        const payload = await response.json()
        if (request !== latestRequest) return

        results.value = payload.artworks || []
        status.value = results.value.length ? "ready" : "empty"
      } catch (error) {
        if (request !== latestRequest) return
        errorMessage.value = error.message
        status.value = "error"
      }
    }

    function swatchButtons() {
      return props.swatches.map((swatch) =>
        h("button", {
          key: swatch.hex,
          type: "button",
          class: [
            "h-11 w-11 rounded-full border border-stone-300 transition-transform hover:scale-105 focus:outline-none focus-visible:ring-2 focus-visible:ring-stone-900 focus-visible:ring-offset-2",
            activeHex.value === swatch.hex ? "ring-2 ring-stone-900 ring-offset-2" : ""
          ],
          style: { backgroundColor: swatch.hex },
          "aria-pressed": activeHex.value === swatch.hex,
          "aria-label": "Find artworks close to " + swatch.hex,
          onClick: () => select(swatch.hex)
        })
      )
    }

    function loadingSkeleton() {
      return h("div", { class: "mt-6 grid grid-cols-2 gap-4 md:grid-cols-3", "aria-hidden": "true" },
        [1, 2, 3].map((n) =>
          h("div", { key: n, class: "card overflow-hidden" }, [
            h("div", { class: "aspect-[4/5] animate-pulse bg-stone-200" }),
            h("div", { class: "space-y-2 p-3" }, [
              h("div", { class: "h-3 w-3/4 animate-pulse rounded bg-stone-200" }),
              h("div", { class: "h-3 w-1/2 animate-pulse rounded bg-stone-200" })
            ])
          ])
        )
      )
    }

    function resultGrid() {
      return h("div", { class: "mt-6 grid grid-cols-2 gap-4 md:grid-cols-3" },
        results.value.map((artwork) =>
          h("a", {
            key: artwork.id,
            href: artwork.url,
            class: "card group overflow-hidden transition-shadow hover:shadow-lg"
          }, [
            h("div", { class: "aspect-[4/5] overflow-hidden bg-stone-200" },
              artwork.image_url
                ? h("img", {
                    src: artwork.image_url,
                    alt: artwork.title,
                    loading: "lazy",
                    class: "h-full w-full object-cover transition-transform group-hover:scale-105"
                  })
                : null
            ),
            h("div", { class: "p-3" }, [
              h("p", { class: "truncate text-sm font-medium text-stone-900" }, artwork.title),
              h("p", { class: "meta-text truncate" }, artwork.artist),
              h("p", { class: "mt-1 text-sm font-semibold text-stone-900" }, artwork.price)
            ])
          ])
        )
      )
    }

    function statusPanel() {
      if (status.value === "loading") return loadingSkeleton()
      if (status.value === "empty") {
        return h("p", { class: "card mt-6 p-4 text-sm text-stone-600" },
          "Nothing else in the catalogue sits near that colour yet.")
      }
      if (status.value === "error") {
        return h("p", { class: "card mt-6 p-4 text-sm text-stone-600", role: "status" }, errorMessage.value)
      }
      if (status.value === "ready") {
        return [
          resultGrid(),
          h("p", { class: "meta-text mt-3" }, "Ranked by CIELAB distance, closest first.")
        ]
      }
      return null
    }

    return () =>
      h("section", { class: "mt-16" }, [
        h("div", { class: "flex flex-wrap items-baseline justify-between gap-3" }, [
          h("h2", { class: "text-xl font-semibold" }, "Explore by colour"),
          activeHex.value
            ? h("button", {
                type: "button",
                class: "text-sm text-stone-600 underline hover:text-stone-900",
                onClick: reset
              }, "Clear")
            : null
        ]),
        h("p", { class: "meta-text mt-1" }, prompt.value),
        h("div", {
          class: "mt-4 flex flex-wrap gap-3",
          role: "group",
          "aria-label": "Colours in this artwork"
        }, swatchButtons()),
        statusPanel()
      ])
  }
}
