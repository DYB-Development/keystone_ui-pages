import { createRoot } from "react-dom/client"
import { register } from "keystone_ui-react/src/registry.js"
import { startMounting } from "keystone_ui-react/src/mounting.js"
import PageEditor from "./PageEditor"

register("keystone_ui_pages/editor", PageEditor)

startMounting(document, createRoot)
