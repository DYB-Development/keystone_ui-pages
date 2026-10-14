import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"
import Select from "keystone_ui-react/src/Select.jsx"
import Alert from "keystone_ui-react/src/Alert.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const LABELS = {
  section: { spacing: "Section spacing" },
  row: { gap: "Row gap" },
  column: { wide: "Width on wide screens", narrow: "Width on narrow screens", align: "Vertical alignment" }
}

export default function LayoutPanel({ node, values, arrangements, refusal, onAddColumn, onAddRow, onArrange, onSelect, onRemove }) {
  const labels = LABELS[node.kind]
  const settings = Object.keys(arrangements[node.kind]).filter((setting) => labels[setting])

  return (
    <aside data-layout-panel className="flex flex-col gap-3">
      {refusal && <div data-layout-refusal><Alert type="error" message={refusal} /></div>}
      {settings.map((setting) => (
        <div key={`${node.id}-${setting}`} className="flex flex-col gap-1">
          <Label htmlFor={`ks-pages-${setting}`}>{labels[setting]}</Label>
          <Select id={`ks-pages-${setting}`} defaultValue={values[setting] ?? ""} onChange={(event) => onArrange(node.id, setting, event.target.value)}>
            {arrangements[node.kind][setting].map((value) => <option key={value} value={value}>{value}</option>)}
          </Select>
        </div>
      ))}
      {node.kind === "column" && (
        <>
          <Button type="button" variant="secondary" onClick={() => onAddColumn(node.rowId)}>Add column</Button>
          <Button type="button" variant="secondary" onClick={() => onAddRow(node.sectionId)}>Add row</Button>
          <Button type="button" variant="secondary" onClick={() => onSelect({ kind: "row", id: node.rowId, sectionId: node.sectionId })}>Select row</Button>
        </>
      )}
      {node.kind === "row" && (
        <Button type="button" variant="secondary" onClick={() => onSelect({ kind: "section", id: node.sectionId })}>Select section</Button>
      )}
      <Button type="button" variant="danger" onClick={() => onRemove(node.id)}>Remove {node.kind}</Button>
    </aside>
  )
}
