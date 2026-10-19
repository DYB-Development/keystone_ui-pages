import React from "react"
import Select from "keystone_ui-react/src/Select.jsx"

export default function AccessExceptionChoice({ exceptions, chosen, onChoose }) {
  if (exceptions.length === 0) return null

  return (
    <label className="flex items-center gap-2 text-sm">
      <span className="whitespace-nowrap">Access exception</span>
      <Select defaultValue={chosen ?? ""} onChange={(event) => onChoose(event.target.value)} className="py-1">
        <option value="">None</option>
        {exceptions.map(([label, value]) => <option key={value} value={value}>{label}</option>)}
      </Select>
    </label>
  )
}
