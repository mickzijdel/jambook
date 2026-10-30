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
**Layout & composition:** single column, phone first. The room page's header (title + the big chalk key) stays pinned while the sheet scrolls. Chord rows have a fixed height so lyrics sit on one baseline. Tab blocks are monospace, never wrapped, shrunk to the screen width.
**Motion & texture:** none, apart from a press state on buttons. Texture comes from one real image: a Gemini-drawn chalk sketch (guitar, stool, pint) on the password page and the empty room, blended onto the slate (screen) and inverted for light mode.
**Signature element:** the room key, chalked huge beside the title.

**Not this:** cream paper, glow, gradients, cards inside cards, emoji, eyebrow labels, em dashes in copy.
**Differs from the last pass on:** first designed pass; the previous CSS was an unstyled dark default.
