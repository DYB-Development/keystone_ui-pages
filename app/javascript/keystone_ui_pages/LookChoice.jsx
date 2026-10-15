import React from "react"
import Select from "keystone_ui-react/src/Select.jsx"

const titled = (name) => name.replace(/_/g, " ").replace(/^./, (first) => first.toUpperCase())

export default function LookChoice({ looks }) {
  if (looks.length === 0) return null

  return (
    <label className="flex items-center gap-2 text-sm">
      <span>Look</span>
      <Select data-look-choice defaultValue={document.documentElement.dataset.look} onChange={(event) => { document.documentElement.dataset.look = event.target.value }} className="py-1">
        {looks.map((name) => <option key={name} value={name}>{titled(name)}</option>)}
      </Select>
    </label>
  )
}
