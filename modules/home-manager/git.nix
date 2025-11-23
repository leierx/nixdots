{
  programs.git = {
    enable = true;
    extraConfig = {
      credential.helper = "cache --timeout=36000";
      safe.directory = "*";
    };
  };
}
