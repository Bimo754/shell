#!/usr/bin/env python3
"""
auto-arranger.py - Intelligent Window Auto-Arranger for Hyprland

Features:
  - prepare-split: targets largest tiled window on screen so opening windows
    forms an even 2x2 grid instead of a dwindle spiral (50%, 25%, 12.5%, 12.5%).
  - balance: re-tiles current workspace windows into an even grid.
"""

import sys
import json
import subprocess
import time

def get_clients():
    try:
        return json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
    except Exception:
        return []

def get_active_workspace():
    try:
        ws = json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"]))
        return ws.get("id", 1)
    except Exception:
        return 1

def prepare_split():
    try:
        clients = get_clients()
        active_ws = get_active_workspace()

        ws_wins = [c for c in clients if c["workspace"]["id"] == active_ws and not c.get("floating", False)]
        if not ws_wins:
            return

        # Sort by area descending
        ws_wins.sort(key=lambda c: c["size"][0] * c["size"][1], reverse=True)
        largest = ws_wins[0]

        w, h = largest["size"][0], largest["size"][1]
        direction = "d" if h >= (w * 0.85) else "r"
        addr = largest["address"]

        subprocess.run([
            "hyprctl", "--batch",
            f'dispatch hl.dsp.focus({{ window = "address:{addr}" }}) ; dispatch hl.dsp.layout("preselect {direction}")'
        ], capture_output=True)
    except Exception:
        pass

def balance_workspace():
    try:
        clients = get_clients()
        active_ws = get_active_workspace()

        ws_wins = [c for c in clients if c["workspace"]["id"] == active_ws and not c.get("floating", False)]
        if len(ws_wins) <= 1:
            return

        temp_ws = 99999
        for w in ws_wins:
            subprocess.run(["hyprctl", "dispatch", f'hl.dsp.window.move({{ window = "address:{w["address"]}", workspace = "{temp_ws}", silent = true }})'], capture_output=True)

        time.sleep(0.05)

        for w in ws_wins:
            prepare_split()
            subprocess.run(["hyprctl", "dispatch", f'hl.dsp.window.move({{ window = "address:{w["address"]}", workspace = "{active_ws}", silent = true }})'], capture_output=True)
            time.sleep(0.05)

        subprocess.run(["hyprctl", "dispatch", f'hl.dsp.focus({{ workspace = "{active_ws}" }})'], capture_output=True)
    except Exception:
        pass

def main():
    cmd = sys.argv[1].lower() if len(sys.argv) > 1 else "prepare"
    if cmd in ("prepare", "prepare-split", "auto-split"):
        prepare_split()
    elif cmd in ("balance", "grid"):
        balance_workspace()
    else:
        prepare_split()

if __name__ == "__main__":
    main()
