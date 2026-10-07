root: {
  perSystem =
    { pkgs, ... }:
    {
      packages.pig = pkgs.buildGo127Module (finalAttrs: {
        pname = "pig";
        version = "0.4.1";

        src = pkgs.fetchFromGitHub {
          owner = "MichaelKinsy";
          repo = "PiG";
          tag = "v${finalAttrs.version}";
          hash = "sha256-JmsDIQMIfIr6StkLO7IJPajenJfOotYuZ0ZZCYVzMeA=";
        };

        vendorHash = "sha256-aEMyg5U1qkxCrKeXyV6Uu9mlozGTi8QUIbWA6I1GWis=";

        subPackages = [ "cmd/pig" ];

        # Build from go.mod alone; go.work would swap the tagged extensions/sdk for the in-tree copy.
        env = {
          GOWORK = "off";
          CGO_ENABLED = 0;
        };

        ldflags = [
          "-s"
          "-w"
          "-X main.Build=v${finalAttrs.version}"
          "-X github.com/MichaelKinsy/PiG/coding/pigletbuild.releaseSourceVersion=v${finalAttrs.version}"
        ];

        # The suite needs tmux, pty, Node and network access.
        doCheck = false;

        meta = {
          description = "Pi coding agent ported to Go";
          homepage = "https://github.com/MichaelKinsy/PiG";
          license = pkgs.lib.licenses.mit;
          mainProgram = "pig";
        };
      });
    };

  flake.modules.homeManager.pig =
    { pkgs, ... }:
    {
      home.packages = [ root.config.flake.packages.${pkgs.stdenv.hostPlatform.system}.pig ];
    };
}
