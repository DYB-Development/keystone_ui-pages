import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"

export default function SequencePages({ sequence }) {
  return (
    <aside data-sequence-pages className="flex w-56 shrink-0 flex-col gap-3 overflow-y-auto border-r border-(--ks-color-border) bg-(--ks-color-surface) p-4 dark:border-(--ks-color-border-dark) dark:bg-(--ks-color-surface-dark)">
      <h2 className="text-sm font-semibold">{sequence.title}</h2>
      <ol className="flex flex-col gap-1">
        {sequence.pages.map((entry, index) => (
          <li key={entry.id} data-sequence-page aria-current={entry.current ? "page" : undefined}
            className="flex items-center gap-2 rounded-md px-2 py-1.5 text-sm aria-[current=page]:bg-(--ks-color-accent)/10 aria-[current=page]:font-semibold">
            <span className="text-(--ks-color-icon)">{index + 1}</span> <a href={entry.url} className="truncate hover:underline">{entry.name}</a>
          </li>
        ))}
      </ol>
      <Button href={sequence.add_page_url} size="sm" variant="secondary">Add page</Button>
    </aside>
  )
}
