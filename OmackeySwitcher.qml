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
  property string switchScope: "all"
  property string scopedAppId: ""

  readonly property int itemWidth: Style.space(146)
  readonly property int itemHeight: Style.space(154)
  readonly property int itemSpacing: Style.spacing.sm
  readonly property int itemStep: itemWidth + itemSpacing
  readonly property int cardPadding: Style.spacing.panelPadding
  readonly property int cardHeaderHeight: Style.space(58)
  readonly property int cardFooterHeight: Style.space(42)
  readonly property int availableGridWidth: Math.max(itemWidth, panel.width - Style.space(64) - cardPadding * 2)
  readonly property int availableGridHeight: Math.max(itemHeight, panel.height - Style.space(64) - cardPadding * 2 - cardHeaderHeight - cardFooterHeight)
  readonly property int maximumColumns: Math.max(1, Math.floor((availableGridWidth + itemSpacing) / itemStep))
  readonly property int maximumRows: Math.max(1, Math.floor((availableGridHeight + itemSpacing) / (itemHeight + itemSpacing)))
  readonly property int columnsNeededToFit: Math.max(1, Math.ceil(apps.length / maximumRows))
  readonly property int gridColumns: Math.min(Math.max(1, apps.length), maximumColumns, Math.max(Math.min(6, Math.max(1, apps.length)), columnsNeededToFit))
  readonly property int gridRows: Math.max(1, Math.ceil(apps.length / gridColumns))
  // GridView derives its column count from complete cell widths. Keep the
  // trailing cell spacing in the viewport or the last item wraps invisibly.
  readonly property int gridWidth: gridColumns * itemStep
  readonly property int gridHeight: gridRows * itemHeight + Math.max(0, gridRows - 1) * itemSpacing
  readonly property int cardWidth: Math.max(Style.space(280), gridWidth + cardPadding * 2)
  readonly property int cardHeight: gridHeight + cardPadding * 2 + cardHeaderHeight + cardFooterHeight
  readonly property int cornerRadius: Math.max(Style.cornerRadius, Style.space(18))

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
      if (root.switchScope === "application" && id !== root.scopedAppId) continue
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

  function moveHorizontal(delta) {
    if (!root.apps.length) return
    var rowStart = Math.floor(root.selectedIndex / root.gridColumns) * root.gridColumns
    var rowEnd = Math.min(rowStart + root.gridColumns, root.apps.length) - 1
    root.selectedIndex = Math.max(rowStart, Math.min(rowEnd, root.selectedIndex + delta))
  }

  function moveLeft() {
    root.moveHorizontal(-1)
  }

  function moveRight() {
    root.moveHorizontal(1)
  }

  function moveVertical(delta) {
    if (!root.apps.length) return
    var column = root.selectedIndex % root.gridColumns
    var targetRow = Math.floor(root.selectedIndex / root.gridColumns) + delta
    targetRow = Math.max(0, Math.min(root.gridRows - 1, targetRow))
    var rowStart = targetRow * root.gridColumns
    var rowEnd = Math.min(rowStart + root.gridColumns, root.apps.length) - 1
    root.selectedIndex = Math.min(rowStart + column, rowEnd)
  }

  function moveUp() {
    root.moveVertical(-1)
  }

  function moveDown() {
    root.moveVertical(1)
  }

  function navigate(action) {
    if (action === "left") root.moveLeft()
    else if (action === "right") root.moveRight()
    else if (action === "up") root.moveUp()
    else if (action === "down") root.moveDown()
    else return false
    return true
  }

  function parsePayload(payloadJson) {
    try {
      var payload = JSON.parse(payloadJson || "{}")
      return {
        action: String(payload.action || "forward"),
        scope: String(payload.scope || "all")
      }
    } catch (error) {
      return { action: "forward", scope: "all" }
    }
  }

  function open(payloadJson) {
    var payload = root.parsePayload(payloadJson)
    var action = payload.action
    if (action === "commit") {
      root.commit()
      return
    }
    if (action === "cancel") {
      root.dismiss(false)
      return
    }

    if (!root.opened) {
      root.switchScope = payload.scope === "application" ? "application" : "all"
      root.scopedAppId = root.switchScope === "application"
        ? root.appIdFor(ToplevelManager.activeToplevel) : ""
      root.rebuildApps()
      if (!root.apps.length) {
        root.dismiss(false)
        return
      }
      root.opened = true
      root.selectedIndex = action === "reverse" ? root.apps.length - 1 : Math.min(1, root.apps.length - 1)
      root.navigate(action)
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    } else {
      if (payload.scope === "application" && root.switchScope !== "application") {
        var selected = root.apps.length ? root.apps[root.selectedIndex].toplevel : ToplevelManager.activeToplevel
        root.switchScope = "application"
        root.scopedAppId = root.appIdFor(selected)
        root.rebuildApps()
        root.selectedIndex = Math.min(1, root.apps.length - 1)
        return
      }
      if (!root.navigate(action)) root.advance(action === "reverse" ? -1 : 1)
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
      color: Util.alpha(Color.menu.scrim, 0.48)
      opacity: root.opened ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    }

    MouseArea {
      anchors.fill: parent
      preventStealing: true
      propagateComposedEvents: false
      onPressed: function(mouse) { mouse.accepted = true }
      onReleased: function(mouse) {
        mouse.accepted = true
        root.dismiss(false)
      }
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(root.cardWidth, panel.width - Style.space(64))
      height: root.cardHeight
      radius: root.cornerRadius
      color: Util.alpha(Color.menu.background, 0.96)
      borderSpec: Border.surfaceSpec("menu", "border", Util.alpha(Color.menu.border, 0.82), Math.max(1, Style.spacing.hairline))
      opacity: root.opened ? 1 : 0
      scale: root.opened ? 1 : 0.97

      Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 165; easing.type: Easing.OutBack } }

      MouseArea {
        anchors.fill: parent
        preventStealing: true
        propagateComposedEvents: false
        onPressed: function(mouse) { mouse.accepted = true }
        onReleased: function(mouse) { mouse.accepted = true }
      }

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
          } else if (event.key === Qt.Key_QuoteLeft || event.key === Qt.Key_AsciiTilde) {
            root.advance(event.modifiers & Qt.ShiftModifier ? -1 : 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.moveLeft()
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.moveRight()
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.moveUp()
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.moveDown()
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

      Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.cardPadding
        anchors.leftMargin: root.cardPadding
        anchors.rightMargin: root.cardPadding
        spacing: Style.spacing.xs

        Text {
          width: parent.width
          text: root.switchScope === "application" ? "APPLICATION WINDOWS" : "WINDOWS"
          textFormat: Text.PlainText
          color: Color.accent
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.caption
          font.weight: Font.Bold
          font.letterSpacing: Style.space(1.2)
        }

        Text {
          width: parent.width
          text: root.apps.length ? root.apps[root.selectedIndex].appName : "No open windows"
          textFormat: Text.PlainText
          color: Color.menu.text
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.title
          font.weight: Font.DemiBold
          elide: Text.ElideRight
        }
      }

      GridView {
        id: appList
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.cardPadding + root.cardHeaderHeight
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
          opacity: selected ? 1 : 0.72

          Behavior on opacity { NumberAnimation { duration: 120 } }

          Rectangle {
            id: selectionPlate
            anchors.fill: parent
            radius: Style.space(14)
            color: appItem.selected ? Util.alpha(Color.accent, 0.16) : "transparent"
            border.width: appItem.selected ? Math.max(1, Style.spacing.hairline) : 0
            border.color: Util.alpha(Color.accent, 0.72)

            Behavior on color { ColorAnimation { duration: 125 } }
            Behavior on border.color { ColorAnimation { duration: 125 } }

            Rectangle {
              visible: appItem.selected
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.leftMargin: Style.space(52)
              anchors.rightMargin: Style.space(52)
              anchors.bottomMargin: Style.space(8)
              height: Style.space(3)
              radius: height / 2
              color: Color.accent
            }
          }

          Column {
            anchors.fill: parent
            anchors.topMargin: Style.space(16)
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            spacing: Style.spacing.sm

            Image {
              width: Style.space(76)
              height: Style.space(76)
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
              text: appItem.modelData.appName
              textFormat: Text.PlainText
              color: appItem.selected ? Color.menu.selectedText : Util.alpha(Color.menu.text, 0.84)
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              font.weight: appItem.selected ? Font.DemiBold : Font.Normal
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              wrapMode: Text.Wrap
              maximumLineCount: 1

              Behavior on color { ColorAnimation { duration: 125 } }
            }

            Text {
              width: parent.width
              text: appItem.modelData.title
              textFormat: Text.PlainText
              color: Util.alpha(Color.menu.text, 0.56)
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              wrapMode: Text.NoWrap
              maximumLineCount: 1
            }
          }

          MouseArea {
            z: 10
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            propagateComposedEvents: false
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = appItem.index
            onPressed: function(mouse) {
              root.selectedIndex = appItem.index
              mouse.accepted = true
            }
            onReleased: function(mouse) {
              mouse.accepted = true
              if (containsMouse) root.commit()
            }
          }
        }
      }

      Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: root.cardPadding
        width: parent.width - root.cardPadding * 2
        text: "Tab or ← ↑ ↓ → to move  ·  Enter to open  ·  Esc to close"
        textFormat: Text.PlainText
        color: Util.alpha(Color.menu.text, 0.58)
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
      }
    }
  }
}
