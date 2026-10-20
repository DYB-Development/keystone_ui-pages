import React, { useEffect, useLayoutEffect, useRef, useState } from "react"
import { DragDropManager, Draggable, Droppable, KeyboardSensor, PointerSensor } from "@dnd-kit/dom"
import { Sortable } from "@dnd-kit/dom/sortable"
import Button from "keystone_ui-react/src/Button.jsx"
import { addColumn, addElement, addRow, addSection, arrange, bindField, chooseAccessException, chooseSample, duplicateNode, moveNode, removeNode, setField, setTitle, showWhen, stepHistory } from "./operations"
import LayoutPanel from "./LayoutPanel"
import DeviceWidth, { DEVICES } from "./DeviceWidth"
import SelectionToolbar from "./SelectionToolbar"
import ElementPalette from "./ElementPalette"
import SelectionPath from "./SelectionPath"
import SampleChoice from "./SampleChoice"
import PageTitle from "./PageTitle"
import AccessExceptionChoice from "./AccessExceptionChoice"
import ShowWhen from "./ShowWhen"
import ThemeMode from "./ThemeMode"
import LookChoice from "./LookChoice"
import ElementFields from "./ElementFields"
import { elementIn, nodeIn } from "./document"

const LAYOUT = [
  { kind: "section", selector: "[data-section-id]", id: (element) => element.dataset.sectionId, group: () => "page" },
  { kind: "row", selector: "[data-row-id]", id: (element) => element.dataset.rowId, group: (element) => element.closest("[data-section-id]").dataset.sectionId },
  { kind: "column", selector: "[data-column-id]", id: (element) => element.dataset.columnId, group: (element) => element.closest("[data-row-id]").dataset.rowId }
]

const NODES = [["[data-element-id]", "Element"], ["[data-column-id]", "Column"], ["[data-row-id]", "Row"], ["[data-section-id]", "Section"]]

const innermost = (target) => NODES.map(([selector, kind]) => [target.closest(selector), kind]).filter(([node]) => node)
  .reduce((inner, candidate) => (!inner || inner[0].contains(candidate[0]) ? candidate : inner), null)

const PLACED_SENSORS = [PointerSensor.configure({ preventActivation: () => false }), KeyboardSensor]

