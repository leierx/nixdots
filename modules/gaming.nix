{
  modules.nixos.gaming =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        # remotePlay.openFirewall = true;
        # dedicatedServer.openFirewall = true;
      };

      # environment.systemPackages = with pkgs; [
      #   lutris
      #   mangohud
      #   protonup-qt
      #   gamescope
      # ];
      # programs.gamescope = {
      #   enable = true;
      #   capSysNice = true;
      # };
    };
}
