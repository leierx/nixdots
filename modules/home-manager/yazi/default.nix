{}:
{
  programs.yazi = {
    enable = true;
    flavors.kanagawa = ./kanagawa.yazi;
    theme.flavor.dark = "kanagawa";
    settings = {
      mgr = {
        ratio = [1 4 3];
        sort_by = "natural";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        sort_translit = true;
      };
    };
    keymap = {};
  };
}
