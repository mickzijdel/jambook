// What this device remembers per song: the capo, the auto-scroll speed. Private browsing can make
// localStorage throw; the in-memory copy then lasts until the tab closes.
const memory = new Map()

export function recall(key) {
  try {
    return localStorage.getItem(key) ?? memory.get(key) ?? null
  } catch {
    return memory.get(key) ?? null
  }
}

export function remember(key, value) {
  memory.set(key, String(value))
  try {
    localStorage.setItem(key, value)
  } catch {
    console.info("Kept for this tab only: browser storage is blocked.")
  }
}
