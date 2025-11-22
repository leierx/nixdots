{
  services.dnscrypt-proxy2 = {
    enable = true;
    upstreamDefaults = false;
    settings = {
      listen_addresses = [ "127.0.0.1:53" ];
      ipv6_servers = false;
      require_dnssec = true;
      cache = true;
      log_level = 2;

      # useful for debugging
      #query_log.file = "/dev/stdout";

      server_names = [ "quad9-dnscrypt-ip4-nofilter-pri" "quad9-dnscrypt-ip4-nofilter-alt" ];
      bootstrap_resolvers = [ "9.9.9.9:53" "149.112.112.112:53" ];

      sources."quad9-resolvers" = {
        urls = [
          "https://quad9.net/dnscrypt/quad9-resolvers.md"
          "https://raw.githubusercontent.com/Quad9DNS/dnscrypt-settings/main/dnscrypt/quad9-resolvers.md"
        ];
        minisign_key = "RWTp2E4t64BrL651lEiDLNon+DqzPG4jhZ97pfdNkcq1VDdocLKvl5FW";
        cache_file = "/var/cache/dnscrypt-proxy/quad9-resolvers.md";
        refresh_delay = 72;
        prefix = "quad9-";
      };
    };
  };
}
