import React from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import Select from "keystone_ui-react/src/Select.jsx"
import Textarea from "keystone_ui-react/src/Textarea.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const FieldInput = ({ field, value, onChange }) => {
  const shared = {
    id: `ks-pages-field-${field.key}`,
    defaultValue: value ?? "",
    onBlur: (event) => event.target.value !== (value ?? "") && onChange(field.key, event.target.value)
  }

  if (field.kind === "long_text") return <Textarea {...shared} rows={4} />
  return <Input {...shared} type="text" />
}

export default function ElementFields({ element, definition, alignments, onChange, onArrange }) {
  return (
    <aside data-element-fields className="flex flex-col gap-3 lg:w-72">
      {definition.fields.map((field) => (
        <div key={`${element.id}-${field.key}`} className="flex flex-col gap-1">
          <Label htmlFor={`ks-pages-field-${field.key}`}>{field.label}</Label>
          <FieldInput field={field} value={element.fields[field.key]} onChange={onChange} />
        </div>
      ))}
      <div className="flex flex-col gap-1">
        <Label htmlFor="ks-pages-element-align">Horizontal alignment</Label>
        <Select key={`${element.id}-align`} id="ks-pages-element-align" defaultValue={element.align ?? "stretch"} onChange={(event) => onArrange(element.id, "align", event.target.value)}>
          {alignments.map((value) => <option key={value} value={value}>{value}</option>)}
        </Select>
      </div>
    </aside>
  )
}
