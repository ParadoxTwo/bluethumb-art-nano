// Island registry.
//
// Islands architecture: the server owns the document, and a handful of small
// interactive regions boot independently inside placeholders it rendered.
// Nothing essential on a page may depend on an island mounting — if Vue fails
// to load, the server HTML is still a complete, usable page.
//
// A mount point is any element carrying data-island-component; props arrive as
// JSON in data-island-props.
import { createApp } from "vue"
import ColourPicker from "islands/colour_picker"
import RoomMatch from "islands/room_match"

const ISLANDS = { ColourPicker, RoomMatch }
const mountedApps = new Map()

function propsFor(element) {
  const raw = element.dataset.islandProps
  if (!raw) return {}

  try {
    return JSON.parse(raw)
  } catch (error) {
    console.warn("[islands] ignoring invalid data-island-props", error)
    return {}
  }
}

function mountIslands() {
  document.querySelectorAll("[data-island-component]").forEach((element) => {
    if (mountedApps.has(element)) return

    const name = element.dataset.islandComponent
    const component = ISLANDS[name]
    if (!component) {
      console.warn("[islands] no component registered for", name)
      return
    }

    try {
      const app = createApp(component, propsFor(element))
      app.config.errorHandler = (error) => console.error("[islands] " + name + " threw", error)
      app.mount(element)
      mountedApps.set(element, app)
    } catch (error) {
      console.error("[islands] " + name + " failed to mount", error)
    }
  })
}

// Turbo caches a snapshot of the DOM before navigating away. Unmounting first
// keeps a half-torn-down Vue tree out of that snapshot.
function unmountIslands() {
  mountedApps.forEach((app) => app.unmount())
  mountedApps.clear()
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", mountIslands)
} else {
  mountIslands()
}

document.addEventListener("turbo:load", mountIslands)
document.addEventListener("turbo:before-cache", unmountIslands)
