{
  programs.git = {
    enable = true;
    settings = {
      credential.helper = "cache --timeout=36000";
      safe.directory = "*";
    };
  };
}
