#!/usr/bin/env bash
# ==============================================================================
# launch-terminal.sh - Context-Aware Terminal Launcher for Hyprland
#
# Behavior:
#   - Default (SUPER+Space / SUPER+Return): Inherits the working directory (CWD)
#     of the currently focused terminal window (Kitty, Foot, Alacritty, etc.).
#     If no terminal is focused, opens at $HOME (~).
#   - --home flag (SUPER+T): Always launches at $HOME (~).
#   - Auto-Arranger: Automatically targets the largest window on screen so
#     windows tile into a balanced 2x2 grid instead of an uneven spiral.
# ==============================================================================

set -e

target_dir="$HOME"

# Query active window from Hyprland if not explicitly --home
if [ "$1" != "--home" ] && [ "$1" != "-h" ]; then
    if command -v hyprctl >/dev/null 2>&1; then
        active_json="$(hyprctl activewindow -j 2>/dev/null || true)"
        if [ -n "$active_json" ]; then
            active_class="$(echo "$active_json" | jq -r '.class // empty' 2>/dev/null || true)"
            active_pid="$(echo "$active_json" | jq -r '.pid // empty' 2>/dev/null || true)"

            if [ -n "$active_pid" ] && [ "$active_pid" -gt 0 ] 2>/dev/null; then
                # Verify if active window is a known terminal emulator
                if [[ "$active_class" =~ ^([Kk]itty|[Ff]oot|[Aa]lacritty|[Ww]ezterm|[Gg]hostty)$ ]]; then
                    shell_pid=""
                    children="$(pgrep -P "$active_pid" 2>/dev/null || true)"

                    # Search for interactive shell child
                    for c in $children; do
                        comm="$(cat "/proc/$c/comm" 2>/dev/null || true)"
                        if [[ "$comm" =~ ^(zsh|bash|fish|sh|ksh|csh|tcsh)$ ]]; then
                            # Check if shell has spawned a foreground child (e.g. nvim, python)
                            sub_children="$(pgrep -P "$c" 2>/dev/null || true)"
                            for sc in $sub_children; do
                                if [ -d "/proc/$sc/cwd" ]; then
                                    shell_pid="$sc"
                                    break
                                fi
                            done
                            if [ -z "$shell_pid" ]; then
                                shell_pid="$c"
                            fi
                            break
                        fi
                    done

                    # Fallback to newest child process or active_pid itself
                    candidate_pid="${shell_pid:-$(echo "$children" | tail -n 1)}"
                    candidate_pid="${candidate_pid:-$active_pid}"

                    if [ -n "$candidate_pid" ] && [ -d "/proc/$candidate_pid/cwd" ]; then
                        resolved_cwd="$(readlink -f "/proc/$candidate_pid/cwd" 2>/dev/null || true)"
                        if [ -n "$resolved_cwd" ] && [ -d "$resolved_cwd" ]; then
                            target_dir="$resolved_cwd"
                        fi
                    fi
                fi
            fi
        fi
    fi
fi

# Prepare balanced split targeting largest window to form an even 2x2 grid
if [ -x "/home/diamond/.config/hypr/scripts/workspace-ctl.py" ]; then
    /home/diamond/.config/hypr/scripts/auto-arranger.py prepare >/dev/null 2>&1 || true
fi

exec kitty --directory "$target_dir"
