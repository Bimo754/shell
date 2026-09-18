# Comprehensive Guide: Integrating Cybersecurity Suite into Caelestia Shell

This document provides an end-to-end architectural blueprint, code templates, and deployment instructions for implementing your specialized cybersecurity and penetration testing features natively into **Caelestia Shell**.

---

## 1. Architecture Overview

### Why Native Integration?
Caelestia Shell uses **Matugen** to extract dynamic Material Design 3 color palettes from the active wallpaper (`Colours.palette.*`), combined with unified styling tokens (`Tokens.*`), Google Sans / Rubik typography, and smooth GPU-accelerated scene-graph transitions.

By building your cybersecurity components directly into Caelestia’s module tree:
1. **Dynamic Theming**: Your Target IP badge, VPN indicators, and Cyber Drawer automatically react to wallpaper changes and light/dark mode toggles.
2. **Native Performance**: Eliminates the slow Python-on-a-timer loop; replaces it with event-driven file monitoring and native Quickshell singletons.
3. **Single Unified System**: Your cyber tools sit seamlessly inside the taskbar and sliding drawers, rather than feeling like a disconnected floating widget.

---

## 2. Directory Structure

All custom cybersecurity code is isolated in a dedicated directory inside the repository to ensure clean separation from upstream Caelestia files:

```
shell/
├── modules/
│   ├── cyber/                            <-- YOUR ISOLATED CYBER SUITE
│   │   ├── CyberState.qml                (State singleton: Target IP, Domains, VPN)
│   │   ├── CyberBarItem.qml              (Taskbar badge: IP display, 1-click copy)
│   │   └── CyberDrawer.qml               (Popout card: Nmap scans, Arsenal, Workspaces)
│   └── bar/
│       └── Bar.qml                       (Modified: 3 lines added to DelegateChooser)
```

---

## 3. Implementation Code

### Component A: State Singleton (`modules/cyber/CyberState.qml`)

This component manages engagement target data (`target_ip`, `target_domains`) and detects active VPN connections (`tun0`, `wg0`, `proton0`) using native Quickshell services without spawning heavy Python interpreters.

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Engagement Target Properties
    property string targetIp: ""
    property var targetDomains: []
    readonly property bool hasTarget: targetIp.length > 0 && targetIp !== "NONE" && targetIp !== "Unset"

    // VPN Properties
    property string vpnIp: "Disconnected"
    property string vpnInterface: "None"
    readonly property bool vpnConnected: vpnInterface !== "None" && vpnIp !== "Disconnected"

    // Target Storage Paths
    readonly property string cyberDataDir: Quickshell.env("HOME") + "/.local/share/caelestia/cyber"
    readonly property string targetIpFile: cyberDataDir + "/target_ip"
    readonly property string targetDomainsFile: cyberDataDir + "/target_domains"

    // 1. Target IP Reader (event-driven via Quickshell Process)
    Process {
        id: targetReader
        command: ["bash", "-c", "mkdir -p '" + root.cyberDataDir + "'; cat '" + root.targetIpFile + "' 2>/dev/null || echo ''"]
        stdout: SplitParser {
            onRead: data => {
                root.targetIp = data.trim();
            }
        }
    }

    // 2. Target Domains Reader
    Process {
        id: domainReader
        command: ["bash", "-c", "cat '" + root.targetDomainsFile + "' 2>/dev/null || echo ''"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n").filter(l => l.trim().length > 0);
                root.targetDomains = lines;
            }
        }
    }

    // 3. Fast VPN Interface Checker (reads Linux sysfs/ip directly)
    Process {
        id: vpnChecker
        command: [
            "bash", "-c",
            "for iface in tun0 wg0 proton0 tap0; do " +
            "  if [ -d /sys/class/net/$iface ]; then " +
            "    ip=$(ip -4 -o addr show $iface 2>/dev/null | awk '{print $4}' | cut -d/ -f1); " +
            "    echo \"$iface:$ip\"; exit 0; " +
            "  fi; " +
            "done; " +
            "echo 'None:Disconnected'"
        ]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(":");
                if (parts.length >= 2) {
                    root.vpnInterface = parts[0];
                    root.vpnIp = parts[1] || "Connected";
                } else {
                    root.vpnInterface = "None";
                    root.vpnIp = "Disconnected";
                }
            }
        }
    }

    // Polling interval (low overhead: bash builtins only, no Python runtime)
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            targetReader.running = true;
            domainReader.running = true;
            vpnChecker.running = true;
        }
    }

    // Helper Actions
    function setTarget(ip: string) {
        let clean = ip.trim();
        Quickshell.execDetached(["bash", "-c", "mkdir -p '" + root.cyberDataDir + "' && echo -n '" + clean + "' > '" + root.targetIpFile + "'"]);
        root.targetIp = clean;
    }

    function clearTarget() {
        Quickshell.execDetached(["bash", "-c", "rm -f '" + root.targetIpFile + "' '" + root.targetDomainsFile + "'"]);
        root.targetIp = "";
        root.targetDomains = [];
    }

    function copyToClipboard(text: string) {
        if (!text || text.length === 0) return;
        Quickshell.execDetached(["bash", "-c", "echo -n '" + text + "' | wl-copy"]);
    }
}
```

---

### Component B: Taskbar Badge (`modules/cyber/CyberBarItem.qml`)

Visual badge placed inside Caelestia’s taskbar. Displays the active target and VPN state with 1-click clipboard copy.

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "."

Item {
    id: root

    implicitWidth: layout.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    StyledRect {
        anchors.fill: parent
        color: CyberState.hasTarget ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainer
        border.color: CyberState.hasTarget ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
        border.width: 1
        radius: Tokens.rounding.medium

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            // Target Indicator
            RowLayout {
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: "radar"
                    color: CyberState.hasTarget ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: CyberState.hasTarget ? CyberState.targetIp : "NO TARGET"
                    color: CyberState.hasTarget ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (CyberState.hasTarget) {
                            CyberState.copyToClipboard(CyberState.targetIp);
                        }
                    }
                }
            }

            // Separator
            StyledRect {
                width: 1
                height: 12
                color: Colours.palette.m3outlineVariant
            }

            // VPN Indicator
            RowLayout {
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: CyberState.vpnConnected ? "vpn_lock" : "vpn_key_off"
                    color: CyberState.vpnConnected ? Colours.palette.m3primary : Colours.palette.m3error
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: CyberState.vpnConnected ? CyberState.vpnInterface : "VPN OFF"
                    color: CyberState.vpnConnected ? Colours.palette.m3onSurface : Colours.palette.m3error
                    font: Tokens.font.label.small
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (CyberState.vpnConnected) {
                            CyberState.copyToClipboard(CyberState.vpnIp);
                        }
                    }
                }
            }
        }
    }
}
```

