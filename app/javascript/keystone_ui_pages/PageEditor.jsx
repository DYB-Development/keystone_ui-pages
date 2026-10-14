import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"

export default function PageEditor({ elements }) {
  return (
    <div className="flex flex-col gap-6 lg:flex-row">
      <aside data-element-palette className="flex flex-col gap-2 lg:w-56">
        {elements.map((element) => (
          <Button key={element.key} type="button" variant="secondary" data-element-key={element.key}>{element.name}</Button>
        ))}
      </aside>
    </div>
  )
}
