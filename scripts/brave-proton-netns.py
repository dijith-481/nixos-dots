"""Create a WireGuard-only browser namespace without changing host routes."""

import configparser
import ipaddress
import os
import subprocess
import sys
import tempfile
from pathlib import Path

NAMESPACE = "brave-proton"
INTERFACE = "bp-proton"
RUNTIME = Path("/run/brave-proton")


def run(*args, **kwargs):
    # Never include command output or credential contents in errors/journal.
    return subprocess.run(args, check=True, capture_output=True, **kwargs)


def parse_config(path):
    conf = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#",))
    conf.read_string(path.read_text())
    if set(conf.sections()) != {"Interface", "Peer"}:
        raise ValueError(
            "Expected one Interface and one Peer in the Proton configuration"
        )
    interface, peer = conf["Interface"], conf["Peer"]
    # This parser intentionally ignores wg-quick hooks, route tables and fwmarks.
    # Imported configuration cannot execute commands or modify host networking.
    addresses = [
        ipaddress.ip_interface(v.strip()) for v in interface["Address"].split(",")
    ]
    dns = [ipaddress.ip_address(v.strip()) for v in interface["DNS"].split(",")]
    allowed = [ipaddress.ip_network(v.strip()) for v in peer["AllowedIPs"].split(",")]
    if ipaddress.ip_network("0.0.0.0/0") not in allowed:
        raise ValueError("A full IPv4 tunnel is required")
    if not any(a.version == 4 for a in addresses):
        raise ValueError("The Proton configuration needs an IPv4 address")
    ipv6 = (
        any(a.version == 6 for a in addresses)
        and ipaddress.ip_network("::/0") in allowed
    )
    dns = [a for a in dns if a.version == 4 or ipv6]
    if not dns:
        raise ValueError("The Proton configuration needs a usable DNS server")
    endpoint = peer["Endpoint"]
    host, port = endpoint.rsplit(":", 1)
    ipaddress.ip_address(host.strip("[]"))
    if not 1 <= int(port) <= 65535:
        raise ValueError("Invalid endpoint port")
    mtu = int(interface.get("MTU", "1280"))
    if not 1280 <= mtu <= 1500:
        raise ValueError("Unsupported MTU")
    # wg validates keys itself. Values never enter arguments, stdout or the store.
    wireguard = (
        f"[Interface]\nPrivateKey = {interface['PrivateKey']}\n"
        f"[Peer]\nPublicKey = {peer['PublicKey']}\n"
        f"AllowedIPs = {', '.join(map(str, allowed))}\n"
        f"Endpoint = {endpoint}\nPersistentKeepalive = 25\n"
    )
    if "PresharedKey" in peer:
        wireguard += f"PresharedKey = {peer['PresharedKey']}\n"
    return addresses, dns, ipv6, mtu, wireguard


def configure(config_path, *, create):
    addresses, dns, ipv6, mtu, wireguard = parse_config(config_path)
    RUNTIME.mkdir(mode=0o755, parents=True, exist_ok=True)
    # Write DNS only; the key remains in the systemd credential and a temporary
    # root-only file that is deleted immediately after configuring the interface.
    resolver = RUNTIME / "resolv.conf"
    resolver.write_text(
        "".join(f"nameserver {a}\n" for a in dns) + "options timeout:2 attempts:2\n"
    )
    resolver.chmod(0o644)
    # The encrypted UDP socket stays in its birthplace (the host namespace).
    # Move the cleartext interface before configuring it: it never gains a host
    # address, route or NetworkManager profile, even transiently.
    if create:
        run("ip", "netns", "add", NAMESPACE)
        run("ip", "link", "add", INTERFACE, "type", "wireguard")
        run("ip", "link", "set", INTERFACE, "netns", NAMESPACE)
    with tempfile.NamedTemporaryFile(
        mode="w", dir=RUNTIME, prefix="wg-", delete=True
    ) as secret:
        os.fchmod(secret.fileno(), 0o600)
        secret.write(wireguard)
        secret.flush()
        run("ip", "netns", "exec", NAMESPACE, "wg", "syncconf", INTERFACE, secret.name)
    # Disable unused IPv6 inside this namespace only (including loopback).
    for scope in ("all", "default"):
        run(
            "ip",
            "netns",
            "exec",
            NAMESPACE,
            sys.executable,
            "-c",
            f"from pathlib import Path; Path('/proc/sys/net/ipv6/conf/{scope}/disable_ipv6').write_text('{0 if ipv6 else 1}')",
        )
    for addr in addresses:
        if addr.version == 4 or ipv6:
            run(
                "ip", "-n", NAMESPACE, "address", "replace", str(addr), "dev", INTERFACE
            )
    run("ip", "-n", NAMESPACE, "link", "set", "lo", "up")
    run("ip", "-n", NAMESPACE, "link", "set", INTERFACE, "mtu", str(mtu), "up")
    run("ip", "-n", NAMESPACE, "route", "replace", "default", "dev", INTERFACE)
    if ipv6:
        run(
            "ip", "-n", NAMESPACE, "-6", "route", "replace", "default", "dev", INTERFACE
        )


def start(config_path):
    configure(config_path, create=True)


def repair(config_path):
    # Keep the namespace alive, so existing private windows recover too.
    configure(config_path, create=False)


def stop():
    # Deleting the interface cuts off existing browser processes too. Removing
    # the namespace name alone would leave it alive while those processes run.
    for args in (
        ("ip", "-n", NAMESPACE, "link", "del", INTERFACE),
        ("ip", "netns", "del", NAMESPACE),
        ("ip", "link", "del", INTERFACE),
    ):
        subprocess.run(args, check=False, capture_output=True)


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["start"]:
            start(Path(os.environ["CREDENTIALS_DIRECTORY"]) / "wireguard.conf")
        elif sys.argv[1:] == ["repair"]:
            # Reload control processes may not inherit the credential context
            # of an already-running oneshot service after a unit replacement.
            # This command is root-only and reads the same protected source.
            repair(Path("/etc/protonvpn/brave-private.conf"))
        elif sys.argv[1:] == ["stop"]:
            stop()
        else:
            raise ValueError("Expected start, repair or stop")
    except (
        OSError,
        ValueError,
        KeyError,
        configparser.Error,
        subprocess.CalledProcessError,
    ) as error:
        if isinstance(error, subprocess.CalledProcessError):
            print(
                f"Tunnel command failed ({error.returncode}): {' '.join(error.cmd[:8])}",
                file=sys.stderr,
            )
        else:
            print(
                f"Tunnel setup error: {type(error).__name__}, errno={getattr(error, 'errno', None)}",
                file=sys.stderr,
            )
        print(
            "Brave Proton tunnel failed. Check the root-owned WireGuard configuration and network availability.",
            file=sys.stderr,
        )
        sys.exit(1)
