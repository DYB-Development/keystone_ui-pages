import React, { useState } from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import Select from "keystone_ui-react/src/Select.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

export default function ShowWhen({ condition, valueNames, onChange }) {
  const [name, setName] = useState(condition?.value ?? "")
  const [equals, setEquals] = useState(condition?.equals ?? "")
  const names = Object.entries(valueNames ?? {})
  if (names.length === 0) return null

  const chosen = (picked) => {
    setName(picked)
    if (picked === "" || equals !== "") onChange(picked, equals)
  }

  return (
    <div data-show-when className="mt-4 flex flex-col gap-2 border-t border-(--ks-color-border) pt-4 dark:border-(--ks-color-border-dark)">
      <Label htmlFor="ks-pages-show-when-value">Show only when</Label>
      <Select id="ks-pages-show-when-value" value={name} onChange={(event) => chosen(event.target.value)}>
        <option value="">Always shown</option>
        {names.map(([key, label]) => <option key={key} value={key}>{label}</option>)}
      </Select>
      {name !== "" &&
        <>
          <Label htmlFor="ks-pages-show-when-equals">equals</Label>
          <Input id="ks-pages-show-when-equals" type="text" defaultValue={equals}
            onBlur={(event) => { setEquals(event.target.value); if (event.target.value !== condition?.equals) onChange(name, event.target.value) }} />
        </>}
    </div>
  )
}
