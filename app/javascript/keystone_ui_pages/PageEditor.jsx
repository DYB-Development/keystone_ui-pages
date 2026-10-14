import React, { useEffect, useRef, useState } from "react"
import { DragDropManager, Draggable, Droppable, KeyboardSensor, PointerSensor } from "@dnd-kit/dom"
import { Sortable } from "@dnd-kit/dom/sortable"
import Button from "keystone_ui-react/src/Button.jsx"
import { addColumn, addElement, addRow, addSection, arrange, moveNode, removeNode, setField } from "./operations"
import LayoutPanel from "./LayoutPanel"
import ElementFields from "./ElementFields"
import { elementIn, nodeIn } from "./document"

const PLACED_SENSORS = [PointerSensor.configure({ preventActivation: () => false }), KeyboardSensor]

export default function PageEditor({ elements, canvas: drawn, document: saved, elements_url, sections_url, columns_url, rows_url, nodes_url, arrangements, token }) {
  const [canvas, setCanvas] = useState(drawn)
  const [document, setDocument] = useState(saved)
  const [selected, setSelected] = useState(null)
  const [node, setNode] = useState(null)
  const [refusal, setRefusal] = useState(null)
  const manager = useRef(null)
  const palette = useRef(null)
  const page = useRef(null)

  const shown = ({ canvas, document }) => {
    setRefusal(null)
    setCanvas(canvas)
    setDocument(document)
  }

  const refused = ({ error }) => setRefusal(error)

  const chose = (chosen) => {
    setRefusal(null)
    setNode(chosen)
  }

  const select = (event) => {
    const chosen = event.target.closest("[data-element-id]")
    if (chosen) {
      event.preventDefault()
      setNode(null)
      return setSelected(chosen.dataset.elementId)
    }
    const column = event.target.closest("[data-column-id]")
    if (!column) return
    setSelected(null)
    setNode({ kind: "column", id: column.dataset.columnId, rowId: column.closest("[data-row-id]").dataset.rowId, sectionId: column.closest("[data-section-id]").dataset.sectionId })
  }

  const element = selected && elementIn(document, selected)
  const definition = element && elements.find((offered) => offered.key === element.key)

  useEffect(() => {
    const dragging = new DragDropManager()
    manager.current = dragging
    const items = [...palette.current.querySelectorAll("[data-element-key]")].map((element) =>
      new Draggable({ id: `palette-${element.dataset.elementKey}`, element, feedback: "clone", data: { key: element.dataset.elementKey } }, dragging))

    const marked = () => page.current.querySelectorAll("[data-drop-target]").forEach((element) => delete element.dataset.dropTarget)
    dragging.monitor.addEventListener("dragover", ({ operation }) => {
      marked()
      if (operation.target?.element) operation.target.element.dataset.dropTarget = ""
    })

    dragging.monitor.addEventListener("dragend", ({ operation, canceled }) => {
      marked()
      const { source, target } = operation
      if (canceled || !target) return
      if (source.data?.key) return addElement(elements_url, token, source.data.key, target.id).then(shown)
      const into = source.group === source.initialGroup && target.id !== source.group && !(target instanceof Sortable) ? target.id : source.group
      const position = into === source.group ? source.index : 0
      moveNode(nodes_url, token, source.id, into, position).then(shown, refused)
    })

    return () => {
      items.forEach((item) => item.destroy())
      dragging.destroy()
    }
  }, [])

  useEffect(() => {
    const columns = [...page.current.querySelectorAll("[data-column-id]")].map((element) =>
      new Droppable({ id: element.dataset.columnId, element }, manager.current))
    const placed = [...page.current.querySelectorAll("[data-element-id]")].map((element) => {
      const column = element.closest("[data-column-id]")
      const index = [...column.children].indexOf(element)
      return new Sortable({ id: element.dataset.elementId, element, index, group: column.dataset.columnId, type: "element", accept: "element", sensors: PLACED_SENSORS }, manager.current)
    })

    return () => [...columns, ...placed].forEach((droppable) => droppable.destroy())
  }, [canvas])

  return (
    <div className="flex flex-col gap-6 lg:flex-row">
      <aside ref={palette} data-element-palette className="flex flex-col gap-2 lg:w-56">
        {elements.map((element) => (
          <Button key={element.key} type="button" variant="secondary" data-element-key={element.key}>{element.name}</Button>
        ))}
        <Button type="button" variant="secondary" onClick={() => addSection(sections_url, token).then(shown)}>Add section</Button>
      </aside>
      <div ref={page} data-page-canvas className="flex-1 [&_[data-column-id]:empty]:min-h-16 [&_[data-drop-target]]:outline-2 [&_[data-drop-target]]:outline-dashed [&_[data-drop-target]]:outline-(--ks-color-accent)" onClick={select} dangerouslySetInnerHTML={{ __html: canvas }} />
      {node && <LayoutPanel node={node} values={nodeIn(document, node.id) ?? {}} arrangements={arrangements}
        onArrange={(id, setting, value) => arrange(nodes_url, token, id, setting, value).then(shown, refused)}
        refusal={refusal}
        onSelect={chose}
        onRemove={(id) => removeNode(nodes_url, token, id).then((answer) => { shown(answer); setNode(null) }, refused)}
        onAddColumn={(rowId) => addColumn(columns_url, token, rowId).then(shown)}
        onAddRow={(sectionId) => addRow(rows_url, token, sectionId).then(shown)} />}
      {definition && <ElementFields element={element} definition={definition} alignments={arrangements.element.align}
        onRemove={(id) => removeNode(nodes_url, token, id).then((answer) => { shown(answer); setSelected(null) })}
        onArrange={(id, setting, value) => arrange(nodes_url, token, id, setting, value).then(shown)}
        onChange={(field, value) => setField(elements_url, token, element.id, field, value).then(shown)} />}
    </div>
  )
}
