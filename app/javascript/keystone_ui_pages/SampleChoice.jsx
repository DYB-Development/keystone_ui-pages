import React from "react"
import Select from "keystone_ui-react/src/Select.jsx"

export default function SampleChoice({ samples, chosen, onChoose }) {
  if (samples.length === 0) return null

  return (
    <label className="flex items-center gap-2 text-sm">
      <span>Preview with</span>
      <Select defaultValue={chosen ?? ""} onChange={(event) => onChoose(event.target.value)} className="py-1">
        {samples.map(([label, value]) => <option key={value} value={value}>{label}</option>)}
      </Select>
    </label>
  )
}
