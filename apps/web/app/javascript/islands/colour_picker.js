// ColourPicker island — pick a colour out of this artwork's palette and see
// what else in the catalogue sits near it perceptually.
//
// Progressive enhancement: the server already rendered "More like this, by
// colour" above this island. This adds the interactive cut, and its absence
// costs the page nothing.
import { computed, ref } from "vue"

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

    return { activeHex, results, status, errorMessage, prompt, select, reset }
  },

  template: `
    <section class="mt-16">
      <div class="flex flex-wrap items-baseline justify-between gap-3">
        <h2 class="text-xl font-semibold">Explore by colour</h2>
        <button
          v-if="activeHex"
          type="button"
          class="text-sm text-stone-600 underline hover:text-stone-900"
          @click="reset"
        >Clear</button>
      </div>

      <p class="meta-text mt-1">{{ prompt }}</p>

      <div class="mt-4 flex flex-wrap gap-3" role="group" aria-label="Colours in this artwork">
        <button
          v-for="swatch in swatches"
          :key="swatch.hex"
          type="button"
          class="h-11 w-11 rounded-full border border-stone-300 transition-transform hover:scale-105 focus:outline-none focus-visible:ring-2 focus-visible:ring-stone-900 focus-visible:ring-offset-2"
          :class="activeHex === swatch.hex ? 'ring-2 ring-stone-900 ring-offset-2' : ''"
          :style="{ backgroundColor: swatch.hex }"
          :aria-pressed="activeHex === swatch.hex"
          :aria-label="'Find artworks close to ' + swatch.hex"
          @click="select(swatch.hex)"
        ></button>
      </div>

      <div v-if="status === 'loading'" class="mt-6 grid grid-cols-2 gap-4 md:grid-cols-3" aria-hidden="true">
        <div v-for="n in 3" :key="n" class="card overflow-hidden">
          <div class="aspect-[4/5] animate-pulse bg-stone-200"></div>
          <div class="space-y-2 p-3">
            <div class="h-3 w-3/4 animate-pulse rounded bg-stone-200"></div>
            <div class="h-3 w-1/2 animate-pulse rounded bg-stone-200"></div>
          </div>
        </div>
      </div>

      <p v-else-if="status === 'empty'" class="card mt-6 p-4 text-sm text-stone-600">
        Nothing else in the catalogue sits near that colour yet.
      </p>

      <p v-else-if="status === 'error'" class="card mt-6 p-4 text-sm text-stone-600" role="status">
        {{ errorMessage }}
      </p>

      <div v-else-if="status === 'ready'" class="mt-6 grid grid-cols-2 gap-4 md:grid-cols-3">
        <a
          v-for="artwork in results"
          :key="artwork.id"
          :href="artwork.url"
          class="card group overflow-hidden transition-shadow hover:shadow-lg"
        >
          <div class="aspect-[4/5] overflow-hidden bg-stone-200">
            <img
              v-if="artwork.image_url"
              :src="artwork.image_url"
              :alt="artwork.title"
              loading="lazy"
              class="h-full w-full object-cover transition-transform group-hover:scale-105"
            />
          </div>
          <div class="p-3">
            <p class="truncate text-sm font-medium text-stone-900">{{ artwork.title }}</p>
            <p class="meta-text truncate">{{ artwork.artist }}</p>
            <p class="mt-1 text-sm font-semibold text-stone-900">{{ artwork.price }}</p>
          </div>
        </a>
      </div>

      <p v-if="status === 'ready'" class="meta-text mt-3">
        Ranked by CIELAB distance, closest first.
      </p>
    </section>
  `
}
