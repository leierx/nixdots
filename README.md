# notes to self
- formating the project: `nixfmt --width=6900 $(rg --files -g '*.nix')` Check: `nixfmt --check --width=6900 $(rg --files -g '*.nix')`
- cool command to get default enabled/disabled sub-modules within the "nixdots" module:

```bash
nix eval --json .#nixosConfigurations.desktop.config.nixdots.core.privilegeEscalation.enable

# independent of GIT
nix eval --impure --json path:$PWD#nixosConfigurations.desktop.config.nixdots.core.privilegeEscalation.enable
```

# Notes on coding style:
- I generally don’t like trailing punctuation
