// RoomMatch island — upload a room photo, get artworks ranked by colour harmony.
//
// Progressive enhancement: the server page already explains the feature and
// links to colour browse. This island is the interactive cut only.
import { h, ref } from "vue"

export default {
  name: "RoomMatch",

  props: {
    endpoint: { type: String, required: true }
  },

  setup(props) {
    const status = ref("idle") // idle | loading | ready | empty | error
    const errorMessage = ref("")
    const results = ref([])
    const swatches = ref([])
    const fileName = ref("")
    let latestRequest = 0

    function csrfToken() {
      const meta = document.querySelector('meta[name="csrf-token"]')
      return meta ? meta.getAttribute("content") : ""
    }

    function reset() {
      latestRequest += 1
      status.value = "idle"
      errorMessage.value = ""
      results.value = []
      swatches.value = []
      fileName.value = ""
    }

    async function onFileChange(event) {
      const file = event.target.files && event.target.files[0]
      if (!file) return

      const request = ++latestRequest
      fileName.value = file.name
      errorMessage.value = ""
      status.value = "loading"
      results.value = []
      swatches.value = []

      const body = new FormData()
      body.append("image", file)

      try {
        const response = await fetch(props.endpoint, {
          method: "POST",
          headers: {
            Accept: "application/json",
            "X-CSRF-Token": csrfToken()
          },
          body,
          credentials: "same-origin"
        })
        if (request !== latestRequest) return

        const payload = await response.json().catch(() => ({}))
        if (!response.ok) {
          throw new Error((payload.error && payload.error.message) || "Room match is unavailable right now.")
        }

        results.value = payload.artworks || []
        swatches.value = (payload.palette && payload.palette.swatches) || []
        status.value = results.value.length ? "ready" : "empty"
      } catch (error) {
        if (request !== latestRequest) return
        errorMessage.value = error.message
        status.value = "error"
      } finally {
        event.target.value = ""
      }
    }

    function swatchRow() {
      if (!swatches.value.length) return null
      return h("div", { class: "mt-6" }, [
        h("p", { class: "meta-text" }, "Palette from your photo"),
        h("div", {
          class: "mt-3 flex flex-wrap gap-3",
          role: "list",
          "aria-label": "Extracted room colours"
        }, swatches.value.map((swatch) =>
          h("span", {
            key: swatch.hex,
            role: "listitem",
            class: "h-10 w-10 rounded-full border border-stone-300",
            style: { backgroundColor: swatch.hex },
            title: swatch.hex
          })
        ))
      ])
    }

    function loadingSkeleton() {
      return h("div", { class: "mt-8 grid grid-cols-2 gap-4 md:grid-cols-3", "aria-hidden": "true" },
        [1, 2, 3, 4, 5, 6].map((n) =>
          h("div", { key: n, class: "overflow-hidden rounded-lg border border-stone-200" }, [
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
      return h("div", { class: "mt-8 grid grid-cols-2 gap-4 md:grid-cols-3" },
        results.value.map((artwork) =>
          h("a", {
            key: artwork.id,
            href: artwork.url,
            class: "group overflow-hidden rounded-lg border border-stone-200 transition-shadow hover:shadow-lg"
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
        return h("p", { class: "mt-8 rounded-lg border border-stone-200 bg-white p-4 text-sm text-stone-600" },
          "No artworks with palette data sit near that room colour yet.")
      }
      if (status.value === "error") {
        return h("p", { class: "mt-8 rounded-lg border border-stone-200 bg-white p-4 text-sm text-stone-600", role: "status" }, errorMessage.value)
      }
      if (status.value === "ready") {
        return [
          swatchRow(),
          resultGrid(),
          h("p", { class: "meta-text mt-3" }, "Ranked by CIELAB distance to the room palette centroid.")
        ]
      }
      return null
    }

    return () =>
      h("section", { class: "mt-2" }, [
        h("div", { class: "flex flex-wrap items-center gap-4" }, [
          h("label", {
            class: "inline-flex cursor-pointer items-center gap-2 rounded-lg bg-stone-900 px-5 py-2.5 text-sm font-medium text-white hover:bg-stone-800 focus-within:ring-2 focus-within:ring-stone-900 focus-within:ring-offset-2"
          }, [
            "Upload room photo",
            h("input", {
              type: "file",
              accept: "image/jpeg,image/png,image/webp",
              class: "sr-only",
              "aria-label": "Upload a room photo",
              onChange: onFileChange
            })
          ]),
          fileName.value
            ? h("button", {
                type: "button",
                class: "text-sm text-stone-600 underline hover:text-stone-900",
                onClick: reset
              }, "Clear")
            : null,
          fileName.value
            ? h("span", { class: "meta-text truncate max-w-xs" }, fileName.value)
            : null
        ]),
        statusPanel()
      ])
  }
}
