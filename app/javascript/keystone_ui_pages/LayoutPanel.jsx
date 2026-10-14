import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"

export default function LayoutPanel({ node, onAddColumn, onAddRow }) {
  return (
    <aside data-layout-panel className="flex flex-col gap-3 lg:w-72">
      <Button type="button" variant="secondary" onClick={() => onAddColumn(node.rowId)}>Add column</Button>
      <Button type="button" variant="secondary" onClick={() => onAddRow(node.sectionId)}>Add row</Button>
    </aside>
  )
}
