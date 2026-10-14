const sent = (url, token, method, body) =>
  fetch(url, {
    method,
    headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": token },
    body: JSON.stringify(body)
  }).then((response) => response.json().then((answer) => (response.ok ? answer : Promise.reject(answer))))

export const addElement = (url, token, key, columnId) => sent(url, token, "POST", { key, column_id: columnId })

export const setField = (url, token, elementId, field, value) => sent(`${url}/${elementId}`, token, "PATCH", { field, value })

export const addSection = (url, token) => sent(url, token, "POST", {})

export const addColumn = (url, token, rowId) => sent(url, token, "POST", { row_id: rowId })
