---
name: design-board
description: Build a live design-picker board as a local HTML page - questions with 3-4 interactive mock-up options each, picks and notes saved in the browser, a "Together" preview of all picks, and a Copy prompt button that turns the picks into the next prompt. Use when the user wants to explore or choose a UI/visual design ("draft some designs", "let me pick", "design board", "go ham on design first", "round 2 of the drafts").
---

# Design board

A page of decisions the user clicks through instead of reading screenshots in the terminal. Each question shows 3-4 options as **live** mock-ups (drag, click, toggle, play), the user picks one per question, adds notes, and copies a prompt that comes back to you as the next request. Rounds rewrite the same file until the user says implement.

`template.html` beside this file is the engine: page chrome, sticky scenario bar, picks and notes in localStorage, the Together section, the dock with "Then: next round / shoot it real / implement" and Copy prompt. `examples/control-centre-round-1.html` is a full board (a Quickshell control centre: bar, glyphs, sliders, pills, menus, media card, open/close motion via WAAPI, pill feedback, slider dragging) to lift renderers and patterns from.

## Steps

1. **Ground it in the real thing.** Read the project's theme (palette, fonts, radii, spacing, sizes) and the current component code. Copy the real values into the `--m-*` tokens; mocks use only those. Note what stands in for what (e.g. Inter for Adwaita Sans) in the footnote.
2. **List the decisions.** Everything the user asked for becomes either an "Already decided" line (they said it outright) or a question. Group questions (`group`), 3-4 options each, today's design as one option where there is one, one option `rec: true` (your recommendation, the default for unanswered questions). Option names are short; `desc` is one sentence a reader can act on.
3. **Copy the template** to `~/.local/share/design-board/<board>/index.html` (one directory per board, so a round overwrites the page the user already has open), then fill in BOARD, STORE, DECIDED, NEXT, SCENARIOS, the renderers, SECTIONS, `renderTogether` and `onAct`.
   - Renderers read picks through `P(id)`, and a section renders option `k` as `W({ [id]: k }, fn)`, so every mock shows the user's other picks around the one in question and Together composes them all for free.
   - Interactive bits carry `data-act="verb:arg:arg"`; `onAct` changes state and returns true to re-render. Keep state that should persist across re-renders in `S`.
   - Scenario chips switch shared state (recording on/off, battery low, empty vs. flooded list) so every mock shows edge cases.
   - Motion questions: a Replay button and WAAPI (`el.animate`) with the real durations and easings; pointer feedback via CSS `cursor`.
4. **Check once, then open it.** `node --check` on the extracted script; one headless screenshot if available (chromium: `env -u LD_LIBRARY_PATH nix shell nixpkgs#chromium -c chromium --headless=new --no-sandbox --disable-gpu --window-size=1500,4200 --virtual-time-budget=5000 --screenshot=shot.png file://...`). Then `xdg-open file:///home/.../index.html` and give the user the path. The page is a `file://` document, so `navigator.clipboard` is blocked: Copy falls back to selecting the prompt's textarea, and the user presses Ctrl+C. Say so once, and say what to paste back.
5. **Next round** when the pasted prompt comes back: bump ROUND and STORE, move picked answers into DECIDED, drop settled questions, add new ones from the notes (mixes, tweaks), rewrite the same `index.html` and reload it (`xdg-open` again).

## Rules

- Mocks are faithful: real tokens, real sizes at scale 1, real copy and plausible data, never lorem ipsum.
- Options differ in kind, not in a pixel; each one should be a real candidate.
- Respect the user's standing UI preferences (AGENTS.md, earlier boards) when choosing options and the recommendation.
- No Print, no downloads, no `alert`; Copy uses `navigator.clipboard` with the select-the-textarea fallback the template has.
