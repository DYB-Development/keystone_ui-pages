import React from "react"
import Alert from "keystone_ui-react/src/Alert.jsx"
import Badge from "keystone_ui-react/src/Badge.jsx"
import Button from "keystone_ui-react/src/Button.jsx"

export default function SequencePages({ sequence }) {
  return (
    <aside data-sequence-pages className="flex w-56 shrink-0 flex-col gap-3 overflow-y-auto border-r border-(--ks-color-border) bg-(--ks-color-surface) p-4 dark:border-(--ks-color-border-dark) dark:bg-(--ks-color-surface-dark)">
      <h2 className="text-sm font-semibold">{sequence.title}</h2>
      {sequence.screen_url && <a href={sequence.screen_url} className="text-xs text-(--ks-color-accent) hover:underline">Flow</a>}
      {sequence.notice && <Alert type="success" message={sequence.notice} />}
      {sequence.refusal && <Alert type="error" message={sequence.refusal} />}
      <ol className="flex flex-col gap-1">
        {sequence.pages.map((entry, index) => (
          <li key={entry.id} data-sequence-page aria-current={entry.current ? "page" : undefined}
            className="flex items-center gap-2 rounded-md px-2 py-1.5 text-sm aria-[current=page]:bg-(--ks-color-accent)/10 aria-[current=page]:font-semibold">
            <span className="text-(--ks-color-icon)">{index + 1}</span> <a href={entry.url} className="truncate hover:underline">{entry.name}</a>
            <Badge data-page-state variant={entry.state === "Published" ? "success" : "neutral"}>{entry.state}</Badge>
            {entry.remove_url && <a href={entry.remove_url} aria-label={`Remove ${entry.name}`} className="ml-auto text-xs text-(--ks-color-icon) hover:underline">Remove</a>}
          </li>
        ))}
        <li>{sequence.end_label}</li>
      </ol>
      <Button href={sequence.add_page_url} size="sm" variant="secondary">Add page</Button>
      {sequence.publish_url && (
        <form method="post" action={sequence.publish_url} className="flex flex-col">
          <input type="hidden" name="authenticity_token" value={sequence.token} />
          <Button type="submit" size="sm">Publish</Button>
        </form>
      )}
    </aside>
  )
}
