function send(address, fields = {}) {
  fetch(address, { method: "POST", body: new URLSearchParams(fields), credentials: "same-origin", keepalive: true })
}

function sendViews() {
  document.querySelectorAll("[data-page-events]:not([data-page-viewed])").forEach((drawn) => {
    drawn.dataset.pageViewed = ""
    send(drawn.dataset.pageEvents)
  })
}

function sendClick(event) {
  const clicked = event.target.closest("a, button")
  const drawn = clicked?.closest("[data-page-events]")
  const element = clicked?.closest("[data-page-element]")
  if (drawn && element) send(drawn.dataset.pageEvents, { kind: "click", element: element.dataset.pageElement })
}

document.addEventListener("DOMContentLoaded", sendViews)
document.addEventListener("turbo:load", sendViews)
document.addEventListener("click", sendClick)
