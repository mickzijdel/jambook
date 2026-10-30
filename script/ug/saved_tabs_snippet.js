// Paste into the browser console on https://www.ultimate-guitar.com/user/mytabs while logged in,
// with "All" selected and the list scrolled to the bottom. Collects your saved tabs (artist, song,
// type, link) from UG's app data and from the links on the page, and downloads ug-saved-tabs.json.
// Metadata only, no tab contents. Sends nothing anywhere.
(() => {
  const tabs = new Map();
  const found = {};
  const add = (entry, source) => {
    if (tabs.has(entry.tab_url)) return;
    tabs.set(entry.tab_url, { ...entry, source });
    found[source] = (found[source] || 0) + 1;
  };

  // 1. App data: objects with a tab_url, in the old .js-store or in window.UGAPP.
  const roots = [];
  const store = document.querySelector(".js-store");
  if (store) {
    try {
      roots.push(["js-store", JSON.parse(store.dataset.content)]);
    } catch (error) {
      console.warn("Skipping .js-store, its data isn't JSON:", error.message);
    }
  }
  if (window.UGAPP) roots.push(["UGAPP", window.UGAPP]);
  const seen = new WeakSet();
  const walk = (node, source, depth) => {
    if (!node || typeof node !== "object" || node instanceof Node || seen.has(node) || depth > 12) return;
    seen.add(node);
    if (typeof node.tab_url === "string") {
      const { content, ...meta } = node;
      add(meta, source);
    }
    for (const key of Object.keys(node)) {
      let value;
      // Some app objects have getters that throw when read; they hold no tab data, so skip that key.
      try { value = node[key]; } catch (error) { if (!(error instanceof Error)) throw error; continue; }
      walk(value, source, depth + 1);
    }
  };
  for (const [source, root] of roots) walk(root, source, 0);

  // 2. Tab links rendered on the page. A link's row is its largest ancestor holding no other tab link.
  const tabLinks = 'a[href*="/tab/"]';
  const rowOf = (link) => {
    let row = link;
    while (row.parentElement && row.parentElement.querySelectorAll(tabLinks).length === 1) row = row.parentElement;
    return row;
  };
  for (const a of document.querySelectorAll(tabLinks)) {
    const url = new URL(a.getAttribute("href"), "https://tabs.ultimate-guitar.com");
    if (!url.pathname.startsWith("/tab/")) continue;
    const row = rowOf(a);
    add({
      tab_url: url.origin + url.pathname,
      link_text: a.textContent.trim(),
      row_text: (row?.innerText || "").replace(/\s+/g, " ").trim().slice(0, 200),
    }, "links");
  }

  const report = {
    found,
    ugapp_keys: window.UGAPP ? Object.keys(window.UGAPP) : null,
    tabs: [...tabs.values()],
  };
  console.log(`Found ${tabs.size} tabs`, found, "UGAPP keys:", report.ugapp_keys);
  if (tabs.size === 0) return console.warn("No tabs found. Save this page (Ctrl+S, 'Webpage, HTML only') and tell Claude where the file is.");
  const blob = new Blob([JSON.stringify(report, null, 2)], { type: "application/json" });
  Object.assign(document.createElement("a"), { href: URL.createObjectURL(blob), download: "ug-saved-tabs.json" }).click();
})();
