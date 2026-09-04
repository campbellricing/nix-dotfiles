pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor // NixOS: pointer over clickable tray icons
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton) {
            modelData.activate();
        } else if (event.button === Qt.MiddleButton) {
            modelData.secondaryActivate();
        } else if (event.button === Qt.RightButton) {
            // NixOS customization: right-click opens the item's own SNI/DBus menu
            // (fcitx5 "Configure", app "Quit", ...). Stock caelestia only calls
            // secondaryActivate() here, which most tray apps silently ignore.
            if (modelData.hasMenu) {
                const win = QsWindow.window;
                const pos = root.mapToItem(win.contentItem, event.x, event.y);
                modelData.display(win, pos.x, pos.y);
            } else {
                modelData.secondaryActivate();
            }
        }
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}
