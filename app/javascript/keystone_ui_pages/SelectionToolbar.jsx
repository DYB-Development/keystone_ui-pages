import React, { forwardRef } from "react"

const SelectionToolbar = forwardRef(function SelectionToolbar({ place, onDuplicate, onRemove }, moveHandle) {
  return (
    <div data-selection-toolbar hidden={!place} style={place ?? {}}
      className="absolute z-20 flex -translate-y-full overflow-hidden rounded-t-md bg-(--ks-color-accent) text-xs text-white shadow">
      <button ref={moveHandle} type="button" data-move-handle className="cursor-grab px-2 py-1 hover:bg-black/20">Move</button>
      <button type="button" onClick={onDuplicate} className="px-2 py-1 hover:bg-black/20">Duplicate</button>
      <button type="button" onClick={onRemove} className="px-2 py-1 hover:bg-black/20">Remove</button>
    </div>
  )
})

export default SelectionToolbar
