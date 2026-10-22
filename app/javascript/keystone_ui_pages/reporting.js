function sendViews() {
  document.querySelectorAll("[data-page-events]:not([data-page-viewed])").forEach((drawn) => {
    drawn.dataset.pageViewed = ""
    fetch(drawn.dataset.pageEvents, { method: "POST", credentials: "same-origin", keepalive: true })
  })
}

document.addEventListener("DOMContentLoaded", sendViews)
document.addEventListener("turbo:load", sendViews)
