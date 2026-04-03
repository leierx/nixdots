# AI Preferences

- Keep modules lean: remove unused arguments/imports; drop unused params.
- Use flake-scoped meta options (`flake.meta.*`) as the single source; avoid per-module option scaffolding.
- Default user homes to `/home/${username}` unless explicitly overridden.
- Favor shared Home Manager modules over per-username imports; use `home-manager.sharedModules` with `self.modules.*`.
- Keep small attrsets/lambdas collapsed when minimal; avoid unused outer headers.
- Avoid `description` fields on `mkOption`; keep options minimal.
- Remove unused bindings promptly; avoid duplicate headers/lets.
- Centralize user shell selection in `shell.nix`, not in `user.nix`.
- XDG user dirs module should be a plain Home Manager module (no wrapping function header).
- Keep modules focused and split out small helpers when it improves reuse (e.g., dedicated HM modules for XDG/user dirs).
