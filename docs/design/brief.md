# Design brief: Jambook

**Direction (one line):** tonight's song chalked on the board behind the bar, readable from a music stand.
**Feeling it should create:** easy, social, a bit scruffy, but never hard to read mid-song.
**Inspiration:** pub chalkboards and blackboard menus (seeded spread, direction A, picked by Mick on 2026-10-30).

**Typography:**
- Fredericka the Great: the song title and the big room key (chalk lettering, two places only).
- Caveat Brush: section titles (Verse, Chorus), with an amber underline.
- Chivo: lyrics and all interface text.
- Chivo Mono 700: chords, in amber; Chivo Mono 400: tab blocks.
- All self-hosted from Fontsource (OFL, see app/assets/fonts/LICENSES.txt): no requests to Google.

**Colour:** dark slate ground #1c2420, chalk ink #ece8dd, muted chalk #a3ada6, lamp amber #f2b347 (chords and the key only), lines #36423c. Light (follows the phone): pale slate #e6ebe7, ink #18221d, muted #4f5c55, amber #8f4f00. No cream: the light theme keeps the slate's cool cast.
**Layout & composition:** single column, phone first, and one column on wide screens too (Mick, 2026-10-30: side-by-side columns meant scrolling back up mid-song). The room page's header (title + the big chalk key) stays pinned while the sheet scrolls. Chord rows have a fixed height so lyrics sit on one baseline. Chord boxes are drawn in chalk lines (ink strokes, amber chord names): a scrolling row above the sheet, and a card for one chord pinned to the bottom of the screen. Tab blocks are monospace and fit the screen width: a tab that would shrink below 14px breaks into even rows at its bar lines (or where every string rests), and only a part that still doesn't fit shrinks, down to 8px.
**Motion & texture:** none, apart from a press state on buttons and the auto-scroll a viewer starts on their own phone. Two real images: a Gemini-drawn chalk sketch (guitar, stool, open songbook; no pint) on the password page and the empty room, blended onto the slate (screen) and inverted for light mode; and a Gemini slate photo, grey and low-contrast, soft-light blended over the whole page and the pinned header (fixed, so the two line up). An SVG noise version of the slate was tried and read as fog.
**Signature element:** the room key, chalked huge beside the title.

**Not this:** cream paper, glow, gradients, cards inside cards, emoji, eyebrow labels, em dashes in copy.
**Differs from the last pass on:** first designed pass; the previous CSS was an unstyled dark default.
