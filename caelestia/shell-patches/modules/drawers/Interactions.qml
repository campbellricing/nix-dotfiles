import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property ScreenState screenState
    required property Panels panels
    required property Bar.BarWrapper bar
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive

    // NixOS customization: every panel / popout opens on CLICK in its
    // screen-edge trigger zone, never on hover. Closing:
    //   click-outside  -> HyprlandFocusGrab in ContentWindow.qml (this config
    //                     extends it to cover popouts / utilities / clicked OSD)
    //   Escape         -> the popout's own Keys handler; the Keys.onEscapePressed
    //                     below for dashboard / utilities / osd / sidebar
    // The onClicked handler drives opening; the hover branches in
    // onPositionChanged are gated off by these flags — flip one true for hover.
    readonly property bool popoutsOnHover: false
    readonly property bool osdOnHover: false
    readonly property bool utilitiesOnHover: false
    readonly property bool dashboardOnHover: false
    readonly property bool sidebarOnHover: false
    readonly property bool launcherOnHover: false

    // True while the OSD was opened by a deliberate click (so ContentWindow's
    // focus grab covers it). A key-triggered volume/brightness OSD leaves this
    // false so it stays a non-modal transient that fades on its own timer.
    property bool osdClicked

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = root.borderThickness + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = bar.implicitWidth + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        return x < bar.implicitWidth + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panel.x) && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y < Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real, isCorner = false): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y > height - Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y);
    }

    // NixOS: true when (x, y) is over a bar entry that does something on click
    // but has no MouseArea of its own to set the cursor — the clock, the tray
    // column, the status-icon block. (Workspaces / logo set their own cursor;
    // the screen-edge panel triggers are deliberately left with the arrow.)
    function overClickable(x: real, y: real): bool {
        if (x >= bar.implicitWidth)
            return false;
        const e = bar.entryIdAt(y);
        return e === "clock" || e === "tray" || e === "statusIcons";
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        if (event.x < bar.implicitWidth) {
            bar.handleWheel(event.y, event.angleDelta);
        }
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    // NixOS: pointing-hand cursor over any clickable trigger zone.
    cursorShape: (!fullscreen && containsMouse && overClickable(mouseX, mouseY)) ? Qt.PointingHandCursor : Qt.ArrowCursor

    // NixOS: hold keyboard focus while a click-opened panel is up (and nothing
    // that manages its own focus — popout / launcher / session — is), so Escape
    // closes it just like the dashboard.
    focus: !fullscreen && !popouts.hasCurrent && !screenState.launcher && !screenState.session && (screenState.dashboard || screenState.utilities || screenState.osd || screenState.sidebar)
    Keys.onEscapePressed: event => {
        screenState.dashboard = false;
        screenState.utilities = false;
        screenState.osd = false;
        screenState.sidebar = false;
        dashboardShortcutActive = false;
        utilitiesShortcutActive = false;
        osdShortcutActive = false;
        osdClicked = false;
        popouts.hasCurrent = false;
        bar.closeTray();
        event.accepted = true;
    }

    onPressed: event => dragStart = Qt.point(event.x, event.y)

    // NixOS customization: click a screen-edge trigger zone to toggle its panel.
    onClicked: event => {
        if (fullscreen || event.button !== Qt.LeftButton)
            return;

        const x = event.x;
        const y = event.y;

        // Bar status-icon / tray column: click an icon to toggle its popout.
        if (!popoutsOnHover && x < bar.implicitWidth) {
            const prevName = popouts.currentName;
            const wasOpen = popouts.hasCurrent;
            bar.checkPopout(y);
            if (wasOpen && popouts.hasCurrent && popouts.currentName === prevName) {
                popouts.hasCurrent = false;
                bar.closeTray();
            }
            return;
        }

        // Click off the bar (and not on the open popout) closes it.
        if (!popoutsOnHover && popouts.hasCurrent && !inLeftPanel(panels.popoutsWrapper, x, y)) {
            popouts.hasCurrent = false;
            bar.closeTray();
        }

        // Dashboard (top edge). Focus grab handles click-outside / Esc.
        if (!dashboardOnHover && inTopPanel(panels.dashboard, x, y)) {
            const show = !screenState.dashboard;
            dashboardShortcutActive = show;
            screenState.dashboard = show;
            return;
        }

        // Utilities (bottom-right corner) — before launcher (bottom-centre).
        if (!utilitiesOnHover && inBottomPanel(panels.utilities, x, y, true)) {
            const show = !screenState.utilities;
            utilitiesShortcutActive = show;
            screenState.utilities = show;
            return;
        }

        // Launcher (bottom edge). Focus grab handles click-outside / Esc.
        if (!launcherOnHover && inBottomPanel(panels.launcher, x, y)) {
            screenState.launcher = !screenState.launcher;
            return;
        }

        // OSD strip (right edge) — before sidebar, which spans the same edge.
        if (!osdOnHover && inRightPanel(panels.osdWrapper, x, y)) {
            const show = !screenState.osd;
            osdClicked = show;
            osdShortcutActive = show;
            screenState.osd = show;
            root.panels.osd.hovered = show;
            return;
        }

        // Sidebar (right edge, above/below the OSD band). Focus grab closes it.
        if (!sidebarOnHover && inRightPanel(panels.sidebar, x, y)) {
            screenState.sidebar = !screenState.sidebar;
            return;
        }
    }

    onContainsMouseChanged: {
        if (!containsMouse) {
            // NixOS: panels/popouts no longer close on pointer-leave — the
            // focus grab (click-outside / Esc) owns that now. A key-triggered
            // OSD still fades on its own hide-delay timer.
            if (Config.bar.showOnHover)
                bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            root.panels.osd.hovered = inRightPanel(panels.osdWrapper, x, y);
            return;
        }

        // Show bar in non-exclusive mode on hover
        if (!screenState.bar && Config.bar.showOnHover && x < bar.clampedWidth)
            bar.isHovered = true;

        // Show/hide bar on drag
        if (pressed && dragStart.x < bar.clampedWidth) {
            if (dragX > Config.bar.dragThreshold)
                screenState.bar = true;
            else if (dragX < -Config.bar.dragThreshold)
                screenState.bar = false;
        }

        if (panels.sidebar.offsetScale === 1) {
            // Show osd on hover
            const showOsd = osdOnHover && inRightPanel(panels.osdWrapper, x, y);

            if (osdOnHover && !osdShortcutActive) {
                screenState.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (osdOnHover && showOsd) {
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            const showSidebar = pressed && dragStart.x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x);

            // Show sidebar on hover (top-right corner, bounded by notification panel height)
            if (sidebarOnHover && Config.sidebar.showOnHover) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
                const showSidebarHover = x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar)
                    screenState.sidebar = true;
            }

            // Show/hide session on drag
            if (pressed && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    screenState.session = true;
                else if (dragX > Config.session.dragThreshold)
                    screenState.session = false;

                if (showSidebar && panels.session.offsetScale <= 0 && dragX < -Config.sidebar.dragThreshold)
                    screenState.sidebar = true;
            } else if (showSidebar && dragX < -Config.sidebar.dragThreshold) {
                screenState.sidebar = true;
            }
        } else {
            const outOfSidebar = x < width - panels.sidebar.width * (1 - panels.sidebar.offsetScale);
            // Show osd on hover
            const showOsd = osdOnHover && outOfSidebar && inRightPanel(panels.osdWrapper, x, y);

            if (osdOnHover && !osdShortcutActive) {
                screenState.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (osdOnHover && showOsd) {
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            // Show/hide session on drag
            if (pressed && outOfSidebar && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    screenState.session = true;
                else if (dragX > Config.session.dragThreshold)
                    screenState.session = false;
            }

            // Show/hide sidebar on hover
            if (sidebarOnHover && Config.sidebar.showOnHover && !pressed) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
                const showSidebarHover = x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar) {
                    screenState.sidebar = true;
                } else {
                    const inSidebarArea = inRightPanel(panels.sidebar, x, y) || inRightPanel(panels.sessionWrapper, x, y);
                    if (!inSidebarArea)
                        screenState.sidebar = false;
                }
            }

            // Hide sidebar on drag
            if (pressed && inRightPanel(panels.sidebar, dragStart.x, 0) && dragX > Config.sidebar.dragThreshold)
                screenState.sidebar = false;
        }

        // Show launcher on hover, or show/hide on drag if hover is disabled
        if (launcherOnHover && Config.launcher.showOnHover) {
            if (!screenState.launcher && inBottomPanel(panels.launcher, x, y))
                screenState.launcher = true;
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                screenState.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                screenState.launcher = false;
        }

        // Show dashboard on hover
        const showDashboard = dashboardOnHover && Config.dashboard.showOnHover && inTopPanel(panels.dashboard, x, y);

        if (dashboardOnHover && !dashboardShortcutActive) {
            screenState.dashboard = showDashboard;
        } else if (dashboardOnHover && showDashboard) {
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inTopPanel(panels.dashboard, dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                screenState.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                screenState.dashboard = false;
        }

        // Show utilities on hover
        const showUtilities = utilitiesOnHover && inBottomPanel(panels.utilities, x, y, true);

        if (utilitiesOnHover && !utilitiesShortcutActive) {
            screenState.utilities = showUtilities;
        } else if (utilitiesOnHover && showUtilities) {
            utilitiesShortcutActive = false;
        }

        // Show popouts on hover (NixOS: only when popoutsOnHover; the onClicked
        // handler drives them otherwise).
        if (popoutsOnHover) {
            if (x < bar.implicitWidth) {
                bar.checkPopout(y);
            } else if ((!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inLeftPanel(panels.popoutsWrapper, x, y)) {
                popouts.hasCurrent = false;
                bar.closeTray();
            }
        }
    }

    // Keep the *ShortcutActive flags in sync with real visibility so nothing
    // upstream trips over a stale value. Closing is handled by the focus grab.
    Connections {
        function onDashboardChanged() {
            if (!root.screenState.dashboard)
                root.dashboardShortcutActive = false;
        }

        function onOsdChanged() {
            if (!root.screenState.osd) {
                root.osdShortcutActive = false;
                root.osdClicked = false;
                root.panels.osd.hovered = false;
            }
        }

        function onUtilitiesChanged() {
            if (!root.screenState.utilities)
                root.utilitiesShortcutActive = false;
        }

        target: root.screenState
    }
}
