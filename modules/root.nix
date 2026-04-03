{
  flake.modules.nixos.root = {
    # disable root account
    users.root.hashedPassword = "!";
  };
}