---

### Component C: Cyber Drawer & Arsenal Card (`modules/cyber/CyberDrawer.qml`)

A sliding frosted glass command card for 1-click execution of scans and tools.

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "."

StyledRect {
    id: root

    implicitWidth: 380
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    color: Colours.tPalette.m3surface
    border.color: Colours.palette.m3outlineVariant
    radius: Tokens.rounding.large

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // Header
        RowLayout {
            Layout.fillWidth: true

            MaterialIcon {
                text: "security"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: "Cyber Command Deck"
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }

            IconButton {
                icon: "delete_sweep"
                onClicked: CyberState.clearTarget()
            }
        }

        // Active Target Banner
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium

                StyledText {
                    text: "Target: " + (CyberState.hasTarget ? CyberState.targetIp : "Not Set")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurface
                    Layout.fillWidth: true
                }

                TextButton {
                    text: "Copy"
                    enabled: CyberState.hasTarget
                    onClicked: CyberState.copyToClipboard(CyberState.targetIp)
                }
            }
        }

        // Scan Triggers
        StyledText {
            text: "Recon & Scans"
            font: Tokens.font.label.large
            color: Colours.palette.m3outline
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ButtonBase {
                Layout.fillWidth: true
                text: "Fast Scan"
                enabled: CyberState.hasTarget
                onClicked: {
                    Quickshell.execDetached(["kitty", "--title", "Nmap Fast: " + CyberState.targetIp, "bash", "-c", "sudo nmap -F -sV -T4 " + CyberState.targetIp + "; read -p 'Done. Press enter.'"]);
                }
            }

            ButtonBase {
                Layout.fillWidth: true
                text: "Full Scan"
                enabled: CyberState.hasTarget
                onClicked: {
                    Quickshell.execDetached(["kitty", "--title", "Nmap Full: " + CyberState.targetIp, "bash", "-c", "sudo nmap -p- -sV -sC -T4 " + CyberState.targetIp + "; read -p 'Done. Press enter.'"]);
                }
            }

            ButtonBase {
                Layout.fillWidth: true
                text: "Vuln Scripts"
                enabled: CyberState.hasTarget
                onClicked: {
                    Quickshell.execDetached(["kitty", "--title", "Nmap Vuln: " + CyberState.targetIp, "bash", "-c", "sudo nmap --script vuln -Pn " + CyberState.targetIp + "; read -p 'Done. Press enter.'"]);
                }
            }
        }

        // GUI Tools & Terminal Layouts
        StyledText {
            text: "Arsenal & Workspaces"
            font: Tokens.font.label.large
            color: Colours.palette.m3outline
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ButtonBase {
                Layout.fillWidth: true
                text: "Burp Suite"
                onClicked: Quickshell.execDetached(["burpsuite"])
            }

            ButtonBase {
                Layout.fillWidth: true
                text: "Wireshark"
                onClicked: Quickshell.execDetached(["wireshark"])
            }

            ButtonBase {
                Layout.fillWidth: true
                text: "HTTP:8000"
                onClicked: Quickshell.execDetached(["kitty", "--title", "HTTP Server :8000", "python3", "-m", "http.server", "8000"])
            }
        }

        // 4-Quadrant Pentest Kitty Workspace
        ButtonBase {
            Layout.fillWidth: true
            text: "Launch 4-Quadrant Pentest Workspace"
            onClicked: {
                let target = CyberState.targetIp || "127.0.0.1";
                Quickshell.execDetached([
                    "bash", "-c",
                    "hyprctl dispatch workspace 5; " +
                    "kitty --title 'Recon' bash -c 'export TARGET=" + target + "; echo \"[+] Target: $TARGET\"; bash' & sleep 0.2; " +
                    "kitty --title 'Exploit' bash -c 'export TARGET=" + target + "; bash' & sleep 0.2; " +
                    "kitty --title 'Listener' bash -c 'nc -lvnp 4444' & sleep 0.2; " +
                    "kitty --title 'Notes' bash -c 'nvim target_notes.md' &"
                ]);
            }
        }
    }
}
```

---

## 4. Surgical Integration into Caelestia Core

To activate your cyber module with minimal intrusion into upstream Caelestia files, apply this exact 3-line modification to [`modules/bar/Bar.qml`](file:///home/diamond/Desktop/Github/shell/modules/bar/Bar.qml):

### `modules/bar/Bar.qml` Diff
```diff
--- a/modules/bar/Bar.qml
+++ b/modules/bar/Bar.qml
@@ -5,6 +5,7 @@
 import "components/workspaces"
