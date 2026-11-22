{
  flake.modules.nixos."nixosConfigurations/thonkpad" =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.treefmt ];

      # Brave finds Chromecasts over mDNS and SSDP, whose replies come back unicast to the asking port,
      # which conntrack never saw leave; only ports that just asked are let in, not every ephemeral one
      networking.firewall = {
        allowedUDPPorts = [ 5353 ];
        extraInputRules = "meta l4proto udp udp dport @discovery accept";
      };
      networking.nftables.tables."nixos-fw".content = lib.mkBefore ''
        set discovery {
          type inet_service
          flags timeout
        }

        chain discovery-queries {
          type filter hook output priority filter; policy accept;
          ip daddr 224.0.0.251 udp dport 5353 add @discovery { udp sport timeout 10s }
          ip6 daddr ff02::fb udp dport 5353 add @discovery { udp sport timeout 10s }
          ip daddr 239.255.255.250 udp dport 1900 add @discovery { udp sport timeout 10s }
          ip6 daddr { ff02::c, ff05::c } udp dport 1900 add @discovery { udp sport timeout 10s }
        }
      '';
    };
}
