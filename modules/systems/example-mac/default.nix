# Template for a nix-darwin machine; rename and flesh out when adding a real mac
{
  hosts.example-mac = {
    class = "darwin";
    platform = "aarch64-darwin";
    user = "leier";
  };
}
