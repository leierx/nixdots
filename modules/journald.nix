{
  flake.modules.nixos.journald = {
    services.journald.extraConfig = "MaxRetentionSec=90day";
  };
}