export default function PageEditor({ name, publish_url, unpublish_url, elements, canvas: drawn, document: saved, elements_url, sections_url, columns_url, rows_url, nodes_url, arrangements, defaults, shares, value_names, looks = [], samples = [], sample, samples_url, title_url, access_exceptions = [], access_exception, access_exception_url, history_url, live_url, back_url, undo_url, redo_url, undoable: couldUndo, redoable: couldRedo, token }) {
  const [canvas, setCanvas] = useState(drawn)
  const [undoable, setUndoable] = useState(couldUndo)
  const [redoable, setRedoable] = useState(couldRedo)
  const [document, setDocument] = useState(saved)
  const [selected, setSelected] = useState(null)
  const [node, setNode] = useState(null)
  const [refusal, setRefusal] = useState(null)
  const [device, setDevice] = useState("desktop")
  const sheet = useRef(null)
  const moveHandle = useRef(null)
  const [toolbarPlace, setToolbarPlace] = useState(null)
  const [selectionPath, setSelectionPath] = useState([])
  const manager = useRef(null)
  const palette = useRef(null)
  const page = useRef(null)

  const shown = ({ canvas, document, undoable, redoable }) => {
    setRefusal(null)
    setCanvas(canvas)
    setDocument(document)
    if (undoable !== undefined) setUndoable(undoable)
    if (redoable !== undefined) setRedoable(redoable)
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

  useLayoutEffect(() => {
    page.current.innerHTML = canvas
  }, [canvas])

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
      if (source.data?.key) return target.data?.columnId && addElement(elements_url, token, source.data.key, target.data.columnId).then(shown)
      if (source.type !== "element") return moveNode(nodes_url, token, source.id, source.group === "page" ? null : source.group, source.index).then(shown, refused)
      const into = source.group === source.initialGroup && target.data?.columnId && target.data.columnId !== source.group ? target.data.columnId : source.group
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
      new Droppable({ id: `drop-${element.dataset.columnId}`, element, data: { columnId: element.dataset.columnId }, accept: (source) => !source.type || source.type === "element" }, manager.current))
    const placed = [...page.current.querySelectorAll("[data-element-id]")].map((element) => {
      const column = element.closest("[data-column-id]")
      const index = [...column.children].indexOf(element)
      return new Sortable({ id: element.dataset.elementId, element, index, group: column.dataset.columnId, type: "element", accept: "element", sensors: PLACED_SENSORS }, manager.current)
    })

    return () => [...columns, ...placed].forEach((droppable) => droppable.destroy())
  }, [canvas])

  const pathTo = (chosen) => [
    ["section", "[data-section-id]", "sectionId", "Section"],
    ["row", "[data-row-id]", "rowId", "Row"],
    ["column", "[data-column-id]", "columnId", "Column"],
    ["element", "[data-element-id]", "elementId", null]
  ].flatMap(([kind, selector, key, label]) => {
    const holder = chosen.closest(selector)
    if (!holder) return []
    const placed = kind === "element" && elementIn(document, holder.dataset[key])
    return [{ kind, id: holder.dataset[key], label: label ?? elements.find((offered) => offered.key === placed?.key)?.name ?? "Element" }]
  })

  const choosePart = ({ kind, id }) => {
    setRefusal(null)
    if (kind === "element") {
      setNode(null)
      return setSelected(id)
    }
    const holder = page.current.querySelector(`[data-${kind}-id="${id}"]`)
    setSelected(null)
    setNode({ kind, id, rowId: holder.closest("[data-row-id]")?.dataset.rowId, sectionId: holder.closest("[data-section-id]")?.dataset.sectionId })
  }

  useEffect(() => {
    const parent = selectionPath[selectionPath.length - 2]
    const escaped = (event) => {
      if (event.key !== "Escape" || !parent || event.target.closest("input, textarea, select")) return
      choosePart(parent)
    }
    window.document.addEventListener("keydown", escaped)
    return () => window.document.removeEventListener("keydown", escaped)
  }, [selectionPath])

  const selectedId = selected ?? node?.id

  useEffect(() => {
    page.current.querySelectorAll("[data-selected]").forEach((marked) => delete marked.dataset.selected)
    const chosen = selectedId && page.current.querySelector(`[data-element-id="${selectedId}"], [data-column-id="${selectedId}"], [data-row-id="${selectedId}"], [data-section-id="${selectedId}"]`)
    if (!chosen) {
      setSelectionPath([])
      return setToolbarPlace(null)
    }
    chosen.dataset.selected = ""
    setSelectionPath(pathTo(chosen))
    const outer = sheet.current.getBoundingClientRect()
    const inner = chosen.getBoundingClientRect()
    setToolbarPlace({ top: inner.top - outer.top, left: inner.left - outer.left })
  }, [canvas, selectedId, device])

  useEffect(() => {
    const unreachable = window.document.createElement("span")
    const layout = LAYOUT.flatMap(({ kind, selector, id, group }) =>
      [...page.current.querySelectorAll(selector)].map((element) => new Sortable({
        id: id(element), element, index: [...element.parentElement.children].indexOf(element), group: group(element), type: kind, accept: kind,
        handle: selectedId === id(element) ? moveHandle.current : unreachable
      }, manager.current)))

    return () => layout.forEach((sortable) => sortable.destroy())
  }, [canvas, selectedId])

  const inUse = (chosen) => {
    const row = chosen.kind === "column" && nodeIn(document, chosen.rowId)
    const share = row ? { wide: shares[row.columns.length] ?? "1/1" } : {}
    return { ...defaults[chosen.kind], ...share, ...nodeIn(document, chosen.id) }
  }

  const removeSelected = () => removeNode(nodes_url, token, selectedId).then((answer) => { shown(answer); setNode(null); setSelected(null) }, refused)

  return (
    <div data-builder className="fixed inset-0 flex flex-col bg-(--ks-color-surface) text-(--ks-color-text) dark:bg-(--ks-color-surface-dark) dark:text-(--ks-color-text-dark)">
      <header data-builder-top-bar className="flex h-14 shrink-0 items-center justify-between gap-4 border-b border-(--ks-color-border) dark:border-(--ks-color-border-dark) px-4">
        <div className="flex min-w-0 items-center gap-2">
          <a href={back_url} className="text-sm hover:underline">Back</a>
          <h1 className="truncate text-base font-semibold">{name}</h1>
        </div>
        <div className="flex items-center gap-4 max-lg:hidden">
          <DeviceWidth chosen={device} onChoose={setDevice} />
          <ThemeMode />
          <LookChoice looks={looks} />
          <SampleChoice samples={samples} chosen={sample} onChoose={(choice) => chooseSample(samples_url, token, choice).then(shown, refused)} />
          <AccessExceptionChoice exceptions={access_exceptions} chosen={access_exception} onChoose={(choice) => chooseAccessException(access_exception_url, token, choice).then(shown, refused)} />
        </div>
        <div className="flex items-center gap-2">
        <Button type="button" size="sm" variant="secondary" disabled={!undoable} title={undoable ? "Undo the last change" : "Nothing to undo"} onClick={() => stepHistory(undo_url, token).then(shown, refused)}>↶ Undo</Button>
        <Button type="button" size="sm" variant="secondary" disabled={!redoable} title={redoable ? "Redo the change you undid" : "Nothing to redo"} onClick={() => stepHistory(redo_url, token).then(shown, refused)}>↷ Redo</Button>
        {live_url && <a href={live_url} className="text-sm whitespace-nowrap hover:underline">View live</a>}
        <a href={history_url} className="text-sm hover:underline">History</a>
        {unpublish_url && (
          <form method="post" action={unpublish_url}>
            <input type="hidden" name="authenticity_token" value={token} />
            <Button type="submit" size="sm" variant="secondary">Unpublish</Button>
          </form>
        )}
        <form method="post" action={publish_url}>
          <input type="hidden" name="authenticity_token" value={token} />
          <Button type="submit" size="sm">Publish</Button>
        </form>
        </div>
      </header>
      <div className="relative flex min-h-0 flex-1">
        <ElementPalette ref={palette} elements={elements}>
          <Button type="button" variant="secondary" onClick={() => addSection(sections_url, token).then(shown)}>Add section</Button>
        </ElementPalette>
        <main data-page-frame className="min-w-0 flex-1 overflow-auto bg-surface-200 p-8 dark:bg-surface-900">
          <div ref={sheet} data-page-sheet data-theme={DEVICES.find((choice) => choice.key === device).theme}
            style={{ width: DEVICES.find((choice) => choice.key === device).width, colorScheme: DEVICES.find((choice) => choice.key === device).theme }}
            className="relative mx-auto min-h-full max-w-full bg-[Canvas] shadow-lg ring-1 ring-black/5">
            <div ref={page} data-page-canvas className="@container min-h-full px-6 [&_[data-hidden]]:opacity-40 bg-(--ks-color-page) text-(--ks-color-on-page) dark:bg-(--ks-color-page-dark) dark:text-(--ks-color-on-page-dark) [&_[data-selected]]:relative [&_[data-selected]]:outline-2 [&_[data-selected]]:outline-(--ks-color-accent) [&_[data-hovered]]:relative [&_[data-hovered]]:outline-1 [&_[data-hovered]]:outline-(--ks-color-accent) [&_[data-hovered]]:before:absolute [&_[data-hovered]]:before:-top-5 [&_[data-hovered]]:before:left-0 [&_[data-hovered]]:before:z-10 [&_[data-hovered]]:before:rounded-t [&_[data-hovered]]:before:bg-(--ks-color-accent) [&_[data-hovered]]:before:px-1.5 [&_[data-hovered]]:before:text-xs [&_[data-hovered]]:before:leading-5 [&_[data-hovered]]:before:text-white [&_[data-hovered]]:before:content-[attr(data-kind)] [&_[data-column-id]:empty]:min-h-16 [&_[data-column-id]:empty]:items-center [&_[data-column-id]:empty]:justify-center [&_[data-column-id]:empty]:rounded-md [&_[data-column-id]:empty]:border-2 [&_[data-column-id]:empty]:border-dashed [&_[data-column-id]:empty]:border-(--ks-color-border-strong) [&_[data-column-id]:empty]:after:text-sm [&_[data-column-id]:empty]:after:text-(--ks-color-icon) [&_[data-column-id]:empty]:after:content-['Drop_an_element_here'] [&_[data-drop-target]]:outline-2 [&_[data-drop-target]]:outline-dashed [&_[data-drop-target]]:outline-(--ks-color-accent)" onClick={select} onMouseOver={hovered} onMouseLeave={() => page.current.querySelectorAll("[data-hovered]").forEach((node) => delete node.dataset.hovered)} />
            <SelectionToolbar ref={moveHandle} place={toolbarPlace} onRemove={removeSelected} onDuplicate={() => duplicateNode(nodes_url, token, selectedId).then(shown, refused)} />
          </div>
        </main>
        <aside data-settings-panel className="w-72 shrink-0 overflow-y-auto border-l border-(--ks-color-border) bg-(--ks-color-surface) p-4 dark:border-(--ks-color-border-dark) dark:bg-(--ks-color-surface-dark)">
          <SelectionPath path={selectionPath} onChoose={choosePart} />
          {!node && !definition && <p className="ks-hint">Select something on the page to change it.</p>}
          {!node && !definition && <PageTitle key={document.title ?? ""} title={document.title} onChange={(title) => setTitle(title_url, token, title).then(shown, refused)} />}
          {node && <LayoutPanel node={node} values={inUse(node)} arrangements={arrangements}
            onArrange={(id, setting, value) => arrange(nodes_url, token, id, setting, value).then(shown, refused)}
            refusal={refusal}
            onSelect={chose}
            onRemove={(id) => removeNode(nodes_url, token, id).then((answer) => { shown(answer); setNode(null) }, refused)}
            onAddColumn={(rowId) => addColumn(columns_url, token, rowId).then(shown)}
            onAddRow={(sectionId) => addRow(rows_url, token, sectionId).then(shown)} />}
          {definition && <ElementFields element={element} definition={definition} alignments={arrangements.element.align}
            onRemove={(id) => removeNode(nodes_url, token, id).then((answer) => { shown(answer); setSelected(null) })}
            onArrange={(id, setting, value) => arrange(nodes_url, token, id, setting, value).then(shown)}
            valueNames={value_names}
            onBind={(field, name, fallback) => bindField(elements_url, token, element.id, field, name, fallback).then(shown, refused)}
            onChange={(field, value) => setField(elements_url, token, element.id, field, value).then(shown)} />}
          {(element || (node && node.kind !== "column")) &&
            <ShowWhen key={element?.id ?? node.id} condition={(element ?? nodeIn(document, node.id))?.show_when} valueNames={value_names}
              onChange={(name, equals) => showWhen(nodes_url, token, element?.id ?? node.id, name, equals).then(shown, refused)} />}
        </aside>
      </div>
    </div>
  )
}
