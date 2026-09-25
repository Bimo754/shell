#!/usr/bin/env python3
import sys
import json
import subprocess

def get_clients():
    try:
        return json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
    except Exception as e:
        print(f"Error fetching clients: {e}", file=sys.stderr)
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
    clients = get_clients()
    wins1 = [w["address"] for w in clients if w["workspace"]["id"] == ws1]
    wins2 = [w["address"] for w in clients if w["workspace"]["id"] == ws2]

    if not wins1 and not wins2:
        # If neither has windows, just focus target workspace
        if follow:
            run_batch([f'dispatch hl.dsp.focus({{ workspace = "{ws2}" }})'])
        return

    temp_ws = "99999"
    batch = []

    # 1. Move ws1 -> temp
    for a in wins1:
        batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{temp_ws}", silent = true }})')
    # 2. Move ws2 -> ws1
    for a in wins2:
        batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{ws1}", silent = true }})')
    # 3. Move temp -> ws2
    for a in wins1:
        batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{ws2}", silent = true }})')

    # 4. Follow to target workspace
    if follow:
        batch.append(f'dispatch hl.dsp.focus({{ workspace = "{ws2}" }})')

    run_batch(batch)
    print(f"Swapped workspace {ws1} and workspace {ws2}.")

def shift_workspace(src_ws, dest_ws, follow=True):
    clients = get_clients()
    occupied = sorted(set(w["workspace"]["id"] for w in clients if w["workspace"]["id"] > 0))

    src_wins = [w["address"] for w in clients if w["workspace"]["id"] == src_ws]
    if not src_wins:
        if follow:
            run_batch([f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})'])
        return

    batch = []
    if dest_ws > src_ws:
        # Pushing right: shift workspaces from highest down to dest_ws
        for ws in sorted([w for w in occupied if w >= dest_ws], reverse=True):
            wins = [w["address"] for w in clients if w["workspace"]["id"] == ws]
            for a in wins:
                batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{ws + 1}", silent = true }})')
        for a in src_wins:
            batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{dest_ws}", silent = true }})')
    elif dest_ws < src_ws:
        # Pushing left: shift workspaces from lowest up to dest_ws
        for ws in sorted([w for w in occupied if w <= dest_ws]):
            wins = [w["address"] for w in clients if w["workspace"]["id"] == ws]
            for a in wins:
                batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{ws - 1}", silent = true }})')
        for a in src_wins:
            batch.append(f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{dest_ws}", silent = true }})')
    else:
        return

    if follow:
        batch.append(f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})')

    run_batch(batch)
    print(f"Moved workspace {src_ws} to {dest_ws} (pushing existing workspaces).")

def move_workspace_all(src_ws, dest_ws, follow=True):
    clients = get_clients()
    src_wins = [w["address"] for w in clients if w["workspace"]["id"] == src_ws]
    if not src_wins:
        return
    batch = [f'dispatch hl.dsp.window.move({{ window = "address:{a}", workspace = "{dest_ws}", silent = true }})' for a in src_wins]
    if follow:
        batch.append(f'dispatch hl.dsp.focus({{ workspace = "{dest_ws}" }})')
    run_batch(batch)
    print(f"Moved all {len(src_wins)} windows from workspace {src_ws} to {dest_ws}.")

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  workspace-ctl swap <ws1> <ws2>      - Swap two workspaces")
        print("  workspace-ctl swap-next             - Swap active workspace with next (id+1)")
        print("  workspace-ctl swap-prev             - Swap active workspace with prev (id-1)")
        print("  workspace-ctl shift <src> <dest>    - Move workspace src to dest and push others")
        print("  workspace-ctl move <src> <dest>     - Move all windows from src to dest")
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
    elif cmd in ("shift", "push"):
        if len(sys.argv) < 4:
            print("Usage: workspace-ctl shift <src> <dest>")
            sys.exit(1)
        shift_workspace(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd == "move":
        if len(sys.argv) < 4:
            print("Usage: workspace-ctl move <src> <dest>")
            sys.exit(1)
        move_workspace_all(int(sys.argv[2]), int(sys.argv[3]))
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
