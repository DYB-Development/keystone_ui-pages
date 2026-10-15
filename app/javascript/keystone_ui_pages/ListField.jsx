import React from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

export default function ListField({ field, entries, onChange }) {
  const parts = (field.entry ?? []).filter((part) => !part.hidden)
  const saved = (changed) => onChange(field.key, changed)

  return (
    <div data-list-field={field.key} className="flex flex-col gap-2">
      {entries.map((entry, index) => (
        <fieldset key={`${index}-${JSON.stringify(entry)}`} data-list-entry className="flex flex-col gap-2 rounded-md border border-(--ks-color-border) p-2">
          {parts.map((part) => (
            <div key={part.key} className="flex flex-col gap-1">
              <Label htmlFor={`ks-pages-${field.key}-${index}-${part.key}`}>{part.label}</Label>
              <Input id={`ks-pages-${field.key}-${index}-${part.key}`} type="text" defaultValue={entry[part.key] ?? ""}
                onBlur={(event) => event.target.value !== (entry[part.key] ?? "") &&
                  saved(entries.map((kept, place) => (place === index ? { ...kept, [part.key]: event.target.value } : kept)))} />
            </div>
          ))}
        </fieldset>
      ))}
      <Button type="button" size="sm" variant="secondary" onClick={() => saved([...entries, {}])}>Add item</Button>
    </div>
  )
}
