import React, { useEffect, useRef, useState } from "react"
import { DragDropManager, Draggable, Droppable } from "@dnd-kit/dom"
import Button from "keystone_ui-react/src/Button.jsx"
import { addElement } from "./operations"

export default function PageEditor({ elements, canvas: drawn, elements_url, token }) {
  const [canvas, setCanvas] = useState(drawn)
  const manager = useRef(null)
  const palette = useRef(null)
  const page = useRef(null)

  useEffect(() => {
    const dragging = new DragDropManager()
    manager.current = dragging
    const items = [...palette.current.querySelectorAll("[data-element-key]")].map((element) =>
      new Draggable({ id: `palette-${element.dataset.elementKey}`, element, feedback: "clone", data: { key: element.dataset.elementKey } }, dragging))

    dragging.monitor.addEventListener("dragend", ({ operation, canceled }) => {
      if (canceled || !operation.target) return
      addElement(elements_url, token, operation.source.data.key, operation.target.id).then(({ canvas }) => setCanvas(canvas))
    })

    return () => {
      items.forEach((item) => item.destroy())
      dragging.destroy()
    }
  }, [])

  useEffect(() => {
    const columns = [...page.current.querySelectorAll("[data-column-id]")].map((element) =>
      new Droppable({ id: element.dataset.columnId, element }, manager.current))

    return () => columns.forEach((column) => column.destroy())
  }, [canvas])

  return (
    <div className="flex flex-col gap-6 lg:flex-row">
      <aside ref={palette} data-element-palette className="flex flex-col gap-2 lg:w-56">
        {elements.map((element) => (
          <Button key={element.key} type="button" variant="secondary" data-element-key={element.key}>{element.name}</Button>
        ))}
      </aside>
      <div ref={page} data-page-canvas className="flex-1" dangerouslySetInnerHTML={{ __html: canvas }} />
    </div>
  )
}
