const columnsIn = (document) =>
  document.sections.flatMap((section) => section.rows).flatMap((row) => row.columns)

export const elementIn = (document, id) =>
  columnsIn(document).flatMap((column) => column.elements).find((element) => element.id === id)
