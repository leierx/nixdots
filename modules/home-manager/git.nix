{
  programs.git = {
    enable = true;
    extraConfig = {
      url."git@github.com:".insteadOf = "https://github.com/";
      credential.helper = "cache --timeout=36000";
      safe.directory = "*";
    };
  };
}
