import React from "react"

export default function SelectionPath({ path, onChoose }) {
  if (path.length === 0) return null

  return (
    <nav data-selection-path aria-label="Selection" className="mb-4 flex flex-wrap items-center gap-1 text-xs">
      {path.map((part, index) => (
        <React.Fragment key={part.id}>
          {index > 0 && <span aria-hidden="true" className="text-(--ks-color-icon)">›</span>}
          <button type="button" aria-current={index === path.length - 1 ? "true" : undefined} onClick={() => onChoose(part)}
            className="rounded px-1.5 py-0.5 hover:bg-(--ks-color-fill-muted) aria-[current=true]:font-semibold">
            {part.label}
          </button>
        </React.Fragment>
      ))}
    </nav>
  )
}
