import React from "react"

export const DEVICES = [
  { key: "phone", label: "Phone", width: "390px" },
  { key: "tablet", label: "Tablet", width: "768px" },
  { key: "desktop", label: "Desktop", width: "100%" }
]

export default function DeviceWidth({ chosen, onChoose }) {
  return (
    <div data-device-width role="group" aria-label="Preview width" className="flex rounded-md border border-(--ks-color-border) p-0.5">
      {DEVICES.map((device) => (
        <button key={device.key} type="button" aria-pressed={chosen === device.key} onClick={() => onChoose(device.key)}
          className="rounded px-3 py-1 text-sm aria-pressed:bg-(--ks-color-accent) aria-pressed:text-white">
          {device.label}
        </button>
      ))}
    </div>
  )
}
