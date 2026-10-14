const columnsIn = (document) =>
  document.sections.flatMap((section) => section.rows).flatMap((row) => row.columns)

export const elementIn = (document, id) =>
  columnsIn(document).flatMap((column) => column.elements).find((element) => element.id === id)

export const nodeIn = (document, id) => {
  const rows = document.sections.flatMap((section) => section.rows)
  return [...document.sections, ...rows, ...columnsIn(document)].find((node) => node.id === id)
}
