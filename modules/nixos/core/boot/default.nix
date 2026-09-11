{
  flake.modules.nixos.boot = {
    boot.tmp.cleanOnBoot = true;
    boot.loader.timeout = 3;
  };
}
