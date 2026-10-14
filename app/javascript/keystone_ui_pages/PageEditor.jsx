import React, { useEffect, useRef, useState } from "react"
import { DragDropManager, Draggable, Droppable, KeyboardSensor, PointerSensor } from "@dnd-kit/dom"
import { Sortable } from "@dnd-kit/dom/sortable"
import Button from "keystone_ui-react/src/Button.jsx"
import { addColumn, addElement, addRow, addSection, arrange, moveNode, removeNode, setField } from "./operations"
import LayoutPanel from "./LayoutPanel"
import DeviceWidth, { DEVICES } from "./DeviceWidth"
import ElementFields from "./ElementFields"
import { elementIn, nodeIn } from "./document"

const NODES = [["[data-element-id]", "Element"], ["[data-column-id]", "Column"], ["[data-row-id]", "Row"], ["[data-section-id]", "Section"]]

const innermost = (target) => NODES.map(([selector, kind]) => [target.closest(selector), kind]).filter(([node]) => node)
  .reduce((inner, candidate) => (!inner || inner[0].contains(candidate[0]) ? candidate : inner), null)

const PLACED_SENSORS = [PointerSensor.configure({ preventActivation: () => false }), KeyboardSensor]

export default function PageEditor({ name, publish_url, elements, canvas: drawn, document: saved, elements_url, sections_url, columns_url, rows_url, nodes_url, arrangements, token }) {
  const [canvas, setCanvas] = useState(drawn)
  const [document, setDocument] = useState(saved)
  const [selected, setSelected] = useState(null)
  const [node, setNode] = useState(null)
  const [refusal, setRefusal] = useState(null)
  const [device, setDevice] = useState("desktop")
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

  const hovered = (event) => {
    page.current.querySelectorAll("[data-hovered]").forEach((node) => delete node.dataset.hovered)
    const [node, kind] = innermost(event.target) ?? []
    if (!node) return
    node.dataset.hovered = ""
    const placed = kind === "Element" && elementIn(document, node.dataset.elementId)
    node.dataset.kind = placed ? elements.find((offered) => offered.key === placed.key)?.name ?? kind : kind
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
    <div data-builder className="fixed inset-0 flex flex-col bg-(--ks-color-surface,white)">
      <header data-builder-top-bar className="flex h-14 shrink-0 items-center justify-between gap-4 border-b border-(--ks-color-border) px-4">
        <h1 className="truncate text-base font-semibold">{name}</h1>
        <DeviceWidth chosen={device} onChoose={setDevice} />
        <form method="post" action={publish_url}>
          <input type="hidden" name="authenticity_token" value={token} />
          <Button type="submit" size="sm">Publish</Button>
        </form>
      </header>
      <div className="flex min-h-0 flex-1">
        <aside ref={palette} data-element-palette className="flex w-64 shrink-0 flex-col gap-2 overflow-y-auto border-r border-(--ks-color-border) p-4">
          {elements.map((element) => (
            <Button key={element.key} type="button" variant="secondary" data-element-key={element.key}>{element.name}</Button>
          ))}
          <Button type="button" variant="secondary" onClick={() => addSection(sections_url, token).then(shown)}>Add section</Button>
        </aside>
        <main data-page-frame className="min-w-0 flex-1 overflow-auto bg-surface-200 p-8 dark:bg-surface-900">
          <div ref={page} data-page-canvas style={{ width: DEVICES.find((choice) => choice.key === device).width }} className="@container mx-auto min-h-full max-w-full bg-white px-6 shadow-lg ring-1 ring-black/5 dark:bg-(--ks-color-surface-dark,black) [&_[data-hovered]]:relative [&_[data-hovered]]:outline-1 [&_[data-hovered]]:outline-(--ks-color-accent) [&_[data-hovered]]:before:absolute [&_[data-hovered]]:before:-top-5 [&_[data-hovered]]:before:left-0 [&_[data-hovered]]:before:z-10 [&_[data-hovered]]:before:rounded-t [&_[data-hovered]]:before:bg-(--ks-color-accent) [&_[data-hovered]]:before:px-1.5 [&_[data-hovered]]:before:text-xs [&_[data-hovered]]:before:leading-5 [&_[data-hovered]]:before:text-white [&_[data-hovered]]:before:content-[attr(data-kind)] [&_[data-column-id]:empty]:min-h-16 [&_[data-column-id]:empty]:items-center [&_[data-column-id]:empty]:justify-center [&_[data-column-id]:empty]:rounded-md [&_[data-column-id]:empty]:border-2 [&_[data-column-id]:empty]:border-dashed [&_[data-column-id]:empty]:border-(--ks-color-border-strong) [&_[data-column-id]:empty]:after:text-sm [&_[data-column-id]:empty]:after:text-(--ks-color-icon) [&_[data-column-id]:empty]:after:content-['Drop_an_element_here'] [&_[data-drop-target]]:outline-2 [&_[data-drop-target]]:outline-dashed [&_[data-drop-target]]:outline-(--ks-color-accent)" onClick={select} onMouseOver={hovered} onMouseLeave={() => page.current.querySelectorAll("[data-hovered]").forEach((node) => delete node.dataset.hovered)} dangerouslySetInnerHTML={{ __html: canvas }} />
        </main>
        <aside data-settings-panel className="w-72 shrink-0 overflow-y-auto border-l border-(--ks-color-border) p-4">
          {!node && !definition && <p className="ks-hint">Select something on the page to change it.</p>}
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
        </aside>
      </div>
    </div>
  )
}
