const sent = (url, token, method, body = {}) =>
  fetch(url, {
    method,
    headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": token },
    body: JSON.stringify(body)
  }).then((response) => response.json().then((answer) => (response.ok ? answer : Promise.reject(answer))))

export const addElement = (url, token, key, columnId) => sent(url, token, "POST", { key, column_id: columnId })

export const setTitle = (url, token, title) => sent(url, token, "POST", { title })

export const setField = (url, token, elementId, field, value) => sent(`${url}/${elementId}`, token, "PATCH", { field, value })

export const addSection = (url, token) => sent(url, token, "POST", {})

export const addColumn = (url, token, rowId) => sent(url, token, "POST", { row_id: rowId })

export const addRow = (url, token, sectionId) => sent(url, token, "POST", { section_id: sectionId })

export const arrange = (url, token, nodeId, setting, value) => sent(`${url}/${nodeId}`, token, "PATCH", { setting, value })

export const removeNode = (url, token, nodeId) => sent(`${url}/${nodeId}`, token, "DELETE")

export const moveNode = (url, token, nodeId, into, position) => sent(`${url}/${nodeId}/move`, token, "POST", { into, position })

export const duplicateNode = (url, token, nodeId) => sent(`${url}/${nodeId}/duplicate`, token, "POST")

export const bindField = (url, token, elementId, field, name, fallback) => sent(`${url}/${elementId}/bind`, token, "POST", { field, name, fallback })

export const chooseSample = (url, token, choice) => sent(url, token, "POST", { choice })

export const chooseAccessException = (url, token, accessException) => sent(url, token, "POST", { access_exception: accessException })

export const showWhen = (url, token, nodeId, name, equals) => sent(`${url}/${nodeId}/condition`, token, "POST", { name, equals })

export const stepHistory = (url, token) => sent(url, token, "POST")