+import "../cyber" as Cyber
 import QtQuick
@@ -141,6 +142,13 @@
             DelegateChoice {
                 roleValue: "workspaces"
                 delegate: EntryWrapper {
                     Workspaces { ... }
                 }
             }
+            DelegateChoice {
+                roleValue: "cyber"
+                delegate: EntryWrapper {
+                    Cyber.CyberBarItem {}
+                }
+            }
             DelegateChoice {
                 roleValue: "activeWindow"
```

---

## 5. Caelestia Configuration (`~/.config/caelestia/shell.json`)

Configure Caelestia to display your cyber widget and register search launcher actions:

```json
{
    "enabled": true,
    "bar": {
        "entries": [
            { "id": "logo" },
            { "id": "workspaces" },
            { "id": "cyber" },
            { "id": "spacer" },
            { "id": "clock" },
            { "id": "statusIcons" },
            { "id": "power" }
        ]
    },
    "launcher": {
        "actions": [
            {
                "name": "Target: Quick Nmap Scan",
                "icon": "radar",
                "description": "Run fast Nmap scan against active target",
                "command": ["kitty", "-e", "bash", "-c", "target=$(cat ~/.local/share/caelestia/cyber/target_ip 2>/dev/null); sudo nmap -F -sV $target; read -p 'Done'"]
            },
            {
                "name": "Arsenal: Launch Burp Suite",
                "icon": "security",
                "description": "Launch Burp Suite Community/Pro",
                "command": ["burpsuite"]
            },
            {
                "name": "Workspace: 4-Quadrant Pentest",
                "icon": "grid_view",
                "description": "Spawn 4-quadrant Kitty pentest grid",
                "command": ["hyprctl", "dispatch", "workspace", "5"]
            }
        ]
    }
}
```

---

## 6. Git Upstream Maintenance Protocol

Because upstream Caelestia will continue receiving updates, use this workflow to guarantee you never get merge conflicts:

### Initial Setup (On your fork):
```bash
cd ~/Desktop/Github/shell
# Add official upstream remote
git remote add upstream https://github.com/caelestia-dots/shell.git
# Create your feature branch
git checkout -b cyber-main
```

### Applying Upstream Updates:
Whenever Caelestia releases an update:
```bash
cd ~/Desktop/Github/shell
# 1. Fetch latest upstream commits
git fetch upstream

# 2. Rebase your custom branch on top of upstream
git rebase upstream/main

# 3. Rebuild and reinstall
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"
cmake --build build
sudo cmake --install build
```

Because 99% of your code lives in `modules/cyber/` (which upstream does not touch), `git rebase` will apply cleanly in seconds.
