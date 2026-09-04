{
  modules.nixos.displayManager = {
    services.displayManager.ly = {
      enable = true;
      settings = {
        allow_empty_password = false;
        clear_password = true;
        session_log = "null";
      };
    };
  };
}
