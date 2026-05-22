# Agent guide

Personal NixOS configuration. Flake-parts-free, loosely dendritic.

## How the flake is structured

- `flake.nix` runs `lib.evalModules` on every `.nix` file under `modules/`
  (collected by `import-tree.nix`). The result's `.config` becomes the
  flake's output.
- Files starting with `_` are skipped by `import-tree.nix`. Use this for
  in-progress / disabled modules.
- Option declarations live in `modules/flake/flake-parts.nix`. The
  freeform top-level outputs are: `nixosConfigurations`, `packages`,
  `formatter`, `modules.{nixos,homeManager,overlays}`.
- `modules.nixos` has three sub-attrs:
  - `hosts.<name>` — per-host modules, turned into real
    `nixosConfigurations` by `modules/flake/build.nix`.
  - `profiles.<name>` — composable bundles (`minimal`, `graphical`).
  - `factories.<name>` — functions that produce NixOS modules
    (e.g. `factories.homeManager <user>`).
- `modules.homeManager.<name>` — reusable HM modules, imported by
  profiles into specific users.
- `modules.overlays.<name>` — modules that set `nixpkgs.overlays`.

## Conventions (don't break these)

- **No `flake.` prefix.** Write `modules.nixos.foo = ...`, not
  `flake.modules.nixos.foo`. Reads as `config.modules.nixos.foo`. The
  `flake.nix` returns `.config` directly.
- **Every module owns its options under `flakeModules.<module>.*`.**
- **Modules are independent — no cross-module option references.**
  Compose via `config.modules.*`, not via reading another module's
  options.
- **Filenames kebab-case; Nix attrs camelCase.**
- **A single module file is either bare top-level config OR uses
  explicit `options`/`config` keys, never both.** If you declare an
  option in the same file as you set unrelated attrs, wrap the latter
  in `config = { ... }`.

## User preferences

- **Hardcode first, add flexibility when needed.** Don't introduce
  options "for future use". If a list has one entry today, hardcode it.
- **Minimal abstractions.** No DSL wrappers, no premature factories.
- **Keep things in one file when reasonable.** Splitting is for actual
  separation of concerns, not for aesthetics.
- **No comments unless they explain *why*.** Don't restate code in
  English. Don't add doc headers.
- **No emojis. Anywhere.**
- **Never commit or push.** Even when changes look done, leave it for
  the user to commit. Don't run `git commit` or `git push` unless
  explicitly asked.
- **Don't proactively edit unrelated files.** If asked about file X,
  don't reformat file Y "while you're there".
- **Run `nix flake check --no-build` after Nix edits** to verify eval
  before declaring done. Eval errors surface here, not at rebuild time.
- **When asked to research, actually research.** Read upstream module
  sources in `nixpkgs#path`, not just general knowledge. Cite the file
  and line you got it from.
- **Push back when something doesn't make sense.** Don't agree by
  default. If a suggestion has a downside, say it explicitly with the
  tradeoff.

## Tooling

- **Formatter**: `nix fmt`. Uses `treefmt` (treefmt.toml at root)
  configured to run `nixfmt-rfc-style` on `*.nix` only. Won't touch
  Lua, shell, markdown.
- **Check eval**: `nix flake check --no-build`.
- **Build a host**: `sudo nixos-rebuild switch --flake .#<host>`.
- **Build offline installer iso**:
  `nix build .#nixosConfigurations.offlineInstaller-<host>.config.system.build.isoImage`

## Hosts

- `thonkpad` — Lenovo ThinkPad, Intel iGPU, fingerprint, TLP, LUKS+disko.
- `desktop` — Ryzen 7 3700X + RX 6700 XT + NVMe, ASUS B550, dual AOC
  monitors via kanshi.

Both import `profiles.minimal + profiles.graphical + gaming`.

## Layout

```
flake.nix                  Inputs + outputs glue
import-tree.nix            Recursively imports every .nix under modules/
treefmt.toml               nix-only treefmt config
modules/
  flake/                   Flake-level plumbing (option decls, builders, fmt)
  hosts/<name>/            Per-host: configuration, hardware, disko, monitors
  profiles/                minimal, graphical
  gui/                     Display manager, fonts, theming, hyprland
  overlays/                Modules that set nixpkgs.overlays
  *.nix                    Standalone reusable modules (git, neovim, etc.)
```
