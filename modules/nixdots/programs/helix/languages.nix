{
  language = [
    {
      name = "nix";
      formatter.command = "nixfmt";
      formatter.args = [ "--width=6900" ];
      auto-format = true;
    }
    {
      name = "markdown";
      formatter.command = "deno";
      formatter.args = [
        "fmt"
        "-"
        "--ext"
        "md"
        "--line-width"
        "6900"
      ];
      auto-format = true;
    }
  ];
}
