document.addEventListener("turbo:frame-missing", (event) => {
  if (!event.target.id.startsWith("keystone-ui-pages-form-")) return

  event.preventDefault()
  event.detail.visit(event.detail.response)
})
