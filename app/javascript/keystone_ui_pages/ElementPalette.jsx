import React, { forwardRef, useState } from "react"
import Input from "keystone_ui-react/src/Input.jsx"

const ICONS = {
  cursor: "M5 3l14 8-6 2-2 6z",
  tag: "M3 7v6l8 8 8-8-8-8H5a2 2 0 0 0-2 2zM7.5 7.5h.01",
  copy: "M8 8h11v11H8zM5 16V5h11",
  heading: "M6 4v16M18 4v16M6 12h12",
  text: "M4 6h16M4 12h16M4 18h10",
  list: "M4 6h4M12 6h8M4 12h4M12 12h8M4 18h4M12 18h8",
  info: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 16v-4M12 8h.01",
  code: "M8 6l-6 6 6 6M16 6l6 6-6 6",
  alert: "M12 3l10 18H2zM12 10v4M12 17h.01",
  card: "M3 5h18v14H3zM3 10h18",
  megaphone: "M3 11v2l13 5V6zM16 9a3 3 0 0 1 0 6M6 14l1 5h3l-1-4",
  chart: "M4 20V10M10 20V4M16 20v-7M22 20H2",
  number: "M10 3L8 21M16 3l-2 18M4 9h17M3 15h17",
  progress: "M3 12h18M3 12h10",
  box: "M3 3h18v18H3z"
}

const grouped = (elements) => {
  const groups = new Map()
  elements.forEach((element) => {
    const group = element.group ?? "Other"
    groups.set(group, [...(groups.get(group) ?? []), element])
  })
  return [...groups]
}

const PaletteItem = ({ element, shown }) => (
  <button type="button" data-element-key={element.key} hidden={!shown}
    className="flex cursor-grab items-center gap-3 rounded-md border border-(--ks-color-border) bg-(--ks-color-surface) px-3 py-2 dark:border-(--ks-color-border-dark) dark:bg-(--ks-color-surface-dark) text-left text-sm hover:border-(--ks-color-accent) dark:bg-transparent">
    <svg viewBox="0 0 24 24" aria-hidden="true" className="size-5 shrink-0 fill-none stroke-current stroke-2 text-(--ks-color-icon)" strokeLinecap="round" strokeLinejoin="round">
      <path d={ICONS[element.icon] ?? ICONS.box} />
    </svg>
    <span>{element.name}</span>
  </button>
)

const ElementPalette = forwardRef(function ElementPalette({ elements, open, children }, palette) {
  const [search, setSearch] = useState("")
  const matches = (element) => element.name.toLowerCase().includes(search.trim().toLowerCase())

  return (
    <aside ref={palette} data-element-palette className={`${open ? "max-lg:flex" : "max-lg:hidden"} flex w-64 shrink-0 flex-col gap-5 overflow-y-auto border-r border-(--ks-color-border) bg-(--ks-color-surface) p-4 dark:border-(--ks-color-border-dark) max-lg:absolute max-lg:inset-y-0 max-lg:left-0 max-lg:z-30 max-lg:shadow-xl dark:bg-(--ks-color-surface-dark)`}>
      <Input type="search" aria-label="Search elements" placeholder="Search elements" value={search} onChange={(event) => setSearch(event.target.value)} />
      {grouped(elements).map(([group, members]) => (
        <section key={group} data-element-group={group} hidden={!members.some(matches)} className="flex flex-col gap-2">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-(--ks-color-icon)">{group}</h2>
          {members.map((element) => (
            <PaletteItem key={element.key} element={element} shown={matches(element)} />
          ))}
        </section>
      ))}
      {children}
    </aside>
  )
})

export default ElementPalette
