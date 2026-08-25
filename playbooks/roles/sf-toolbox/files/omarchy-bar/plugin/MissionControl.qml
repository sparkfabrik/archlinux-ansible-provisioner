import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui

// SparkFabrik Mission Control: a fullscreen overlay in the style of the
// Omarchy pickers. Left: the developer's local Docker/compose projects as
// cards (type to filter, arrows to move, Enter opens the site, Ctrl+T opens a
// floating terminal in the project). Right: system status at a glance and the
// developer's open merge requests on the company GitLab.
// Data comes from `sf-toolbox-status projects|mrs|--json`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property var projects: []
  property var filtered: []
  property var mrs: []
  property var status: ({})

  // Shares the [menu] surface tokens, like the built-in pickers.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property var borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property string fontFamily: Style.font.menuFamily

  // Capped size: on an ultrawide the overlay must stay a centered window,
  // not a full-bleed sheet.
  property int cardWidth: Math.min(Style.space(1150), Math.floor(panel.width * 0.75))
  property int cardHeight: Math.min(Style.space(700), Math.floor(panel.height * 0.85))
  readonly property url logoSource: Qt.resolvedUrl("sparkfabrik-logo.png")
  readonly property color sparkRed: "#eb0000"
  readonly property color okGreen: "#5fbf6e"

  readonly property int paneSpacing: Style.space(24)
  readonly property int leftWidth: Math.floor((cardWidth - Style.spacing.panelPadding * 2 - paneSpacing) * 0.60)
  readonly property int rightWidth: cardWidth - Style.spacing.panelPadding * 2 - paneSpacing - leftWidth
  readonly property int columns: Math.max(1, Math.floor(leftWidth / Style.space(300)))
  property int cellWidth: Math.floor(leftWidth / columns)
  property int cellHeight: Style.space(128)

  function open(payloadJson) {
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    if (!projectsProc.running) projectsProc.running = true
    if (!mrsProc.running) mrsProc.running = true
    if (!sysProc.running) sysProc.running = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "sparkfabrik.toolbox")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function rebuild() {
    var needle = root.filterText.toLowerCase()
    var out = []
    for (var i = 0; i < root.projects.length; i++) {
      var p = root.projects[i]
      if (needle === "") { out.push(p); continue }
      var hay = (p.name + " " + (p.branch || "") + " " + (p.hosts || []).join(" ")).toLowerCase()
      if (hay.indexOf(needle) !== -1) out.push(p)
    }
    root.filtered = out
    if (root.selectedIndex >= out.length) root.selectedIndex = Math.max(0, out.length - 1)
  }

  function setFilter(next) {
    root.filterText = next
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuild()
  }

  function move(delta) {
    if (root.filtered.length === 0) return
    root.cursorActive = true
    root.selectedIndex = (root.selectedIndex + delta + root.filtered.length) % root.filtered.length
    grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
  }

  function selectedProject() {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.filtered.length) return null
    return root.filtered[root.selectedIndex]
  }

  function openSite(p) {
    if (!p) return
    if (p.hosts && p.hosts.length > 0) {
      root.dismiss()
      // Strip an explicit port marker: the proxy serves the plain host.
      var host = String(p.hosts[0]).split(":")[0]
      Quickshell.execDetached(["xdg-open", "https://" + host])
    } else {
      root.openTerminal(p)
    }
  }

  // org.omarchy.terminal is float-ruled by Omarchy itself, so the terminal
  // opens as a centered floating window with zero window-rule setup.
  function openTerminal(p) {
    if (!p || !p.dir) return
    root.dismiss()
    Quickshell.execDetached(["xdg-terminal-exec", "--app-id=org.omarchy.terminal",
      "--title=" + p.name, "-e", "bash", "-lc", "cd '" + p.dir + "' && exec bash"])
  }

  function hostGlyph(host) {
    var h = String(host).toLowerCase()
    if (h.indexOf("mysql") !== -1 || h.indexOf("db") === 0 || h.indexOf("postgres") !== -1
        || h.indexOf("typesense") !== -1 || h.indexOf("minio") !== -1) return "󰋊"
    return "󰖟"
  }

  function stateColor(state) {
    if (state === "stale" || state === "stopped" || state === "none") return Color.urgent
    if (state === "fresh" || state === "running" || state === "ok") return root.okGreen
    return Color.muted
  }

  Process {
    id: projectsProc
    command: ["sf-toolbox-status", "projects"]
    stdout: StdioCollector { id: projectsOut }
    onExited: {
      try {
        var data = JSON.parse(projectsOut.text || "{}")
        root.projects = data.projects || []
      } catch (e) {
        root.projects = []
      }
      root.rebuild()
    }
  }

  Process {
    id: mrsProc
    command: ["sf-toolbox-status", "mrs"]
    stdout: StdioCollector { id: mrsOut }
    onExited: {
      try {
        var data = JSON.parse(mrsOut.text || "{}")
        root.mrs = data.mrs || []
      } catch (e) {
        root.mrs = []
      }
    }
  }

  Process {
    id: sysProc
    command: ["sf-toolbox-status", "--offline", "--json"]
    stdout: StdioCollector { id: sysOut }
    onExited: {
      try { root.status = JSON.parse(sysOut.text || "{}") }
      catch (e) { root.status = {} }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "sparkfabrik-mission-control"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill: parent; color: root.scrim }

    MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: Style.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: Style.spacing.panelPadding

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.dismiss()
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.move(-1); event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.move(1); event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.move(-root.columns); event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.move(root.columns); event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.openSite(root.selectedProject()); event.accepted = true
          } else if (event.key === Qt.Key_Backspace) {
            root.setFilter(root.filterText.slice(0, -1)); event.accepted = true
          } else if ((event.key === Qt.Key_T) && event.modifiers === Qt.ControlModifier) {
            root.openTerminal(root.selectedProject()); event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.spacing.md

        // Branded header: Spark logo, wordmark, live search on the right,
        // a Spark-red accent rule underneath.
        Item {
          id: header
          width: parent.width
          height: Style.space(52)

          Image {
            id: headerLogo
            width: Style.space(30)
            height: Style.space(30)
            source: root.logoSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.left: headerLogo.right
            anchors.leftMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(1)

            Text {
              text: "SPARKFABRIK"
              color: root.sparkRed
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 3
            }
            Text {
              text: "Mission Control"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: "󰍉"
              color: Qt.alpha(root.foreground, root.filterText !== "" ? 0.9 : 0.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: root.filterText !== "" ? root.filterText : "type to filter…"
              color: root.foreground
              opacity: root.filterText !== "" ? 1 : 0.45
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        Rectangle {
          width: parent.width
          height: Math.max(2, Style.space(2))
          color: root.sparkRed
          opacity: 0.9
        }

        // ---------- Two panes ----------
        Row {
          width: parent.width
          height: parent.height - header.height - Style.space(2) - footer.height - Style.spacing.md * 3
          spacing: root.paneSpacing

          // Left: project cards
          Column {
            width: root.leftWidth
            height: parent.height
            spacing: Style.space(8)

            SectionTitle { text: "PROJECTS" }

            Item {
              width: parent.width
              height: parent.height - Style.space(28)

              GridView {
                id: grid
                anchors.fill: parent
                model: root.filtered
                clip: true
                cellWidth: root.cellWidth
                cellHeight: root.cellHeight
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                  required property int index
                  required property var modelData
                  width: grid.cellWidth
                  height: grid.cellHeight

                  Rectangle {
                    readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex
                    anchors.fill: parent
                    anchors.margins: Style.space(6)
                    radius: Style.cornerRadius
                    color: hasCursor ? root.selectedBackground : Qt.alpha(root.foreground, 0.05)
                    border.width: hasCursor ? 2 : 1
                    border.color: hasCursor ? root.sparkRed : Qt.alpha(root.foreground, 0.15)

                    Column {
                      anchors.fill: parent
                      anchors.margins: Style.space(14)
                      spacing: Style.space(5)

                      Row {
                        spacing: Style.space(8)
                        Rectangle {
                          width: Style.space(10)
                          height: Style.space(10)
                          radius: width / 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: modelData.running > 0
                            ? (modelData.running === modelData.total ? root.okGreen : Color.urgent)
                            : Color.muted
                        }
                        Text {
                          text: modelData.name
                          color: root.foreground
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.title
                          font.bold: true
                          elide: Text.ElideRight
                        }
                      }

                      Row {
                        spacing: Style.space(12)
                        Text {
                          visible: (modelData.branch || "") !== ""
                          text: "󰘬 " + modelData.branch
                          color: Qt.alpha(root.foreground, 0.7)
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                        }
                        Row {
                          spacing: Style.space(6)
                          anchors.verticalCenter: parent.verticalCenter
                          Text {
                            text: "󰡨"
                            color: Qt.alpha(root.foreground, 0.7)
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            anchors.verticalCenter: parent.verticalCenter
                          }
                          // Mini fill bar: running containers over total.
                          Rectangle {
                            width: Style.space(52)
                            height: Style.space(5)
                            radius: height / 2
                            color: Qt.alpha(root.foreground, 0.15)
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                              width: modelData.total > 0 ? parent.width * modelData.running / modelData.total : 0
                              height: parent.height
                              radius: height / 2
                              color: modelData.running > 0 ? root.okGreen : "transparent"
                            }
                          }
                          Text {
                            text: modelData.running + "/" + modelData.total
                            color: Qt.alpha(root.foreground, 0.7)
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            anchors.verticalCenter: parent.verticalCenter
                          }
                        }
                      }

                      Text {
                        width: parent.width
                        visible: (modelData.hosts || []).length > 0
                        text: (modelData.hosts || []).length > 0
                          ? root.hostGlyph(modelData.hosts[0]) + " " + modelData.hosts[0]
                            + ((modelData.hosts.length > 1) ? "  (+" + (modelData.hosts.length - 1) + ")" : "")
                          : ""
                        color: Qt.alpha(root.foreground, 0.55)
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideMiddle
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onContainsMouseChanged: if (containsMouse) {
                        root.cursorActive = true
                        root.selectedIndex = index
                      }
                      onClicked: {
                        root.selectedIndex = index
                        root.openSite(modelData)
                      }
                    }
                  }
                }
              }

              Column {
                anchors.centerIn: parent
                spacing: Style.space(14)
                visible: root.filtered.length === 0

                Image {
                  width: Style.space(56)
                  height: Style.space(56)
                  source: root.logoSource
                  fillMode: Image.PreserveAspectFit
                  smooth: true
                  mipmap: true
                  opacity: 0.35
                  anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                  text: root.projects.length === 0
                    ? "No local projects running"
                    : "No matches for “" + root.filterText + "”"
                  color: root.foreground
                  opacity: 0.7
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                  horizontalAlignment: Text.AlignHCenter
                  width: root.leftWidth - Style.space(40)
                  wrapMode: Text.WordWrap
                }
              }
            }
          }

          // Right: system status + merge requests
          Column {
            width: root.rightWidth
            height: parent.height
            spacing: Style.space(10)

            SectionTitle { text: "SYSTEM" }

            Grid {
              columns: 2
              columnSpacing: Style.space(18)
              rowSpacing: Style.space(8)

              MiniStatus { glyph: ""; label: "Toolbox"; state: root.status.toolbox ? root.status.toolbox.state : "" }
              MiniStatus { glyph: ""; label: "Sparkdock"; state: root.status.sparkdock ? root.status.sparkdock.state : "" }
              MiniStatus { glyph: "󰚩"; label: "Agents"; state: root.status.agents ? root.status.agents.state : "" }
              MiniStatus {
                glyph: "󰏖"
                label: {
                  var p = root.status.packages
                  var n = p ? (p.repo || 0) + (p.aur || 0) : 0
                  return n > 0 ? "Packages (" + n + ")" : "Packages"
                }
                state: root.status.packages ? root.status.packages.state : ""
              }
              MiniStatus {
                glyph: "󰖟"; label: "Proxy"
                state: root.status.http_proxy
                  ? (root.status.http_proxy.running === false ? "stopped" : "running") : ""
              }
              MiniStatus { glyph: "󰡨"; label: "Docker"; state: root.status.docker ? root.status.docker.state : "" }
            }

            Rectangle {
              width: parent.width
              height: 1
              color: Qt.alpha(root.foreground, 0.15)
            }

            SectionTitle { text: "MY MERGE REQUESTS" }

            Column {
              width: parent.width
              spacing: Style.space(4)

              Repeater {
                model: root.mrs
                delegate: Item {
                  required property var modelData
                  width: parent.width
                  implicitHeight: Style.space(44)

                  Rectangle {
                    anchors.fill: parent
                    radius: Style.cornerRadius
                    color: mrMouse.containsMouse ? Qt.alpha(root.foreground, 0.1) : "transparent"
                  }

                  Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Style.space(6)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(2)

                    Text {
                      width: parent.width
                      text: (modelData.draft ? "[draft] " : "") + modelData.title
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      elide: Text.ElideRight
                    }
                    Text {
                      width: parent.width
                      text: modelData.ref
                      color: Qt.alpha(root.foreground, 0.5)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideMiddle
                    }
                  }

                  MouseArea {
                    id: mrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.dismiss()
                      Quickshell.execDetached(["xdg-open", modelData.url])
                    }
                  }
                }
              }

              Text {
                visible: root.mrs.length === 0
                text: "No open merge requests"
                color: Qt.alpha(root.foreground, 0.45)
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }
          }
        }

        // Footer: keyboard hints, centered.
        Item {
          id: footer
          width: parent.width
          height: Style.space(24)

          Text {
            anchors.centerIn: parent
            text: "Enter  open site      Ctrl+T  terminal in project      Esc  close"
            color: Qt.alpha(root.foreground, 0.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }

  // --- inline components -----------------------------------------------------

  component SectionTitle: Text {
    color: Qt.alpha(root.foreground, 0.55)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 2
  }

  component MiniStatus: Row {
    id: mini
    property string glyph: ""
    property string label: ""
    property string state: ""
    spacing: Style.space(7)
    visible: state !== ""

    Rectangle {
      width: Style.space(9)
      height: Style.space(9)
      radius: width / 2
      color: root.stateColor(mini.state)
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      text: mini.glyph
      color: Qt.alpha(root.foreground, 0.75)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      text: mini.label
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
