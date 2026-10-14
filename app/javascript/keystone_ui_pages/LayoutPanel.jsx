import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"
import Select from "keystone_ui-react/src/Select.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const LABELS = { wide: "Width on wide screens", narrow: "Width on narrow screens" }

export default function LayoutPanel({ node, values, arrangements, onAddColumn, onAddRow, onArrange }) {
  const settings = Object.keys(arrangements[node.kind]).filter((setting) => LABELS[setting])

  return (
    <aside data-layout-panel className="flex flex-col gap-3 lg:w-72">
      {settings.map((setting) => (
        <div key={`${node.id}-${setting}`} className="flex flex-col gap-1">
          <Label htmlFor={`ks-pages-${setting}`}>{LABELS[setting]}</Label>
          <Select id={`ks-pages-${setting}`} defaultValue={values[setting] ?? ""} onChange={(event) => onArrange(node.id, setting, event.target.value)}>
            <option value="" disabled>Choose</option>
            {arrangements[node.kind][setting].map((value) => <option key={value} value={value}>{value}</option>)}
          </Select>
        </div>
      ))}
      <Button type="button" variant="secondary" onClick={() => onAddColumn(node.rowId)}>Add column</Button>
      <Button type="button" variant="secondary" onClick={() => onAddRow(node.sectionId)}>Add row</Button>
    </aside>
  )
}
