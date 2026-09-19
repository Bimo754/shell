//
// This file is part of SDDM Sugar Candy.
// A theme for the Simple Display Desktop Manager.
//
// Copyright (C) 2018–2020 Marian Arlt
//
// SDDM Sugar Candy is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or any later version.
//
// You are required to preserve this and any additional legal notices, either
// contained in this file or in other files that you received along with
// SDDM Sugar Candy that refer to the author(s) in accordance with
// sections §4, §5 and specifically §7b of the GNU General Public License.
//
// SDDM Sugar Candy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SDDM Sugar Candy. If not, see <https://www.gnu.org/licenses/>
//

import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import SddmComponents 2.0 as SDDM

RowLayout {
    id: systemButtonsRow
    spacing: 10

    SDDM.TextConstants { id: textConstants }

    property var suspend: ["Suspend", config.TranslateSuspend || textConstants.suspend, sddm.canSuspend]
    property var hibernate: ["Hibernate", config.TranslateHibernate || textConstants.hibernate, sddm.canHibernate]
    property var reboot: ["Reboot", config.TranslateReboot || textConstants.reboot, sddm.canReboot]
    property var shutdown: ["Shutdown", config.TranslateShutdown || textConstants.shutdown, sddm.canPowerOff]

    property var firstButton: repeater.count > 0 ? repeater.itemAt(0) : null

    Repeater {
        id: repeater
        model: [suspend, hibernate, reboot, shutdown]

        RoundButton {
            id: sysBtn
            implicitWidth: 36
            implicitHeight: 36
            display: AbstractButton.IconOnly
            visible: config.ForceHideSystemButtons != "true" && (modelData[2] || (Qt.application.arguments && Qt.application.arguments.indexOf("--test-mode") !== -1))
            hoverEnabled: true

            icon.source: modelData ? Qt.resolvedUrl("../Assets/" + modelData[0] + ".svgz") : ""
            icon.height: 18
            icon.width: 18
            icon.color: hovered || activeFocus ? root.palette.highlight : root.palette.text

            ToolTip.visible: hovered
            ToolTip.delay: 300
            ToolTip.text: modelData[1]

            background: Rectangle {
                radius: width / 2
                color: sysBtn.down ? Qt.rgba(1, 1, 1, 0.25) : sysBtn.hovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0.08, 0.08, 0.12, 0.7)
                border.color: sysBtn.activeFocus || sysBtn.hovered ? root.palette.highlight : Qt.rgba(1, 1, 1, 0.15)
                border.width: sysBtn.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
            onClicked: {
                forceActiveFocus()
                if (index === 0) sddm.suspend()
                else if (index === 1) sddm.hibernate()
                else if (index === 2) sddm.reboot()
                else sddm.powerOff()
            }

            KeyNavigation.left: index > 0 ? repeater.itemAt(index - 1) : null
            KeyNavigation.right: index < repeater.count - 1 ? repeater.itemAt(index + 1) : null
        }
    }
}
