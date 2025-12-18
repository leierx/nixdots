{
  language = [
    {
      name = "nix";
      formatter.command = "nixfmt";
      formatter.args = ["--width=6900"];
      auto-format = true;
    }
  ];
}
