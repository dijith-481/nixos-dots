{ pkgs, ... }:
let
  user = "dijith";
  vpnIcon = pkgs.writeText "brave-proton-private.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
      <rect width="128" height="128" rx="28" fill="#14251e"/>
      <path d="M64 15 105 31v31c0 26-21 42-41 51-20-9-41-25-41-51V31Z" fill="#57d99b"/>
      <rect x="44" y="57" width="40" height="32" rx="7" fill="#14251e"/>
      <path d="M51 57V45a13 13 0 0 1 26 0v12" fill="none" stroke="#14251e" stroke-width="8"/>
      <circle cx="64" cy="71" r="4" fill="#57d99b"/>
      <path d="M64 73v7" stroke="#57d99b" stroke-width="4"/>
    </svg>
  '';
  tunnel = pkgs.writeText "brave-proton-netns.py" (builtins.readFile ../../../../scripts/brave-proton-netns.py);
  enter = pkgs.writeShellScript "brave-proton-enter" ''
    set -euo pipefail
    # This is the only passwordless root entry point. The executable, user,
    # profile, namespace and environment are fixed; callers may supply URLs.
    wayland_socket="''${1:-}"
    [[ "$wayland_socket" =~ ^wayland-[0-9]+$ ]] || exit 1
    shift
    for url in "$@"; do
      case "$url" in
        https://*|http://*|about:blank) ;;
        *) echo 'Only HTTP(S) URLs or about:blank are accepted.' >&2; exit 1 ;;
      esac
    done
    ${pkgs.systemd}/bin/systemctl start brave-proton-netns.service
    ${pkgs.systemd}/bin/systemctl reload brave-proton-netns.service
    user_uid=$(${pkgs.coreutils}/bin/id -u ${user})
    # Chromium sends new windows to the process owning this profile. Refuse
    # reuse after a service restart (or a manual launch outside the namespace).
    lock=$(${pkgs.coreutils}/bin/readlink /home/${user}/.config/BraveSoftware/Brave-Proton-Private/SingletonLock || true)
    pid="''${lock##*-}"
    if [[ "$pid" =~ ^[0-9]+$ && -e "/proc/$pid/ns/net" ]]; then
      browser_ns=$(${pkgs.coreutils}/bin/stat -Lc %i "/proc/$pid/ns/net")
      tunnel_ns=$(${pkgs.coreutils}/bin/stat -Lc %i /run/netns/brave-proton)
      if [[ "$browser_ns" != "$tunnel_ns" ]]; then
        echo 'Close existing VPN-private Brave windows before reopening the launcher.' >&2
        exit 1
      fi
    fi
    exec ${pkgs.iproute2}/bin/ip netns exec brave-proton \
      ${pkgs.util-linux}/bin/runuser -u ${user} -- \
      ${pkgs.coreutils}/bin/env -i \
        HOME=/home/${user} USER=${user} LOGNAME=${user} \
        PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${user}/bin \
        XDG_RUNTIME_DIR="/run/user/$user_uid" WAYLAND_DISPLAY="$wayland_socket" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_uid/bus" \
        XDG_CONFIG_HOME=/home/${user}/.config \
        XDG_CACHE_HOME=/home/${user}/.cache \
        XDG_DATA_HOME=/home/${user}/.local/share \
        XDG_CURRENT_DESKTOP=niri LANG=en_US.UTF-8 \
        CHROME_DESKTOP=brave-proton-private.desktop \
        ${pkgs.brave}/bin/brave \
          --ozone-platform=wayland \
          --class=brave-proton-private \
          --user-data-dir=/home/${user}/.config/BraveSoftware/Brave-Proton-Private \
          --incognito --no-first-run --no-default-browser-check "$@"
  '';
  launcher = pkgs.writeShellApplication {
    name = "brave-proton-private";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      if [[ ! "''${WAYLAND_DISPLAY:-}" =~ ^wayland-[0-9]+$ ]]; then
        notify-send 'Brave Private — Proton VPN' 'A Wayland session is required.'
        exit 1
      fi
      if ! /run/wrappers/bin/sudo -n ${enter} "$WAYLAND_DISPLAY" "$@"; then
        notify-send 'Brave Private — Proton VPN' \
          'Could not start the private VPN browser. Close old VPN-private Brave windows, or check the configuration and brave-proton-netns service.'
        exit 1
      fi
    '';
  };
in
{
  # Only this namespace has a route through the dedicated WireGuard interface.
  # The host's routes, firewall, DNS and Proton app are independent.
  environment.etc."netns/brave-proton/resolv.conf".source = "/run/brave-proton/resolv.conf";
  # Avoid resolving through the host's systemd-resolved Unix socket.
  environment.etc."netns/brave-proton/nsswitch.conf".text = ''
    passwd: files
    group: files
    shadow: files
    hosts: files dns
    networks: files
    services: files
    protocols: files
  '';

  systemd.services.brave-proton-netns = {
    description = "Independent Proton WireGuard tunnel for Brave private browsing";
    after = [ "network.target" ];
    reloadIfChanged = true;
    path = [ pkgs.iproute2 pkgs.wireguard-tools ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "brave-proton";
      RuntimeDirectoryMode = "0755";
      LoadCredential = "wireguard.conf:/etc/protonvpn/brave-private.conf";
      ExecStart = "${pkgs.python3}/bin/python3 ${tunnel} start";
      ExecReload = "${pkgs.python3}/bin/python3 ${tunnel} repair";
      ExecStopPost = "${pkgs.python3}/bin/python3 ${tunnel} stop";
      UMask = "0077";
    };
  };

  security.sudo.extraRules = [{
    users = [ user ];
    commands = [{ command = "${enter} *"; options = [ "NOPASSWD" ]; }];
  }];
  environment.systemPackages = [ launcher (pkgs.makeDesktopItem {
    name = "brave-proton-private";
    desktopName = "Brave VPN Only — Canada";
    genericName = "VPN-only private browser";
    comment = "Start a dedicated Proton tunnel for private browsing only";
    exec = "brave-proton-private %U";
    icon = "${vpnIcon}";
    startupWMClass = "brave-proton-private";
    categories = [ "Network" "WebBrowser" ];
    terminal = false;
  }) ];

}
