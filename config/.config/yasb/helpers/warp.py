import json
import subprocess

def get_output() -> list[str]:
    check = subprocess.check_output(
        ["warp-cli", "status"],
        stdin=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        shell=True
    ).decode()
    curr = ""
    text = ""
    if "Disconnected" in check:
        curr = ""
        text = "Disconnected"
    elif "Connected" in check:
        curr = "󰌆"
        text = "Connected"
    elif "Connecting" in check:
        curr = "󰇘"
        text = "Connecting"
    else:
        curr = "󰧠"
        text = "Error"
    return curr, text

def main():
    status, text = get_output()
    output = {
        "status": status,
        "text": text
    }
    print(json.dumps(output))

main()