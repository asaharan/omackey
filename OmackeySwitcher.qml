import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property var apps: []
  property var recentToplevels: []
  property int selectedIndex: 0

  readonly property int itemWidth: Style.space(116)
  readonly property int itemHeight: Style.space(142)
  readonly property int itemSpacing: Style.spacing.md
  readonly property int itemStep: itemWidth + itemSpacing
  readonly property int cardPadding: Style.spacing.panelPadding
  readonly property int gridColumns: Math.min(6, Math.max(1, apps.length))
  readonly property int gridRows: Math.max(1, Math.ceil(apps.length / gridColumns))
  readonly property int gridWidth: gridColumns * itemWidth + Math.max(0, gridColumns - 1) * itemSpacing
  readonly property int gridHeight: gridRows * itemHeight + Math.max(0, gridRows - 1) * itemSpacing
  readonly property int cardWidth: Math.max(Style.space(210), gridWidth + cardPadding * 2)
  readonly property int cardHeight: gridHeight + cardPadding * 2
  readonly property int cornerRadius: Math.max(Style.cornerRadius, Style.space(22))

  function normalizedAppId(value) {
    var id = String(value || "").trim().toLowerCase()
    if (id.slice(-8) === ".desktop") id = id.slice(0, -8)
    return id || "unknown-application"
  }

  function appIdFor(toplevel) {
    if (!toplevel) return "unknown-application"
    return root.normalizedAppId(toplevel.appId || toplevel.title)
  }

  function desktopEntry(appId) {
    var direct = DesktopEntries.byId(appId)
    if (direct) return direct
    var guessed = DesktopEntries.heuristicLookup(appId)
    if (guessed) return guessed

    var values = DesktopEntries.applications.values || []
    var needle = root.normalizedAppId(appId)
    for (var i = 0; i < values.length; i++) {
      var entry = values[i]
      if (root.normalizedAppId(entry.id) === needle
          || root.normalizedAppId(entry.startupClass) === needle)
        return entry
    }
    return null
  }

  function displayName(appId, toplevel, entry) {
    if (entry && entry.name) return String(entry.name)
    var value = String(appId || "Application")
      .replace(/^com\./, "")
      .replace(/[._-]+/g, " ")
      .replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
    return value || String((toplevel && toplevel.title) || "Application")
  }

  function iconSource(entry, appId) {
    var custom = root.customIconSource(appId)
    if (custom) return custom
    var id = root.normalizedAppId(appId)
    if (id.indexOf("chrome-") === 0
        || id.indexOf("chromium-") === 0
        || id.indexOf("x.com") >= 0
        || id.indexOf("chatgpt.com") >= 0) {
      if (root.shell && root.shell.appLibrary)
        return root.shell.appLibrary.iconSource("chromium")
      return Quickshell.iconPath("chromium", true)
    }
    if (root.shell && root.shell.appLibrary) {
      if (entry && entry.icon) return root.shell.appLibrary.iconSource(entry.icon)
      return root.shell.appLibrary.iconSource(appId)
    }
    var themed = Quickshell.iconPath((entry && entry.icon) || appId, true)
    if (themed) return themed
    return Quickshell.iconPath("application-x-executable", true)
  }

  function customIconSource(appId) {
    var id = root.normalizedAppId(appId)
    if (id.indexOf("gnome-control-center") >= 0
        || id.indexOf("org.gnome.settings") >= 0
        || id.indexOf("systemsettings") >= 0
        || id.indexOf("cosmic-settings") >= 0
        || id.indexOf("omarchy-settings") >= 0)
      return Qt.resolvedUrl("assets/icons/settings.svg")
    return ""
  }

  function containsToplevel(values, target) {
    for (var i = 0; i < values.length; i++) if (values[i] === target) return true
    return false
  }

  function rememberToplevel(toplevel) {
    if (!toplevel) return
    var next = [toplevel]
    for (var i = 0; i < root.recentToplevels.length; i++) {
      if (root.recentToplevels[i] !== toplevel) next.push(root.recentToplevels[i])
    }
    root.recentToplevels = next
  }

  function rebuildApps() {
    var values = ToplevelManager.toplevels.values || []
    var ordered = []
    for (var r = 0; r < root.recentToplevels.length; r++) {
      var recent = root.recentToplevels[r]
      if (root.containsToplevel(values, recent)) ordered.push(recent)
    }
    for (var v = 0; v < values.length; v++) {
      if (!root.containsToplevel(ordered, values[v])) ordered.push(values[v])
    }
    root.recentToplevels = ordered.slice()

    var nextApps = []
    for (var n = 0; n < ordered.length; n++) {
      var target = ordered[n]
      var id = root.appIdFor(target)
      var entry = root.desktopEntry(id)
      nextApps.push({
        appId: id,
        appName: root.displayName(id, target, entry),
        title: String(target.title || root.displayName(id, target, entry)),
        icon: root.iconSource(entry, id),
        toplevel: target
      })
    }
    root.apps = nextApps
    if (root.selectedIndex >= nextApps.length) root.selectedIndex = Math.max(0, nextApps.length - 1)
  }

  function advance(delta) {
    if (!root.apps.length) return
    root.selectedIndex = (root.selectedIndex + delta + root.apps.length) % root.apps.length
  }

  function parseAction(payloadJson) {
    try {
      var payload = JSON.parse(payloadJson || "{}")
      return String(payload.action || "forward")
    } catch (error) {
      return "forward"
    }
  }

  function open(payloadJson) {
    var action = root.parseAction(payloadJson)
    if (action === "commit") {
      root.commit()
      return
    }
    if (action === "cancel") {
      root.dismiss(false)
      return
    }

    if (!root.opened) {
      root.rebuildApps()
      if (!root.apps.length) {
        root.dismiss(false)
        return
      }
      root.opened = true
      root.selectedIndex = action === "reverse" ? root.apps.length - 1 : Math.min(1, root.apps.length - 1)
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    } else {
      root.advance(action === "reverse" ? -1 : 1)
    }
  }

  function close() {
    root.opened = false
  }

  function dismiss(activateSelection) {
    var target = activateSelection && root.apps.length ? root.apps[root.selectedIndex].toplevel : null
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "omackey.switcher")

    if (target) {
      if (target.minimized) target.minimized = false
      Qt.callLater(function() { target.activate() })
    }
  }

  function commit() {
    if (!root.opened) {
      if (root.shell && typeof root.shell.hide === "function")
        root.shell.hide((root.manifest && root.manifest.id) || "omackey.switcher")
      return
    }
    root.dismiss(true)
  }

  function cancel() {
    root.dismiss(false)
  }

  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() {
      root.rememberToplevel(ToplevelManager.activeToplevel)
      if (!root.opened) root.rebuildApps()
    }
  }

  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() { root.rebuildApps() }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() { root.rebuildApps() }
  }

  Component.onCompleted: {
    root.rememberToplevel(ToplevelManager.activeToplevel)
    root.rebuildApps()
    if (root.shell && root.shell.appLibrary) root.shell.appLibrary.refreshIcons()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos-application-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.menu.scrim, 0.34)
      opacity: root.opened ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss(false)
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(root.cardWidth, panel.width - Style.space(64))
      height: root.cardHeight
      radius: root.cornerRadius
      color: Util.alpha(Color.menu.background, 0.86)
      borderSpec: Border.surfaceSpec("menu", "border", Util.alpha(Color.menu.border, 0.58), Math.max(1, Style.spacing.hairline))
      opacity: root.opened ? 1 : 0
      scale: root.opened ? 1 : 0.97

      Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 165; easing.type: Easing.OutBack } }

      MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.dismiss(false)
            event.accepted = true
          } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.advance((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.advance(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.advance(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.commit()
            event.accepted = true
          }
        }

        Keys.onReleased: function(event) {
          if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
            root.commit()
            event.accepted = true
          }
        }
      }

      GridView {
        id: appList
        anchors.centerIn: parent
        width: root.gridWidth
        height: root.gridHeight
        cellWidth: root.itemWidth + root.itemSpacing
        cellHeight: root.itemHeight + root.itemSpacing
        model: root.apps
        interactive: false
        clip: false

        delegate: Item {
          id: appItem
          required property int index
          required property var modelData
          readonly property bool selected: index === root.selectedIndex

          width: root.itemWidth
          height: root.itemHeight
          opacity: selected ? 1 : 0.76

          Behavior on opacity { NumberAnimation { duration: 120 } }

          Rectangle {
            id: selectionPlate
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.space(96)
            height: Style.space(96)
            radius: Style.space(23)
            color: appItem.selected ? Util.alpha(Color.accent, 0.22) : "transparent"
            border.width: appItem.selected ? Math.max(1, Style.spacing.hairline) : 0
            border.color: Color.accent

            Behavior on color { ColorAnimation { duration: 125 } }
            Behavior on border.color { ColorAnimation { duration: 125 } }

            Rectangle {
              visible: appItem.selected
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.leftMargin: Style.space(24)
              anchors.rightMargin: Style.space(24)
              anchors.bottomMargin: Style.space(7)
              height: Style.space(3)
              radius: height / 2
              color: Color.accent
            }
          }

          Column {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: Style.spacing.sm

            Image {
              width: Style.space(72)
              height: Style.space(72)
              anchors.topMargin: Style.space(12)
              anchors.horizontalCenter: parent.horizontalCenter
              source: appItem.modelData.icon
              sourceSize.width: width * Screen.devicePixelRatio
              sourceSize.height: height * Screen.devicePixelRatio
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              smooth: true
              mipmap: true
              scale: appItem.selected ? 1 : 0.91

              Behavior on scale { NumberAnimation { duration: 145; easing.type: Easing.OutCubic } }
            }

            Text {
              width: parent.width
              text: appItem.modelData.title
              textFormat: Text.PlainText
              color: appItem.selected ? Color.menu.selectedText : Util.alpha(Color.menu.text, 0.84)
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              font.weight: appItem.selected ? Font.DemiBold : Font.Normal
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              wrapMode: Text.Wrap
              maximumLineCount: 2

              Behavior on color { ColorAnimation { duration: 125 } }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = appItem.index
            onClicked: {
              root.selectedIndex = appItem.index
              root.commit()
            }
          }
        }
      }
    }
  }
}
