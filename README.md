# notes to self
- formating the project: `nixfmt --width=6900 $(rg --files -g '*.nix')` Check: `nixfmt --check --width=6900 $(rg --files -g '*.nix')`
- cool command to get an overview over the available options:

```bash
nix eval --impure --json ".#nixosConfigurations.desktop.options.nixdots"
```

# Notes on coding style:
- I generally don’t like trailing punctuation

# Todo

# Todo - neovim
- [ ] fix paste binding

