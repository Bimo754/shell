#!/usr/bin/env python3
"""
workspace-ctl.py - Advanced Workspace & Window Arranger for Hyprland (Caelestia)

Features:
  - Zero-rearrangement workspace swapping & shifting via native compositor change_id
  - Preserves 100% of window sizes, aspect ratios, positions, and 2x2 grids
  - prepare-split: targets largest window by area to automatically produce balanced 2x2 grids
  - balance: rebalances any workspace into a clean, symmetrical grid
"""

import sys
import json
import subprocess
import time

def get_clients():
    try:
        return json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
    except Exception as e:
        print(f"Error fetching clients: {e}", file=sys.stderr)
        return []

def get_workspaces():
    try:
        return json.loads(subprocess.check_output(["hyprctl", "workspaces", "-j"]))
    except Exception as e:
        print(f"Error fetching workspaces: {e}", file=sys.stderr)
        return []

def get_active_workspace():
    try:
        ws = json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"]))
        return ws.get("id", 1)
    except Exception:
        return 1

def run_batch(commands):
    if not commands:
        return
    batch_cmd = " ; ".join(commands)
    res = subprocess.run(["hyprctl", "--batch", batch_cmd], capture_output=True, text=True)
    if "error:" in res.stdout or "error:" in res.stderr:
        print(f"Hyprland dispatch error: {res.stdout} {res.stderr}", file=sys.stderr)

def swap_workspaces(ws1, ws2, follow=True):
    if ws1 == ws2:
        return

    workspaces = get_workspaces()
    existing_ids = {ws["id"] for ws in workspaces}

    ws1_exists = ws1 in existing_ids
    ws2_exists = ws2 in existing_ids

    if not ws1_exists and not ws2_exists:
        if follow:
            run_batch([f'dispatch hl.dsp.focus({{ workspace = "{ws2}" }})'])
        return

    batch = []
    if ws1_exists and not ws2_exists:
        batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {ws1}, id = {ws2} }})')
        if follow:
            batch.append(f'dispatch hl.dsp.focus({{ workspace = "{ws2}" }})')
    elif not ws1_exists and ws2_exists:
        batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {ws2}, id = {ws1} }})')
        if follow:
            batch.append(f'dispatch hl.dsp.focus({{ workspace = "{ws1}" }})')
    else:
        # Both exist: swap using safe temporary workspace ID
        temp_id = 99999
        while temp_id in existing_ids:
            temp_id += 1
        batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {ws1}, id = {temp_id} }})')
        batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {ws2}, id = {ws1} }})')
        batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {temp_id}, id = {ws2} }})')
        if follow:
            batch.append(f'dispatch hl.dsp.focus({{ workspace = "{ws2}" }})')

    run_batch(batch)
    print(f"Swapped workspace {ws1} and workspace {ws2} (zero window re-arrangement).")

def shift_workspace(src_ws, dest_ws, follow=True):
    if src_ws == dest_ws:
        return

    workspaces = get_workspaces()
    existing_ids = {ws["id"] for ws in workspaces if ws["id"] > 0}

    if src_ws not in existing_ids:
        if follow:
            run_batch([f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})'])
        return

    batch = []
    temp_id = 99999
    while temp_id in existing_ids:
        temp_id += 1

    if dest_ws > src_ws:
        # Pushing right: shift contiguous block starting at dest_ws up by +1
        if dest_ws in existing_ids:
            curr = dest_ws
            block = []
            while curr in existing_ids:
                block.append(curr)
                curr += 1
            for ws in reversed(block):
                batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {ws}, id = {ws + 1} }})')
        batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {src_ws}, id = {dest_ws} }})')
    else:
        # dest_ws < src_ws (pushing left): rotate range [dest_ws, src_ws-1] right (+1)
        if dest_ws in existing_ids:
            batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {src_ws}, id = {temp_id} }})')
            in_range = sorted([ws for ws in existing_ids if dest_ws <= ws < src_ws], reverse=True)
            for ws in in_range:
                batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {ws}, id = {ws + 1} }})')
            batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {temp_id}, id = {dest_ws} }})')
        else:
            batch.append(f'dispatch hl.dsp.workspace.change_id({{ workspace = {src_ws}, id = {dest_ws} }})')

    if follow:
        batch.append(f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})')

    run_batch(batch)
    print(f"Shifted workspace {src_ws} to {dest_ws} (pushing existing workspaces).")

def move_workspace_all(src_ws, dest_ws, follow=True):
    clients = get_clients()
    src_wins = [w["address"] for w in clients if w["workspace"]["id"] == src_ws]
    if not src_wins:
        if follow:
            run_batch([f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})'])
        return

    dest_wins = [w["address"] for w in clients if w["workspace"]["id"] == dest_ws]
    if not dest_wins:
        # Destination is empty: change workspace ID directly for instant zero-rearrangement move
        batch = [f'dispatch hl.dsp.workspace.change_id({{ workspace = {src_ws}, id = {dest_ws} }})']
        if follow:
            batch.append(f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})')
        run_batch(batch)
        print(f"Moved workspace {src_ws} to empty workspace {dest_ws} preserving exact layout.")
    else:
        # Destination already has windows: merge into destination workspace
        batch = [f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{dest_ws}", silent = true }})' for a in src_wins]
        if follow:
            batch.append(f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})')
        run_batch(batch)
        print(f"Merged {len(src_wins)} windows from workspace {src_ws} into workspace {dest_ws}.")

