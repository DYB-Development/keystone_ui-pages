import React, { useEffect, useRef, useState } from "react"
import { DragDropManager, Draggable, Droppable } from "@dnd-kit/dom"
import Button from "keystone_ui-react/src/Button.jsx"
import { addElement, addSection, setField } from "./operations"
import ElementFields from "./ElementFields"
import { elementIn } from "./document"

export default function PageEditor({ elements, canvas: drawn, document: saved, elements_url, sections_url, token }) {
  const [canvas, setCanvas] = useState(drawn)
  const [document, setDocument] = useState(saved)
  const [selected, setSelected] = useState(null)
  const manager = useRef(null)
  const palette = useRef(null)
  const page = useRef(null)

  const shown = ({ canvas, document }) => {
    setCanvas(canvas)
    setDocument(document)
  }

  const select = (event) => {
    const chosen = event.target.closest("[data-element-id]")
    if (!chosen) return
    event.preventDefault()
    setSelected(chosen.dataset.elementId)
  }

  const element = selected && elementIn(document, selected)
  const definition = element && elements.find((offered) => offered.key === element.key)

  useEffect(() => {
    const dragging = new DragDropManager()
    manager.current = dragging
    const items = [...palette.current.querySelectorAll("[data-element-key]")].map((element) =>
      new Draggable({ id: `palette-${element.dataset.elementKey}`, element, feedback: "clone", data: { key: element.dataset.elementKey } }, dragging))

    dragging.monitor.addEventListener("dragend", ({ operation, canceled }) => {
      if (canceled || !operation.target) return
      addElement(elements_url, token, operation.source.data.key, operation.target.id).then(shown)
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
        <Button type="button" variant="secondary" onClick={() => addSection(sections_url, token).then(shown)}>Add section</Button>
      </aside>
      <div ref={page} data-page-canvas className="flex-1 [&_[data-column-id]:empty]:min-h-16" onClick={select} dangerouslySetInnerHTML={{ __html: canvas }} />
      {definition && <ElementFields element={element} definition={definition} onChange={(field, value) => setField(elements_url, token, element.id, field, value).then(shown)} />}
    </div>
  )
}
