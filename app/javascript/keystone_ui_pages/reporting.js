function send(address, fields = {}) {
  fetch(address, { method: "POST", body: new URLSearchParams(fields), credentials: "same-origin", keepalive: true })
}

function fire(name, drawn, details = {}) {
  document.dispatchEvent(new CustomEvent(`keystone-ui-pages:${name}`, { detail: { slug: drawn.dataset.pageSlug, place: drawn.dataset.pagePlace, ...details } }))
}

function sendViews() {
  document.querySelectorAll("[data-page-events]:not([data-page-viewed])").forEach((drawn) => {
    drawn.dataset.pageViewed = ""
    fire("view", drawn)
    send(drawn.dataset.pageEvents)
  })
}

function sendClick(event) {
  const clicked = event.target.closest("a, button")
  const drawn = clicked?.closest("[data-page-events]")
  const element = clicked?.closest("[data-page-element]")
  if (!drawn || !element) return

  fire("click", drawn, { element: element.dataset.pageElement, href: clicked.href ?? null })
  send(drawn.dataset.pageEvents, { kind: "click", element: element.dataset.pageElement })
}

document.addEventListener("DOMContentLoaded", sendViews)
document.addEventListener("turbo:load", sendViews)
document.addEventListener("click", sendClick)
