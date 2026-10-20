import React from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

export default function PageTitle({ title, onChange }) {
  const shown = title ?? ""

  return (
    <div className="flex flex-col gap-1">
      <Label htmlFor="ks-pages-page-title">Page title</Label>
      <Input id="ks-pages-page-title" type="text" defaultValue={shown}
        onBlur={(event) => event.target.value !== shown && onChange(event.target.value)} />
      <p className="ks-hint">Shown in the browser tab once the page is published</p>
    </div>
  )
}
