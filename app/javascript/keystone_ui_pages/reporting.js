function report(drawn, kind, details = {}) {
  document.dispatchEvent(new CustomEvent(`keystone-ui-pages:${kind}`, { detail: { slug: drawn.dataset.pageSlug, place: drawn.dataset.pagePlace, ...details } }))
  fetch(drawn.dataset.pageEvents, { method: "POST", body: new URLSearchParams({ kind, element: details.element ?? "" }), credentials: "same-origin", keepalive: true }).catch(() => {})
}

function reportViews() {
  if (document.prerendering) return document.addEventListener("prerenderingchange", reportViews, { once: true })

  document.querySelectorAll("[data-page-events]:not([data-page-viewed])").forEach((drawn) => {
    drawn.dataset.pageViewed = ""
    report(drawn, "view")
  })
}

function reportClick(event) {
  const clicked = event.target.closest("a, button")
  const drawn = clicked?.closest("[data-page-events]")
  const element = clicked?.closest("[data-page-element]")
  if (drawn && element) report(drawn, "click", { element: element.dataset.pageElement, href: clicked.href ?? null })
}

document.addEventListener("DOMContentLoaded", reportViews)
document.addEventListener("turbo:load", reportViews)
document.addEventListener("click", reportClick)