def prepare_split():
    """
    Identifies the largest tiled window by area on the active workspace,
    focuses it, and preselects the optimal split direction.
    Produces a balanced, symmetrical 2x2 grid for 4 windows.
    """
    try:
        clients = get_clients()
        active_ws = get_active_workspace()

        ws_wins = [c for c in clients if c["workspace"]["id"] == active_ws and not c.get("floating", False)]
        if not ws_wins:
            return

        # Sort by window area descending
        ws_wins.sort(key=lambda c: c["size"][0] * c["size"][1], reverse=True)
        largest = ws_wins[0]

        w, h = largest["size"][0], largest["size"][1]
        # If height is comparable or larger than width, split vertically (down); else split horizontally (right)
        direction = "d" if h >= (w * 0.85) else "r"
        addr = largest["address"]

        run_batch([
            f'dispatch hl.dsp.focus({{ window = "address:{addr}" }})',
            f'dispatch hl.dsp.layout("preselect {direction}")'
        ])
    except Exception as e:
        print(f"Error in prepare_split: {e}", file=sys.stderr)

def balance_workspace():
    """
    Re-balances all tiled windows on the active workspace into an even grid.
    """
    try:
        clients = get_clients()
        active_ws = get_active_workspace()

        ws_wins = [c for c in clients if c["workspace"]["id"] == active_ws and not c.get("floating", False)]
        if len(ws_wins) <= 1:
            print("Nothing to balance (1 or 0 tiled windows).")
            return

        temp_ws = 99999
        # 1. Move all tiled windows to temporary workspace
        for w in ws_wins:
            subprocess.run(["hyprctl", "dispatch", f'hl.dsp.window.move({{ window = "address:{w["address"]}", workspace = "{temp_ws}", silent = true }})'], capture_output=True)

        time.sleep(0.05)

        # 2. Move them back one-by-one with balanced split preparation
        for w in ws_wins:
            prepare_split()
            subprocess.run(["hyprctl", "dispatch", f'hl.dsp.window.move({{ window = "address:{w["address"]}", workspace = "{active_ws}", silent = true }})'], capture_output=True)
            time.sleep(0.05)

        subprocess.run(["hyprctl", "dispatch", f'hl.dsp.focus({{ workspace = "{active_ws}" }})'], capture_output=True)
        print(f"Balanced {len(ws_wins)} windows on workspace {active_ws} into an even grid.")
    except Exception as e:
        print(f"Error balancing workspace: {e}", file=sys.stderr)

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  workspace-ctl swap <ws1> <ws2>      - Swap two workspaces (zero rearrangement)")
        print("  workspace-ctl swap-next             - Swap active workspace with next (id+1)")
        print("  workspace-ctl swap-prev             - Swap active workspace with prev (id-1)")
        print("  workspace-ctl shift <src> <dest>    - Shift workspace src to dest and push others")
        print("  workspace-ctl shift-next            - Shift active workspace forward (+1)")
        print("  workspace-ctl shift-prev            - Shift active workspace backward (-1)")
        print("  workspace-ctl move <src> <dest>     - Move workspace/windows from src to dest")
        print("  workspace-ctl prepare-split         - Prepare balanced split for next window")
        print("  workspace-ctl balance               - Rebalance active workspace to an even grid")
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "swap":
        if len(sys.argv) < 4:
            print("Usage: workspace-ctl swap <ws1> <ws2>")
            sys.exit(1)
        swap_workspaces(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd in ("swap-next", "next"):
        curr = get_active_workspace()
        swap_workspaces(curr, curr + 1, follow=True)
    elif cmd in ("swap-prev", "prev"):
        curr = get_active_workspace()
        if curr > 1:
            swap_workspaces(curr, curr - 1, follow=True)
    elif cmd == "shift":
        if len(sys.argv) < 4:
            print("Usage: workspace-ctl shift <src> <dest>")
            sys.exit(1)
        shift_workspace(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd in ("shift-next", "push-next"):
        curr = get_active_workspace()
        shift_workspace(curr, curr + 1, follow=True)
    elif cmd in ("shift-prev", "push-prev"):
        curr = get_active_workspace()
        if curr > 1:
            shift_workspace(curr, curr - 1, follow=True)
    elif cmd == "move":
        if len(sys.argv) < 4:
            print("Usage: workspace-ctl move <src> <dest>")
            sys.exit(1)
        move_workspace_all(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd in ("prepare-split", "auto-split"):
        prepare_split()
    elif cmd in ("balance", "grid"):
        balance_workspace()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
