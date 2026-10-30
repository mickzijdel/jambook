// A tab staff line: a bar and some dashes. Other lines in a tab (chord names, counts) ride along with it.
const isStaff = (line) => line.includes("|") && (line.match(/-/g) ?? []).length >= 3

// Breaks each staff in a tab into parts no wider than `columns`, at bar lines where it can and
// otherwise where every string rests, so a fret number is never split. Every part starts with the
// string names again. A part that can't be made narrow enough is left for the screen to shrink.
export function wrapTab(lines, columns) {
  const wrapped = []
  let staff = []
  for (const line of [ ...lines, "" ]) {
    if (line.trim()) {
      staff.push(line)
      continue
    }
    wrapped.push(...wrapStaff(staff, columns), line)
    staff = []
  }
  return wrapped.slice(0, -1)
}

function wrapStaff(lines, columns) {
  const width = Math.max(0, ...lines.map((line) => line.length))
  const strings = lines.filter(isStaff)
  if (width <= columns || !strings.length) return lines

  const every = (column, character) => strings.every((line) => line[column] === character)
  // Cutting after `column` mustn't split a chord name or a word on the other lines.
  const clean = (column) => lines.every((line) => isStaff(line) || !(/\S/.test(line[column] ?? " ") && /\S/.test(line[column + 1] ?? " ")))
  const all = [ ...Array(width).keys() ]
  const first = all.find((column) => every(column, "|"))
  if (first === undefined) return lines

  const bars = all.filter((column) => column > first && every(column, "|"))
  const end = bars.at(-1) ?? width
  const barCuts = bars.filter(clean)
  const restCuts = all.filter((column) => column > first && every(column, "-") && clean(column))
  // Every part must hold more than bar lines: no part that is only "e||" or the closing bar and "x2".
  const filled = all.map((column) => strings.some((line) => (line[column] ?? "|") !== "|"))
  const body = (from, to) => filled.slice(from + 1, to).includes(true)

  const prefix = first + 1
  const plan = (target) => {
    const cuts = []
    let start = first
    while (prefix + width - 1 - start > target) {
      const limit = start + target - prefix
      const usable = (list) => list.filter((column) => column > start && body(start, column + 1) && body(column, end))
      const fitting = (list) => usable(list).filter((column) => column <= limit).at(-1)
      const nearest = (list) => usable(list)[0]
      const cut = fitting(barCuts) ?? fitting(restCuts) ?? nearest(barCuts) ?? nearest(restCuts)
      if (cut === undefined) break
      cuts.push(cut)
      start = cut
    }
    return cuts
  }
  const widest = (cuts) => prefix + Math.max(...[ first, ...cuts ].map((from, i) => (cuts[i] ?? width - 1) - from))
  const inBar = (cuts) => cuts.filter((cut) => !bars.includes(cut)).length

  // The fewest parts that fit, then evened out, as long as no bar-line break turns into one inside a bar.
  let cuts = plan(columns)
  for (let target = columns - 1; target > prefix; target--) {
    const even = plan(target)
    if (even.length !== cuts.length || inBar(even) > inBar(cuts) || widest(even) > target) break
    cuts = even
  }

  const parts = [ first, ...cuts ].map((from, i) => lines.map((line) => {
    const head = i === 0 ? "" : isStaff(line) ? line.slice(0, prefix) : " ".repeat(prefix)
    return (head + line.slice(i === 0 ? 0 : from + 1, cuts[i] === undefined ? undefined : cuts[i] + 1)).trimEnd()
  }))
  return parts.flatMap((part, i) => (i === 0 ? part : [ "", ...part ]))
}
