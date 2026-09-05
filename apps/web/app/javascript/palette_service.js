// The palette service is a second Render instance with its own sleep schedule,
// so the site can be wide awake while colour search is still getting up. A free
// instance takes roughly half a minute to wake, and while it does the edge in
// front of it answers 502. Two small things make that a pause instead of a
// failure: wake it early, and wait for it rather than giving up on the first try.

const WAKEABLE_STATUSES = [502, 503, 504]
const WARMED_KEY = "palette-warmed"

// sessionStorage throws in some privacy modes, and a warm-up is never worth an
// exception on an unrelated page.
function alreadyWarmed() {
  try {
    return sessionStorage.getItem(WARMED_KEY) === "1"
  } catch (error) {
    return false
  }
}

function rememberWarmed() {
  try {
    sessionStorage.setItem(WARMED_KEY, "1")
  } catch (error) {
    // Nothing to do: we simply warm again on the next page.
  }
}

// Fire and forget. The visitor is reading the home page or a listing; by the
// time they open an artwork the colour service should be answering.
export function warmPaletteService() {
  if (alreadyWarmed()) return

  fetch("/palette/health", { method: "GET", cache: "no-store", credentials: "same-origin" })
    .then((response) => {
      if (response.ok) rememberWarmed()
    })
    .catch(() => {
      // Offline, blocked, or the service is down. Either way this is a nicety.
    })
}

// fetch, but patient with a service that is still starting. Anything that is
// not a wake-up status is returned untouched on the first pass, so a 404 or a
// 422 still fails fast - only 502/503/504 are worth waiting on.
//
// The delays escalate rather than repeat because a free instance takes around
// half a minute to wake: three quick retries would all land inside the same
// cold start and report failure just as the service came up. Rails already
// spends up to its read timeout on each attempt, so this covers roughly a
// minute in total.
const WAKE_DELAYS_MS = [3000, 6000, 10000]

export async function fetchWakingService(url, options = {}, config = {}) {
  const delays = config.delays || WAKE_DELAYS_MS
  const onWaking = config.onWaking || (() => {})

  let response = await fetch(url, options)

  for (let attempt = 0; attempt < delays.length; attempt++) {
    if (!WAKEABLE_STATUSES.includes(response.status)) return response

    onWaking(attempt + 1)
    await new Promise((resolve) => setTimeout(resolve, delays[attempt]))
    response = await fetch(url, options)
  }

  return response
}
