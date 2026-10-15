import React from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import Select from "keystone_ui-react/src/Select.jsx"
import Textarea from "keystone_ui-react/src/Textarea.jsx"
import Checkbox from "keystone_ui-react/src/Checkbox.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const FieldInput = ({ field, value, onChange }) => {
  const shown = value ?? field.default ?? ""
  const shared = {
    id: `ks-pages-field-${field.key}`,
    defaultValue: shown,
    onBlur: (event) => event.target.value !== shown && onChange(field.key, event.target.value)
  }

  if (field.kind === "yes_or_no") {
    return <Checkbox id={shared.id} defaultChecked={value === "true"} onChange={(event) => onChange(field.key, String(event.target.checked))} />
  }
  if (field.kind === "one_of") {
    return (
      <Select id={shared.id} defaultValue={value ?? field.default ?? ""} onChange={(event) => onChange(field.key, event.target.value)}>
        {field.options.map((option) => <option key={option} value={option}>{option}</option>)}
      </Select>
    )
  }
  if (field.kind === "long_text") return <Textarea {...shared} rows={4} />
  if (field.kind === "number") return <Input {...shared} type="number" />
  if (field.kind === "address") return <Input {...shared} type="url" />
  return <Input {...shared} type="text" />
}

const BINDABLE = ["text", "long_text", "address", "number", undefined]

const ValueChoice = ({ field, stored, valueNames, onChange, onBind }) => {
  const bound = stored && typeof stored === "object" ? stored : null
  const typed = bound ? bound.fallback ?? "" : stored ?? field.default ?? ""

  return (
    <Select id={`ks-pages-value-${field.key}`} aria-label={`${field.label} value`} value={bound?.value ?? ""}
      onChange={(event) => (event.target.value ? onBind(field.key, event.target.value, typed) : onChange(field.key, typed))}>
      <option value="">Typed text</option>
      {Object.entries(valueNames).map(([name, label]) => <option key={name} value={name}>{label}</option>)}
    </Select>
  )
}

export default function ElementFields({ element, definition, alignments, valueNames = {}, onChange, onArrange, onBind, onRemove }) {
  return (
    <aside data-element-fields className="flex flex-col gap-3">
      {definition.fields.map((field) => (
        <div key={`${element.id}-${field.key}`} className="flex flex-col gap-1">
          <Label htmlFor={`ks-pages-field-${field.key}`}>{field.label}</Label>
          {BINDABLE.includes(field.kind) && Object.keys(valueNames).length > 0 &&
            <ValueChoice field={field} stored={element.fields[field.key]} valueNames={valueNames} onChange={onChange} onBind={onBind} />}
          <FieldInput key={JSON.stringify(element.fields[field.key] ?? null)} field={field}
            value={typeof element.fields[field.key] === "object" && element.fields[field.key] ? element.fields[field.key].fallback ?? "" : element.fields[field.key]}
            onChange={(key, text) => (typeof element.fields[key] === "object" && element.fields[key] ? onBind(key, element.fields[key].value, text) : onChange(key, text))} />
          {typeof element.fields[field.key] === "object" && element.fields[field.key] &&
            <p className="ks-hint">Shows {valueNames[element.fields[field.key].value] ?? element.fields[field.key].value}, or this text when it has no value</p>}
        </div>
      ))}
      <div className="flex flex-col gap-1">
        <Label htmlFor="ks-pages-element-align">Horizontal alignment</Label>
        <Select key={`${element.id}-align`} id="ks-pages-element-align" defaultValue={element.align ?? definition.align ?? "stretch"} onChange={(event) => onArrange(element.id, "align", event.target.value)}>
          {alignments.map((value) => <option key={value} value={value}>{value}</option>)}
        </Select>
      </div>
      <Button type="button" variant="danger" onClick={() => onRemove(element.id)}>Remove element</Button>
    </aside>
  )
}
