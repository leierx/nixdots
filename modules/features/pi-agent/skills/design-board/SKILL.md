---
name: design-board
description: Build a live design-picker board as a local HTML page - questions with 3-4 interactive mock-up options each, picks and notes saved in the browser, a "Together" preview of all picks, and a Copy prompt button that turns the picks into the next prompt. Use when the user wants to explore or choose a UI/visual design or motion ("draft some designs", "let me pick", "design board", "give me alternatives", "go ham on design first", "round 2 of the drafts").
---

# Design board

A page of decisions the user clicks through instead of reading screenshots in the terminal. Each question shows 3-4 options as **live** mock-ups (drag, click, toggle, play), the user picks one per question, adds notes, and copies a prompt that comes back to you as the next request. Rounds edit the same board until the user says implement.

All paths below are relative to this skill's directory.

## Files

- `engine/` is the page: `index.html` (fixed markup), `engine.css` (chrome), `engine.js` (picks and notes in localStorage, scenario bar, Together, prompt, dock, Copy, plus helpers). Never edit a board's copy; fix the engine here.
- `starter/board.js`, `starter/board.css`: the part you write, a one-question example.
- `new-board.sh SLUG` (lowercase letters, digits and `-`) makes `~/.local/share/design-board/SLUG/` (refreshing the engine copies, keeping an existing `board.js`/`board.css`) and prints the path.
- `check.mjs BOARD_DIR [--shots DIR] [--eval EXPR|FILE]`: headless Chromium in real time; JSON with page errors (no `BOARD` or no questions counts as one), each question's option count, empty or sideways-overflowing mocks, an `--eval`'s awaited value, one PNG per question under `--shots`. Exit 1 on any page error.
- `examples/toggle-menus/`: a motion board on the engine (a Quickshell control centre's menus: open, swap, hand-off, timing; Play and Click fast buttons; speed chips) and `motion-check.js`, an `--eval` that samples every mock's transitions.
- `examples/control-centre-round-1.html`: an older single-file board (bar, glyphs, sliders, pills, menus, media card, open/close motion, pill feedback); lift renderers and CSS from it, not its engine.

## Steps

1. **Ground it in the real thing.** Read the project's theme (palette, fonts, radii, spacing, sizes) and the component's code; copy real values into `--m-*` tokens in `board.css`. For motion, read today's durations and easings (cite their source) and, if the project can, measure today's behaviour frame by frame first: the user's complaint is usually visible in the numbers.
2. **List the decisions.** What the user said outright goes in `DECIDED`; the rest become questions, grouped (`group`), 3-4 options that differ in kind, today's design as one option marked "(today)", one `rec: true` (your pick, the default for unanswered questions). Option names are short; `desc` is one sentence a reader can act on.
3. **Scaffold, then write only the board.** `sh new-board.sh SLUG`, then write `board.js` and `board.css` in that directory:
   - `BOARD` (name, slug, round, eyebrow, headline, footnote: what stands in for what), `DECIDED`, `SECTIONS`, `renderTogether()`, `onAct(act, x, y, e)`; optional `SCENARIOS`, `NEXT`, scenario keys via `Object.assign(S, {...})`.
   - A section renders option `k` as `render: k => W({ [id]: k }, () => mock(...))`; renderers read picks through `P(id)`, so every mock shows the user's other picks and Together composes them for free.
   - Interactive bits carry `data-act="verb:arg:arg"` (split on `:`, so no `:` inside an arg; name scopes `open-A`). Every verb but `noop` (does nothing) reaches `onAct`; the engine's own chips use other attributes. `onAct` returning true re-renders every mock; return false when you animate the DOM yourself.
   - Option keys are single capital letters (the pick badge shows them); map them to variant names in the renderer.
   - Style buttons inside a mock as `.stage .cls`: the engine resets `.stage button`.
4. **Check, look, open.** `node check.mjs DIR --shots /tmp/SLUG-shots` and fix every error, empty or overflowing mock; read two or three shots (whole sections, not the page). For motion, add an `--eval` that drives the mocks and samples them (see `examples/toggle-menus/motion-check.js`) and read the numbers against each option's description. Then `xdg-open DIR/index.html` (`open` on macOS) and give the user the path, and say they paste the copied prompt back. If the browser refuses the clipboard, Copy selects the prompt's text instead (Ctrl+C).
5. **Next round** when the prompt comes back: bump `BOARD.round` (a fresh store, so old picks don't preselect), move answered questions into `DECIDED`, drop settled ones, add new ones from the notes, edit `board.js` in place, re-run `check.mjs`, reopen.

## Motion questions

The engine has a kit; a motion board needs only its own state and transitions:

- `tween(el, to, ms, EASE.outQuad)` animates from wherever `el` is now, leaving `to` set; `EASE` maps Qt/Clutter names (`outQuad`, `outCubic`, `inOutCubic`, `outBack`, …) to CSS curves.
- Before each new transition, `settle(root)` freezes running tweens where they are (CSS transitions such as a chevron's are left alone), and `const alive = generation(scope)` hands the mock to this transition: check `alive()` after every `await` so a superseded sequence stops.
- Add `SPEED` to `SCENARIOS` (×1, ×3, ×8; `tween` and `speed()` follow it) and give each mock Play (a scripted sequence with pauses) and Click fast (the same ~160 ms apart): interruptions are where motion looks wrong.
- Keep per-mock state (which panel is open) in a module-level map so a re-render after a pick restores it.
- `--virtual-time-budget` and `--dump-dom` never advance Web Animations; `check.mjs` runs in real time.

## Rules

- Mocks are faithful: real tokens, real sizes at scale 1, real copy and plausible data, never lorem ipsum or the user's private data.
- Options differ in kind, not in a pixel; each one is a real candidate.
- Respect the user's standing UI preferences (AGENTS.md, earlier boards) in the options and the recommendation.
- No Print, no downloads, no `alert`.
- Never kill a browser with `pkill -f`: the pattern matches your own shell. `check.mjs` closes its own.
