import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// SparkFabrik Toolbox bar widget: at-a-glance freshness of the Spark dev stack
// (toolbox, sparkdock, packages, HTTP proxy, Docker, CLI auth) with one-click
// upgrade actions. All logic lives in the sf-toolbox-status backend; this
// widget only renders its JSON and shells out for actions, mirroring the macOS
// sparkdock menu bar design.
Panel {
  id: root
  moduleName: "sparkfabrik.toolbox"
  ipcTarget: "sparkfabrik.toolbox"

  property var status: ({})
  property bool checking: false
  property bool fullCheck: false

  // The bar sizes each widget from its implicit size; without this the slot
  // collapses to zero width and the icon is invisible.
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property bool hasAttention: {
    var s = root.status
    if (!s || !s.toolbox) return false
    return s.toolbox.state === "stale" || s.sparkdock.state === "stale"
      || s.packages.state === "stale" || s.http_proxy.state === "stale"
      || s.http_proxy.running === false || s.docker.state === "stopped"
  }

  readonly property string summaryText: {
    var s = root.status
    if (root.checking) return "Checking…"
    if (!s || !s.toolbox) return "Status unavailable"
    if (!root.hasAttention) return "Everything up to date"
    var parts = []
    if (s.toolbox.state === "stale") parts.push("toolbox")
    if (s.sparkdock.state === "stale") parts.push("sparkdock")
    if (s.packages.state === "stale") parts.push(s.packages.repo + s.packages.aur + " packages")
    if (s.http_proxy.state === "stale") parts.push("http-proxy")
    if (s.http_proxy.running === false) parts.push("proxy stopped")
    if (s.docker.state === "stopped") parts.push("docker stopped")
    return "Attention: " + parts.join(", ")
  }

  function refresh(full) {
    if (statusProc.running) return
    root.fullCheck = !!full
    root.checking = true
    statusProc.command = full
      ? ["sf-toolbox-status", "--json"]
      : ["sf-toolbox-status", "--offline", "--json"]
    statusProc.running = true
  }

  function runInTerminal(cmd) {
    Quickshell.execDetached(["xdg-terminal-exec", "bash", "-lc",
      cmd + "; echo; read -n1 -s -p 'Done — press any key to close'"])
  }

  function stateColor(state) {
    if (state === "stale" || state === "stopped" || state === "none") return Color.urgent
    if (state === "fresh" || state === "running" || state === "ok") return "#5fbf6e"
    if (state === "error") return Color.urgent
    return Color.muted   // missing / unknown
  }

  function stateLabel(state) {
    if (state === "stale") return "updates available"
    if (state === "fresh") return "up to date"
    if (state === "running") return "running"
    if (state === "stopped") return "stopped"
    if (state === "ok") return "authenticated"
    if (state === "none") return "not logged in"
    if (state === "error") return "check failed"
    return "not installed"
  }

  Process {
    id: statusProc
    stdout: StdioCollector { id: statusOut }
    onExited: {
      root.checking = false
      try { root.status = JSON.parse(statusOut.text || "{}") }
      catch (e) { root.status = {} }
    }
  }

  Component.onCompleted: refresh(false)
  onOpenedChanged: if (opened) refresh(true)

  // Periodic cheap refresh so the icon reflects reality without the popup
  // ever being opened. Offline mode: no git fetch, no network cost.
  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.refresh(false)
  }

  readonly property url logoSource: Qt.resolvedUrl("sparkfabrik-logo.png")

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.hasAttention
    tooltipText: "SparkFabrik Toolbox — " + root.summaryText
    onPressed: function(b) { root.toggle() }

    // The Spark aperture logo, like the macOS sparkdock menu bar. Attention is
    // signalled with a small urgent badge instead of tinting the mark.
    iconComponent: Component {
      Item {
        Image {
          anchors.centerIn: parent
          width: Style.space(15)
          height: Style.space(15)
          source: root.logoSource
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
        }
        Rectangle {
          visible: root.hasAttention
          width: Style.space(6)
          height: Style.space(6)
          radius: width / 2
          color: Color.urgent
          anchors.right: parent.right
          anchors.top: parent.top
        }
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // ---------- Hero ----------
        Item {
          width: parent.width
          // heroIcon.height, not implicitHeight: an Image's implicit size is
          // the source PNG's natural 180px, which would blow up the hero row.
          implicitHeight: Math.max(heroIcon.height, heroLabels.implicitHeight)

          Image {
            id: heroIcon
            width: Style.font.display
            height: Style.font.display
            source: root.logoSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "SparkFabrik Toolbox"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.heading
              font.bold: true
            }
            Text {
              text: root.summaryText
              color: Qt.alpha(root.bar.foreground, 0.7)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        PanelSeparator { width: parent.width }

        // ---------- Updates ----------
        PanelSectionHeader {
          text: "UPDATES"
          foreground: root.bar.foreground
        }

        StatusRow {
          label: "Toolbox"
          state: root.status.toolbox ? root.status.toolbox.state : ""
          actionLabel: "Upgrade"
          actionVisible: state === "stale"
          onActionTriggered: root.runInTerminal("sf-toolbox")
        }
        StatusRow {
          label: "Sparkdock"
          state: root.status.sparkdock ? root.status.sparkdock.state : ""
          actionLabel: "Upgrade"
          actionVisible: state === "stale"
          onActionTriggered: root.runInTerminal("ajust sparkdock-fetch-updates")
        }
        StatusRow {
          label: "System packages"
          state: root.status.packages ? root.status.packages.state : ""
          detail: {
            var p = root.status.packages
            if (!p || p.state !== "stale") return ""
            var n = (p.repo || 0) + (p.aur || 0)
            return n + " pending"
          }
          actionLabel: "Update"
          actionVisible: state === "stale"
          onActionTriggered: root.runInTerminal("omarchy-update")
        }

        PanelSeparator { width: parent.width }

        // ---------- Services ----------
        PanelSectionHeader {
          text: "SERVICES"
          foreground: root.bar.foreground
        }

        StatusRow {
          label: "HTTP proxy"
          state: {
            var p = root.status.http_proxy
            if (!p) return ""
            if (p.state === "missing") return "missing"
            if (p.running === false) return "stopped"
            if (p.state === "stale") return "stale"
            return "running"
          }
          detail: root.status.http_proxy && root.status.http_proxy.state === "stale" ? "update available" : ""
          actionLabel: {
            var p = root.status.http_proxy
            if (!p) return ""
            if (p.running === false) return "Start"
            if (p.state === "stale") return "Update"
            return "Dashboard"
          }
          actionVisible: state !== "" && state !== "missing"
          onActionTriggered: {
            var p = root.status.http_proxy
            if (p.running === false) root.runInTerminal("spark-http-proxy start")
            else if (p.state === "stale") root.runInTerminal("spark-http-proxy self-update")
            else Quickshell.execDetached(["spark-http-proxy", "dashboard"])
          }
        }
        StatusRow {
          label: "Docker"
          state: root.status.docker ? root.status.docker.state : ""
        }

        PanelSeparator { width: parent.width }

        // ---------- Auth ----------
        PanelSectionHeader {
          text: "AUTH"
          foreground: root.bar.foreground
        }

        Row {
          width: parent.width
          spacing: Style.space(16)

          AuthBadge { name: "gcloud"; state: root.status.auth ? root.status.auth.gcloud : "" }
          AuthBadge { name: "glab"; state: root.status.auth ? root.status.auth.glab : "" }
          AuthBadge { name: "gh"; state: root.status.auth ? root.status.auth.gh : "" }
        }

        PanelSeparator { width: parent.width }

        // ---------- Links ----------
        Row {
          width: parent.width
          spacing: Style.space(10)

          ActionButton {
            label: "Playbook"
            onTriggered: Quickshell.execDetached(["xdg-open", "https://playbook.sparkfabrik.com/"])
          }
          ActionButton {
            label: "Refresh"
            onTriggered: root.refresh(true)
          }
        }
      }
    }
  }

  // --- inline components -----------------------------------------------------

  component StatusRow: Item {
    id: row
    property string label: ""
    property string state: ""
    property string detail: ""
    property string actionLabel: ""
    property bool actionVisible: false
    signal actionTriggered()

    width: column.width
    implicitHeight: Math.max(Style.spacing.controlHeight, rowLabel.implicitHeight)
    visible: state !== ""

    Rectangle {
      id: dot
      width: Style.space(10)
      height: Style.space(10)
      radius: width / 2
      color: root.stateColor(row.state)
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: rowLabel
      anchors.left: dot.right
      anchors.leftMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      text: row.label
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      anchors.left: rowLabel.right
      anchors.leftMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      text: row.detail !== "" ? row.detail : root.stateLabel(row.state)
      color: Qt.alpha(root.bar.foreground, 0.55)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
    }

    ActionButton {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      label: row.actionLabel
      visible: row.actionVisible
      onTriggered: row.actionTriggered()
    }
  }

  component AuthBadge: Row {
    id: badge
    property string name: ""
    property string state: ""
    spacing: Style.space(6)
    visible: state !== "" && state !== "missing"

    Rectangle {
      width: Style.space(8)
      height: Style.space(8)
      radius: width / 2
      color: root.stateColor(badge.state)
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      text: badge.name
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  component ActionButton: Rectangle {
    id: ab
    property string label: ""
    signal triggered()
    implicitWidth: abText.implicitWidth + Style.space(20)
    implicitHeight: Math.round(Style.spacing.controlHeight * 0.8)
    radius: Style.cornerRadius
    color: abMouse.containsMouse
      ? Qt.alpha(root.bar.foreground, 0.15)
      : "transparent"
    border.width: 1
    border.color: Qt.alpha(root.bar.foreground, 0.35)

    Text {
      id: abText
      anchors.centerIn: parent
      text: ab.label
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
    }
    MouseArea {
      id: abMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: ab.triggered()
    }
  }
}
