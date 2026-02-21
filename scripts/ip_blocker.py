import subprocess

def is_ip_blocked(ip):
    try:
        result = subprocess.run(
            ["iptables", "-C", "INPUT", "-s", ip, "-j", "DROP"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return result.returncode == 0
    except Exception:
        return False


def block_ip_temporarily(ip, duration):
    try:
        subprocess.run(
            ["iptables", "-I", "INPUT", "-s", ip, "-j", "DROP"],
            check=True
        )

        subprocess.Popen(
            [
                "bash",
                "-c",
                f"sleep {duration}; iptables -D INPUT -s {ip} -j DROP"
            ]
        )

        return True
    except Exception:
        return False