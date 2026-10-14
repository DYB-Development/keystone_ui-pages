import React from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

export default function ElementFields({ element, definition, onChange }) {
  return (
    <aside data-element-fields className="flex flex-col gap-3 lg:w-72">
      {definition.fields.map((field) => (
        <div key={`${element.id}-${field.key}`} className="flex flex-col gap-1">
          <Label htmlFor={`ks-pages-field-${field.key}`}>{field.label}</Label>
          <Input id={`ks-pages-field-${field.key}`} type="text" defaultValue={element.fields[field.key] ?? ""}
            onBlur={(event) => event.target.value !== (element.fields[field.key] ?? "") && onChange(field.key, event.target.value)} />
        </div>
      ))}
    </aside>
  )
}
