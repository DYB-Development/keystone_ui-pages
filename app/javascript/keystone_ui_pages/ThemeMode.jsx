import React from "react"
import Select from "keystone_ui-react/src/Select.jsx"

const MODES = [["light", "Light"], ["dark", "Dark"], ["system", "System"]]

const shown = (mode) => {
  document.documentElement.dataset.theme = mode
}

export default function ThemeMode() {
  const current = document.documentElement.dataset.theme ?? "system"

  return (
    <label className="flex items-center gap-2 text-sm">
      <span>Mode</span>
      <Select data-theme-mode defaultValue={current} onChange={(event) => shown(event.target.value)} className="py-1">
        {MODES.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
      </Select>
    </label>
  )
}
