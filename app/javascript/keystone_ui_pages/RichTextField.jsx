import React, { useEffect, useState } from "react"
import Input from "keystone_ui-react/src/Input.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"
import { LexicalComposer } from "@lexical/react/LexicalComposer"
import { RichTextPlugin } from "@lexical/react/LexicalRichTextPlugin"
import { ContentEditable } from "@lexical/react/LexicalContentEditable"
import { LexicalErrorBoundary } from "@lexical/react/LexicalErrorBoundary"
import { HistoryPlugin } from "@lexical/react/LexicalHistoryPlugin"
import { LinkPlugin } from "@lexical/react/LexicalLinkPlugin"
import { useLexicalComposerContext } from "@lexical/react/LexicalComposerContext"
import { LinkNode, TOGGLE_LINK_COMMAND, $isLinkNode } from "@lexical/link"
import { $generateHtmlFromNodes, $generateNodesFromDOM } from "@lexical/html"
import { $getRoot, $getSelection, $isRangeSelection, $createParagraphNode, $createTextNode, TextNode } from "lexical"

const filled = (stored) => (editor) => {
  const root = $getRoot()
  if (stored && typeof stored === "object" && "html" in stored) {
    const dom = new DOMParser().parseFromString(stored.html, "text/html")
    root.append(...$generateNodesFromDOM(editor, dom))
  } else {
    root.append($createParagraphNode().append($createTextNode(stored ?? "")))
  }
}

const selectedLink = () => {
  const selection = $getSelection()
  if (!$isRangeSelection(selection)) return null
  const node = selection.anchor.getNode()
  return $isLinkNode(node) ? node : $isLinkNode(node.getParent()) ? node.getParent() : null
}

const PlainWords = () => {
  const [editor] = useLexicalComposerContext()
  useEffect(() => editor.registerNodeTransform(TextNode, (node) => {
    if (node.getFormat() !== 0) node.setFormat(0)
    if (node.getStyle() !== "") node.setStyle("")
  }), [editor])
  return null
}

const LinkControls = () => {
  const [editor] = useLexicalComposerContext()
  const [address, setAddress] = useState(null)

  const opened = () => editor.getEditorState().read(() => setAddress(selectedLink()?.getURL() ?? ""))
  const saved = () => {
    editor.dispatchCommand(TOGGLE_LINK_COMMAND, address || null)
    setAddress(null)
  }
  const removed = () => {
    editor.dispatchCommand(TOGGLE_LINK_COMMAND, null)
    setAddress(null)
  }

  if (address === null) return <Button type="button" variant="secondary" onClick={opened}>Link</Button>

  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor="ks-pages-link-address">Link address</Label>
      <Input id="ks-pages-link-address" type="url" value={address} onChange={(event) => setAddress(event.target.value)} />
      <div className="flex gap-2">
        <Button type="button" onClick={saved}>Save link</Button>
        <Button type="button" variant="secondary" onClick={removed}>Remove link</Button>
      </div>
    </div>
  )
}

const SavedOnLeave = ({ fieldKey, onChange, children }) => {
  const [editor] = useLexicalComposerContext()
  const left = (event) => {
    if (event.currentTarget.contains(event.relatedTarget)) return
    editor.getEditorState().read(() => onChange(fieldKey, { html: $generateHtmlFromNodes(editor, null) }))
  }
  return <div data-rich-text-field={fieldKey} onBlur={left} className="flex flex-col gap-2">{children}</div>
}

export default function RichTextField({ field, value, onChange }) {
  const config = {
    namespace: `ks-pages-${field.key}`,
    nodes: [LinkNode],
    editorState: filled(value ?? field.default),
    onError: (error) => { throw error }
  }

  return (
    <LexicalComposer initialConfig={config}>
      <SavedOnLeave fieldKey={field.key} onChange={onChange}>
        <RichTextPlugin
          contentEditable={<ContentEditable id={`ks-pages-field-${field.key}`} className="ks-input min-h-24" />}
          ErrorBoundary={LexicalErrorBoundary} />
        <HistoryPlugin />
        <LinkPlugin />
        <PlainWords />
        <LinkControls />
      </SavedOnLeave>
    </LexicalComposer>
  )
}
