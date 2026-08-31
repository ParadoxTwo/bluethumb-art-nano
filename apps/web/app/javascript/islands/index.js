// Vue island stubs — colour picker mounts on artwork detail when present
const ISLANDS = {
  ColourPicker: {
    mount(el) {
      el.textContent = ""
      const artworkId = el.dataset.artworkId
      const wrapper = document.createElement("div")
      wrapper.className = "text-sm text-stone-600 p-4 border border-dashed rounded bg-stone-50"
      const p = document.createElement("p")
      p.className = "text-sm text-stone-600"
      p.textContent = artworkId
        ? `Colour picker for artwork #${artworkId} — connects to /palette/colour/similar/${artworkId}.`
        : "Colour picker — browse artworks to explore palette similarity."
      wrapper.appendChild(p)
    }
  }
}

function mountIslands() {
  document.querySelectorAll("[data-island-component]").forEach((el) => {
    const name = el.dataset.islandComponent
    const island = ISLANDS[name]
    if (island) island.mount(el)
  })
}

document.addEventListener("DOMContentLoaded", mountIslands)
document.addEventListener("turbo:load", mountIslands)
