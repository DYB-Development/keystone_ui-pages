import React from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import Checkbox from "keystone_ui-react/src/Checkbox.jsx"
import Select from "keystone_ui-react/src/Select.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const swapped = (entries, from, to) => {
  const changed = [...entries]
  ;[changed[from], changed[to]] = [changed[to], changed[from]]
  return changed
}

export default function ListField({ field, entries, onChange }) {
  const parts = (field.entry ?? []).filter((part) => !part.hidden)
  const saved = (changed) => onChange(field.key, changed)

  return (
    <div data-list-field={field.key} className="flex flex-col gap-2">
      {entries.map((entry, index) => (
        <fieldset key={`${index}-${JSON.stringify(entry)}`} data-list-entry className="flex flex-col gap-2 rounded-md border border-(--ks-color-border) dark:border-(--ks-color-border-dark) p-2">
          {parts.map((part) => (
            <div key={part.key} className="flex flex-col gap-1">
              <Label htmlFor={`ks-pages-${field.key}-${index}-${part.key}`}>{part.label}</Label>
              {part.kind === "one_of" &&
                <Select id={`ks-pages-${field.key}-${index}-${part.key}`} defaultValue={entry[part.key] ?? part.default ?? ""}
                  onChange={(event) => saved(entries.map((kept, place) => (place === index ? { ...kept, [part.key]: event.target.value } : kept)))}>
                  <option value=""></option>
                  {part.options.map((option) => <option key={option} value={option}>{option}</option>)}
                </Select>}
              {part.kind !== "one_of" && (part.kind === "yes_or_no"
                ? <Checkbox id={`ks-pages-${field.key}-${index}-${part.key}`} className="self-start" defaultChecked={entry[part.key] === "true"}
                    onChange={(event) => saved(entries.map((kept, place) => (place === index ? { ...kept, [part.key]: String(event.target.checked) } : kept)))} />
                : <Input id={`ks-pages-${field.key}-${index}-${part.key}`} type="text" defaultValue={entry[part.key] ?? part.default ?? ""}
                    onBlur={(event) => event.target.value !== (entry[part.key] ?? part.default ?? "") &&
                      saved(entries.map((kept, place) => (place === index ? { ...kept, [part.key]: event.target.value } : kept)))} />)}
            </div>
          ))}
          <div className="flex flex-wrap gap-2">
            <Button type="button" size="sm" variant="secondary" disabled={index === 0} onClick={() => saved(swapped(entries, index, index - 1))}>Move up</Button>
            <Button type="button" size="sm" variant="secondary" disabled={index === entries.length - 1} onClick={() => saved(swapped(entries, index, index + 1))}>Move down</Button>
            <Button type="button" size="sm" variant="danger" onClick={() => saved(entries.filter((_kept, place) => place !== index))}>Remove item</Button>
          </div>
        </fieldset>
      ))}
      <Button type="button" size="sm" variant="secondary" onClick={() => saved([...entries, {}])}>Add item</Button>
    </div>
  )
}
