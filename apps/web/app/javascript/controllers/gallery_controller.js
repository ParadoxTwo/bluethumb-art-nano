import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "thumb"]

  select(event) {
    const thumb = event.currentTarget
    const src = thumb.dataset.fullSrc
    if (!src || !this.hasMainTarget) return

    this.mainTarget.src = src
    this.thumbTargets.forEach((t) => {
      t.classList.toggle("ring-2", t === thumb)
      t.classList.toggle("ring-stone-900", t === thumb)
      t.classList.toggle("ring-offset-1", t === thumb)
    })
  }
}
