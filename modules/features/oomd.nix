{
  # oomd is on by default but watches no slice; these are Fedora's
  flake.modules.nixos.oomd.systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
  };
}
