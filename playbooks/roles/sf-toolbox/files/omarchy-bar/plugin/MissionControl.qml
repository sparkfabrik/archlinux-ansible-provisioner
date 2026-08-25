import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui

// SparkFabrik Mission Control: a fullscreen overlay answering, in order, what
// is broken or running, what is waiting for the developer, and how the projects
// they actually work on are doing. Projects come from the last 90 days of their
// own GitLab activity, ordered by how often they work on each, and are named
// after the client rather than the repository slug.
// Data comes from `sf-toolbox-status gitlab` (cached).
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property bool loading: false
  property bool loadedOnce: false
  property bool showClosed: false

  property var projects: []
  property var filtered: []
  property var attention: []
  property var closedRecently: []
  property var weeks: []
  property var pipelines: ({})
  property var localProjects: []
  property var totals: ({})
  property var coverage: ({})
  property var myMrs: []

  // Shares the [menu] surface tokens, like the built-in pickers.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property var borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property string fontFamily: Style.font.menuFamily

  property int cardWidth: Math.floor(panel.width * 0.95)
  property int cardHeight: Math.floor(panel.height * 0.93)
  readonly property url logoSource: Qt.resolvedUrl("sparkfabrik-logo.png")

  // SparkFabrik palette as semantic colors: one meaning per hue.
  readonly property color brand: Color.accent          // theme accent (Spark red)
  readonly property color cIssue: "#027aca"            // light blue
  readonly property color cMr: "#40c6cf"               // aquamarine
  readonly property color cReview: "#f7ad2c"           // yellow
  readonly property color cOk: "#68d366"               // lime
  readonly property color cWarn: "#f7ad2c"             // yellow, for running work
  readonly property color cFail: "#eb0000"             // red, dots and borders only
  // Saturated red text on the navy background vibrates and reads badly, so
  // urgent LABELS use the Spark orange while the red stays on dots and borders.
  readonly property color cAlertText: "#f36931"        // orange
  readonly property color cLive: "#40c6cf"             // aquamarine, live states

  readonly property int paneSpacing: Style.space(30)
  readonly property int leftWidth: Math.floor((cardWidth - Style.spacing.panelPadding * 2 - paneSpacing) * 0.62)
  readonly property int rightWidth: cardWidth - Style.spacing.panelPadding * 2 - paneSpacing - leftWidth
  readonly property int columns: Math.max(1, Math.floor(leftWidth / Style.space(400)))
  property int cellWidth: Math.floor(leftWidth / columns)
  property int cellHeight: Style.space(286)

  readonly property var livePipes: (pipelines && pipelines.live) ? pipelines.live : []
  readonly property var brokenPipes: (pipelines && pipelines.broken) ? pipelines.broken : []
  readonly property bool hasPipeNews: livePipes.length > 0 || brokenPipes.length > 0
  readonly property var pipeGroups: (pipelines && pipelines.by_project) ? pipelines.by_project : []

  // Attention split by weight, so the wall of "mentioned" stops hiding the
  // things that actually address the developer.
  readonly property var urgentAttention: {
    var out = []
    for (var i = 0; i < attention.length; i++) {
      var a = attention[i].action
      if (a === "directly_addressed" || a === "review_requested" || a === "assigned" || a === "build_failed")
        out.push(attention[i])
    }
    return out
  }
  readonly property var mentionAttention: {
    var out = []
    for (var i = 0; i < attention.length; i++) {
      var a = attention[i].action
      if (!(a === "directly_addressed" || a === "review_requested" || a === "assigned" || a === "build_failed"))
        out.push(attention[i])
    }
    return out
  }

  // Attention grouped per project: a flat list of thirty rows hides which
  // client each item belongs to.
  readonly property var attentionGroups: {
    var order = []
    var byKey = ({})
    var rows = urgentAttention.concat(mentionAttention)
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i]
      var key = (r.client || "") + "/" + (r.repo || "")
      if (!byKey[key]) {
        byKey[key] = { key: key, client: r.client || "", repo: r.repo || "", items: [] }
        order.push(key)
      }
      byKey[key].items.push(r)
    }
    var out = []
    for (var j = 0; j < order.length; j++) out.push(byKey[order[j]])
    return out
  }

  function countAction(name) {
    var n = 0
    for (var i = 0; i < attention.length; i++) if (attention[i].action === name) n++
    return n
  }

  function open(payloadJson) {
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    root.showClosed = false
    root.load(false)
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() { root.opened = false }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "sparkfabrik.toolbox")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function load(force) {
    if (gitlabProc.running) return
    root.loading = true
    gitlabProc.command = force
      ? ["sf-toolbox-status", "--no-cache", "gitlab"]
      : ["sf-toolbox-status", "gitlab"]
    gitlabProc.running = true
  }

  function rebuild() {
    var needle = root.filterText.toLowerCase()
    var out = []
    for (var i = 0; i < root.projects.length; i++) {
      var p = root.projects[i]
      if (needle === "") { out.push(p); continue }
      var hay = ((p.client || "") + " " + (p.repo || "") + " " + (p.path || "")).toLowerCase()
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

  function localFor(p) {
    if (!p) return null
    var key = (p.repo || "").toLowerCase()
    for (var i = 0; i < root.localProjects.length; i++) {
      var l = root.localProjects[i]
      if ((l.name || "").toLowerCase() === key) return l
    }
    return null
  }

  function openUrl(url) {
    if (!url) return
    root.dismiss()
    Quickshell.execDetached(["xdg-open", url])
  }

  // org.omarchy.terminal is float-ruled by Omarchy itself.
  function openTerminal(p) {
    var l = root.localFor(p)
    if (!l || !l.dir) return
    root.dismiss()
    Quickshell.execDetached(["xdg-terminal-exec", "--app-id=org.omarchy.terminal",
      "--title=" + l.name, "-e", "bash", "-lc", "cd '" + l.dir + "' && exec bash"])
  }

  function openSite(p) {
    var l = root.localFor(p)
    if (!l || !l.hosts || l.hosts.length === 0) return
    root.openUrl("https://" + String(l.hosts[0]).split(":")[0])
  }

  function pipeColor(s) {
    if (s === "success") return root.cOk
    if (s === "failed" || s === "canceled") return root.cFail
    if (s === "running" || s === "pending") return root.cLive
    return Color.muted
  }

  // Text version of the same state: readable on the dark navy surface.
  function pipeTextColor(s) {
    if (s === "success") return root.cOk
    if (s === "failed" || s === "canceled") return root.cAlertText
    if (s === "running" || s === "pending") return root.cLive
    return Qt.alpha(root.foreground, 0.6)
  }

  // A green pipeline is not news: only running and broken ones earn a badge.
  function pipeIsNews(s) {
    return s === "failed" || s === "running" || s === "pending" || s === "canceled"
  }

  function actionLabel(a) {
    if (a === "directly_addressed") return "replied to you"
    if (a === "review_requested") return "review requested"
    if (a === "assigned") return "assigned to you"
    if (a === "build_failed") return "build failed"
    if (a === "mentioned") return "mentioned"
    return a || ""
  }

  function actionColor(a) {
    if (a === "directly_addressed" || a === "review_requested" || a === "build_failed") return root.cAlertText
    if (a === "assigned") return root.cReview
    return Qt.alpha(root.foreground, 0.5)
  }

  function ago(iso) {
    if (!iso) return ""
    var then = new Date(iso).getTime()
    if (isNaN(then)) return ""
    var mins = Math.floor((Date.now() - then) / 60000)
    if (mins < 1) return "now"
    if (mins < 60) return mins + "m ago"
    var hours = Math.floor(mins / 60)
    if (hours < 24) return hours + "h ago"
    var days = Math.floor(hours / 24)
    if (days < 30) return days + "d ago"
    return Math.floor(days / 30) + "mo ago"
  }

  Process {
    id: gitlabProc
    stdout: StdioCollector { id: gitlabOut }
    onExited: {
      root.loading = false
      root.loadedOnce = true
      try {
        var d = JSON.parse(gitlabOut.text || "{}")
        root.projects = d.projects || []
        root.attention = d.attention || []
        root.closedRecently = d.closed_recently || []
        root.weeks = (d.activity && d.activity.weeks) || []
        root.pipelines = d.pipelines || {}
        root.localProjects = d.local || []
        root.totals = d.totals || {}
        root.coverage = d.coverage || {}
        root.myMrs = d.my_mrs || []
      } catch (e) {
        root.projects = []
      }
      root.rebuild()
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
            var p = root.selectedProject()
            if (p) root.openUrl(p.url)
            event.accepted = true
          } else if (event.key === Qt.Key_Backspace) {
            root.setFilter(root.filterText.slice(0, -1)); event.accepted = true
          } else if (event.key === Qt.Key_T && event.modifiers === Qt.ControlModifier) {
            root.openTerminal(root.selectedProject()); event.accepted = true
          } else if (event.key === Qt.Key_R && event.modifiers === Qt.ControlModifier) {
            root.load(true); event.accepted = true
          } else if (event.key === Qt.Key_H && event.modifiers === Qt.ControlModifier) {
            root.showClosed = !root.showClosed; event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      // ---------- Content ----------
      Column {
        id: body
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.spacing.md
        visible: root.loadedOnce

        // ---------- Header ----------
        Item {
          id: header
          width: parent.width
          height: Style.space(54)

          Image {
            id: headerLogo
            width: Style.space(32)
            height: Style.space(32)
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
              color: root.brand
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
            spacing: Style.space(14)

            Text {
              visible: root.loading
              text: "refreshing"
              color: root.cWarn
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter

              SequentialAnimation on opacity {
                running: root.loading
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
              }
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
          color: root.brand
          opacity: 0.9
        }

        // ---------- Panes ----------
        Row {
          width: parent.width
          height: parent.height - header.height - Style.space(2) - footer.height - Style.spacing.md * 3
          spacing: root.paneSpacing

          // ===== Left: project cockpits =====
          Column {
            width: root.leftWidth
            height: parent.height
            spacing: Style.space(8)

            Row {
              spacing: Style.space(10)
              SectionTitle { text: "PROJECTS · MOST WORKED" }
              Text {
                // The GitLab event feed truncates, so the window shown is
                // what the data really covers, not what was requested.
                text: {
                  var d = root.coverage.days || 0
                  if (d <= 0) return ""
                  if (d < 14) return "last " + d + " days"
                  return "last " + Math.round(d / 7) + " weeks"
                }
                color: Qt.alpha(root.foreground, 0.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: root.filtered.length + " active"
                color: Qt.alpha(root.foreground, 0.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            GridView {
              id: grid
              width: parent.width
              height: parent.height - Style.space(28) - (mrBand.visible ? mrBand.height + Style.space(10) : 0)
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

                readonly property var localData: root.localFor(modelData)

                Rectangle {
                  readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex
                  anchors.fill: parent
                  anchors.margins: Style.space(6)
                  radius: Style.cornerRadius
                  color: hasCursor ? root.selectedBackground : Qt.alpha(root.foreground, 0.05)
                  border.width: hasCursor ? 2 : 1
                  border.color: hasCursor ? root.brand : Qt.alpha(root.foreground, 0.15)

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onContainsMouseChanged: if (containsMouse) {
                      root.cursorActive = true
                      root.selectedIndex = index
                    }
                  }

                  Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Style.space(15)
                    spacing: Style.space(7)

                    // Client, repo, and the pipeline badge only when it matters
                    Item {
                      width: parent.width
                      implicitHeight: titleCol.implicitHeight

                      Column {
                        id: titleCol
                        anchors.left: parent.left
                        anchors.right: pipeBadge.visible ? pipeBadge.left : parent.right
                        anchors.rightMargin: Style.space(8)
                        spacing: Style.space(1)

                        Text {
                          width: parent.width
                          text: modelData.display_title || modelData.client || "—"
                          color: root.foreground
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.title
                          font.bold: true
                          elide: Text.ElideRight
                        }
                        Text {
                          width: parent.width
                          text: modelData.display_sub || modelData.repo || ""
                          color: Qt.alpha(root.foreground, 0.5)
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.body
                          elide: Text.ElideRight
                        }
                      }

                      Rectangle {
                        id: pipeBadge
                        visible: modelData.pipeline && root.pipeIsNews(modelData.pipeline.status)
                        anchors.right: parent.right
                        anchors.top: parent.top
                        implicitWidth: pipeText.implicitWidth + Style.space(14)
                        height: Style.space(20)
                        radius: height / 2
                        color: Qt.alpha(root.pipeColor(modelData.pipeline ? modelData.pipeline.status : ""), 0.18)
                        border.width: 1
                        border.color: root.pipeColor(modelData.pipeline ? modelData.pipeline.status : "")

                        Text {
                          id: pipeText
                          anchors.centerIn: parent
                          text: modelData.pipeline ? modelData.pipeline.status : ""
                          color: root.pipeTextColor(modelData.pipeline ? modelData.pipeline.status : "")
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                        }

                        SequentialAnimation on opacity {
                          running: pipeBadge.visible && modelData.pipeline
                            && (modelData.pipeline.status === "running" || modelData.pipeline.status === "pending")
                          loops: Animation.Infinite
                          NumberAnimation { to: 0.4; duration: 700 }
                          NumberAnimation { to: 1.0; duration: 700 }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.openUrl(modelData.pipeline ? modelData.pipeline.url : "")
                        }
                      }
                    }

                    // Counters and the activity sparkline on one line
                    Item {
                      width: parent.width
                      implicitHeight: Math.max(counters.implicitHeight, spark.height)

                      Row {
                        id: counters
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(13)
                        Counter { value: modelData.issues_open || 0; label: "issues"; tone: root.cIssue }
                        Counter { value: modelData.mrs_open || 0; label: "MR"; tone: root.cMr }
                        Counter { value: modelData.mrs_to_review || 0; label: "to review"; tone: root.cReview }
                        Counter { value: modelData.replies || 0; label: "replies"; tone: root.cAlertText }
                      }

                      // 12 weeks of the developer's own events on this project
                      Row {
                        id: spark
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: Style.space(30)
                        spacing: 3

                        readonly property int maxN: {
                          var m = 1
                          var arr = modelData.spark || []
                          for (var i = 0; i < arr.length; i++) m = Math.max(m, arr[i] || 0)
                          return m
                        }

                        Repeater {
                          model: modelData.spark || []
                          delegate: Rectangle {
                            required property var modelData
                            width: Style.space(7)
                            height: Math.max(3, Style.space(28) * (modelData || 0) / spark.maxN)
                            radius: 1
                            color: (modelData || 0) > 0 ? root.cLive : Qt.alpha(root.foreground, 0.12)
                            anchors.bottom: parent.bottom
                          }
                        }
                      }
                    }

                    // The work itself: latest issues and merge requests
                    Column {
                      width: parent.width
                      spacing: Style.space(3)

                      Repeater {
                        model: modelData.recent || []
                        delegate: Item {
                          required property var modelData
                          width: parent.width
                          height: Style.space(20)

                          Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Style.space(7)

                            Rectangle {
                              width: Style.space(6)
                              height: Style.space(6)
                              radius: width / 2
                              color: modelData.kind === "mr" ? root.cMr : root.cIssue
                              anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                              text: (modelData.kind === "mr" ? "!" : "#") + modelData.iid
                              color: Qt.alpha(root.foreground, 0.45)
                              font.family: root.fontFamily
                              font.pixelSize: Style.font.caption
                              anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                              width: parent.width - Style.space(70)
                              text: modelData.title || ""
                              color: itemMouse.containsMouse ? root.foreground : Qt.alpha(root.foreground, 0.75)
                              font.family: root.fontFamily
                              font.pixelSize: Style.font.caption
                              elide: Text.ElideRight
                              anchors.verticalCenter: parent.verticalCenter
                            }
                          }

                          MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openUrl(modelData.url)
                          }
                        }
                      }
                    }
                  }

                  // Actions plus local state, always visible at the bottom
                  Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: Style.space(15)
                    spacing: Style.space(14)

                    CardAction {
                      label: "GitLab"
                      onTriggered: root.openUrl(modelData.url)
                    }
                    CardAction {
                      label: "Issues"
                      onTriggered: root.openUrl((modelData.url || "") + "/-/issues")
                    }
                    CardAction {
                      label: "Terminal"
                      visible: localData !== null && (localData.dir || "") !== ""
                      onTriggered: root.openTerminal(modelData)
                    }
                    CardAction {
                      label: "Site"
                      visible: localData !== null && (localData.hosts || []).length > 0
                      onTriggered: root.openSite(modelData)
                    }
                  }

                  Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Style.space(15)
                    spacing: Style.space(10)

                    Text {
                      visible: localData !== null
                      text: localData ? (localData.running + "/" + localData.total + " local") : ""
                      color: (localData && localData.running > 0) ? root.cOk : Qt.alpha(root.foreground, 0.4)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: (modelData.events || 0) + " events · " + root.ago(modelData.last_activity)
                      color: Qt.alpha(root.foreground, 0.4)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
              }
            }

            // ---------- My open merge requests ----------
            Column {
              id: mrBand
              width: parent.width
              spacing: Style.space(4)
              visible: root.myMrs.length > 0

              Rectangle { width: parent.width; height: 1; color: Qt.alpha(root.foreground, 0.15) }

              Row {
                spacing: Style.space(10)
                SectionTitle { text: "MY OPEN MERGE REQUESTS" }
                Text {
                  text: root.myMrs.length + " open"
                  color: Qt.alpha(root.foreground, 0.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Repeater {
                model: root.myMrs.slice(0, 4)
                delegate: Item {
                  required property var modelData
                  width: parent.width
                  height: Style.space(28)

                  Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Style.cornerRadius
                    color: mrMouse.containsMouse ? Qt.alpha(root.foreground, 0.1) : "transparent"
                  }

                  Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Style.space(8)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(9)

                    Rectangle {
                      width: Style.space(7)
                      height: Style.space(7)
                      radius: width / 2
                      color: modelData.draft ? Color.muted : root.cMr
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      visible: modelData.draft
                      text: "draft"
                      color: Qt.alpha(root.foreground, 0.45)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: modelData.title || ""
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideRight
                      width: Math.max(Style.space(120), root.leftWidth - Style.space(340))
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: (modelData.client || "") + " · " + (modelData.repo || "")
                      color: Qt.alpha(root.foreground, 0.45)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: root.ago(modelData.updated)
                      color: Qt.alpha(root.foreground, 0.35)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  MouseArea {
                    id: mrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openUrl(modelData.url)
                  }
                }
              }
            }
          }

          // ===== Right: pipelines, attention, activity =====
          Column {
            width: root.rightWidth
            height: parent.height
            spacing: Style.space(9)

            // Pipelines only when there is something live or broken. A project
            // can have several at once (develop, a branch, an MR).
            Column {
              width: parent.width
              spacing: Style.space(4)
              visible: true

              Row {
                spacing: Style.space(10)
                SectionTitle { text: "PIPELINES" }
                Text {
                  text: root.livePipes.length + " running · "
                    + ((root.pipelines && root.pipelines.broken_recent) || 0) + " failed this week"
                  color: (((root.pipelines && root.pipelines.broken_recent) || 0) > 0)
                    ? root.cAlertText : Qt.alpha(root.foreground, 0.5)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                  text: ((root.pipelines && root.pipelines.green) || 0) + " green"
                    + (((root.pipelines && root.pipelines.broken_old) || 0) > 0
                       ? " · " + root.pipelines.broken_old + " older failed" : "")
                  color: Qt.alpha(root.foreground, 0.35)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Text {
                visible: root.pipeGroups.length === 0
                text: "no pipelines yet"
                color: Qt.alpha(root.foreground, 0.45)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              // Recent runs grouped per project, green and red alike: the
              // history tells more than a failure-only list.
              Repeater {
                model: root.pipeGroups.slice(0, 4)
                delegate: Column {
                  required property var modelData
                  width: parent.width
                  spacing: 0

                  Row {
                    spacing: Style.space(8)
                    Rectangle {
                      width: Style.space(3)
                      height: Style.space(12)
                      color: (modelData.failed || 0) > 0 ? root.cAlertText : Qt.alpha(root.foreground, 0.3)
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: modelData.title || ""
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: modelData.sub || ""
                      color: Qt.alpha(root.foreground, 0.4)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  Repeater {
                    model: modelData.runs
                    delegate: Item {
                      required property var modelData
                      width: parent.width
                      height: Style.space(23)

                      Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Style.cornerRadius
                        color: runMouse.containsMouse ? Qt.alpha(root.foreground, 0.1) : "transparent"
                      }

                      Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Style.space(14)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(8)

                        Rectangle {
                          width: Style.space(7)
                          height: Style.space(7)
                          radius: width / 2
                          color: root.pipeColor(modelData.status)
                          anchors.verticalCenter: parent.verticalCenter

                          SequentialAnimation on opacity {
                            running: modelData.status === "running" || modelData.status === "pending"
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 700 }
                            NumberAnimation { to: 1.0; duration: 700 }
                          }
                        }
                        Text {
                          text: modelData.status || ""
                          color: root.pipeTextColor(modelData.status)
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          width: Style.space(58)
                          anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                          text: modelData.ref || ""
                          color: Qt.alpha(root.foreground, 0.8)
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          elide: Text.ElideMiddle
                          width: Style.space(210)
                          anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                          text: root.ago(modelData.updated)
                          color: Qt.alpha(root.foreground, 0.35)
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          anchors.verticalCenter: parent.verticalCenter
                        }
                      }

                      MouseArea {
                        id: runMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openUrl(modelData.url)
                      }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: 1; color: Qt.alpha(root.foreground, 0.15) }
            }

            // Needs you, with the counts up front and mentions dimmed
            Row {
              spacing: Style.space(12)
              SectionTitle { text: "NEEDS YOU" }
              Text {
                text: root.countAction("directly_addressed") + " replied · "
                  + root.countAction("assigned") + " assigned · "
                  + root.countAction("review_requested") + " review"
                color: root.urgentAttention.length > 0 ? root.cAlertText : Qt.alpha(root.foreground, 0.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: root.mentionAttention.length + " mentions"
                color: Qt.alpha(root.foreground, 0.35)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            ListView {
              width: parent.width
              height: parent.height - Style.space(230)
                - (root.showClosed ? Style.space(160) : 0)
              model: root.attentionGroups
              clip: true
              spacing: Style.space(6)
              boundsBehavior: Flickable.StopAtBounds

              delegate: Column {
                required property var modelData
                width: ListView.view.width
                spacing: 0

                // Group header: which client project these rows belong to.
                Row {
                  spacing: Style.space(8)
                  Rectangle {
                    width: Style.space(3)
                    height: Style.space(13)
                    color: root.brand
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: modelData.client || ""
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: modelData.repo || ""
                    color: Qt.alpha(root.foreground, 0.45)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: modelData.items.length + ""
                    color: Qt.alpha(root.foreground, 0.35)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Repeater {
                  model: modelData.items
                  delegate: AttentionRow {
                    required property var modelData
                    width: parent.width
                    item: modelData
                    closed: false
                    grouped: true
                  }
                }
              }
            }

            Row {
              spacing: Style.space(10)
              SectionTitle { text: "CLOSED RECENTLY" }
              Text {
                text: (root.totals.todos_closed || 0) + " done"
                color: Qt.alpha(root.foreground, 0.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
              MouseArea {
                width: Style.space(40)
                height: Style.space(16)
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showClosed = !root.showClosed
                Text {
                  anchors.centerIn: parent
                  text: root.showClosed ? "hide" : "show"
                  color: Qt.alpha(root.foreground, 0.55)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.underline: true
                }
              }
            }

            ListView {
              visible: root.showClosed
              width: parent.width
              height: root.showClosed ? Style.space(150) : 0
              model: root.closedRecently
              clip: true
              spacing: 0
              boundsBehavior: Flickable.StopAtBounds
              delegate: AttentionRow {
                required property var modelData
                width: ListView.view.width
                item: modelData
                closed: true
              }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.alpha(root.foreground, 0.15) }

            // Weekly activity: 12 bars, labels every other bar, no crowding
            Row {
              spacing: Style.space(10)
              SectionTitle { text: "YOUR ACTIVITY · 6 WEEKS" }
              Text {
                text: (root.totals.events || 0) + " events"
                color: Qt.alpha(root.foreground, 0.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Item {
              width: parent.width
              height: Style.space(72)

              readonly property int maxN: {
                var m = 1
                for (var i = 0; i < root.weeks.length; i++) m = Math.max(m, root.weeks[i].n || 0)
                return m
              }

              Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: Style.space(6)

                Repeater {
                  model: root.weeks
                  delegate: Column {
                    required property int index
                    required property var modelData
                    width: Style.space(54)
                    spacing: Style.space(3)

                    Text {
                      text: (modelData.n || 0) > 0 ? modelData.n : ""
                      color: Qt.alpha(root.foreground, 0.55)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                      width: Style.space(34)
                      height: Math.max(2, Style.space(34) * (modelData.n || 0) / parent.parent.parent.maxN)
                      radius: 2
                      color: index === root.weeks.length - 1 ? root.cLive : Qt.alpha(root.cLive, 0.5)
                      anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                      text: modelData.label || ""
                      color: Qt.alpha(root.foreground, 0.35)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.horizontalCenter: parent.horizontalCenter
                    }
                  }
                }
              }
            }
          }
        }

        // ---------- Footer ----------
        Item {
          id: footer
          width: parent.width
          height: Style.space(24)

          Text {
            anchors.centerIn: parent
            text: "Enter  open project      Ctrl+T  terminal      Ctrl+H  closed items      Ctrl+R  refresh      Esc  close"
            color: Qt.alpha(root.foreground, 0.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      // ---------- First load ----------
      Column {
        anchors.centerIn: parent
        spacing: Style.space(18)
        visible: !root.loadedOnce

        Image {
          width: Style.space(64)
          height: Style.space(64)
          source: root.logoSource
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          anchors.horizontalCenter: parent.horizontalCenter

          SequentialAnimation on opacity {
            running: !root.loadedOnce
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 750; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
          }
        }
        Text {
          text: "Loading your GitLab work"
          color: Qt.alpha(root.foreground, 0.7)
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          anchors.horizontalCenter: parent.horizontalCenter
        }
        Rectangle {
          width: Style.space(220)
          height: Style.space(3)
          radius: 2
          color: Qt.alpha(root.foreground, 0.12)
          anchors.horizontalCenter: parent.horizontalCenter

          Rectangle {
            width: Style.space(70)
            height: parent.height
            radius: 2
            color: root.brand

            SequentialAnimation on x {
              running: !root.loadedOnce
              loops: Animation.Infinite
              NumberAnimation { from: 0; to: Style.space(150); duration: 900; easing.type: Easing.InOutQuad }
              NumberAnimation { from: Style.space(150); to: 0; duration: 900; easing.type: Easing.InOutQuad }
            }
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

  component Counter: Row {
    id: counter
    property int value: 0
    property string label: ""
    property color tone: root.foreground
    spacing: Style.space(4)
    visible: value > 0

    Text {
      text: counter.value
      color: counter.tone
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      text: counter.label
      color: Qt.alpha(root.foreground, 0.45)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  component CardAction: Item {
    id: ca
    property string label: ""
    signal triggered()
    implicitWidth: caText.implicitWidth
    implicitHeight: Style.space(18)

    Text {
      id: caText
      anchors.verticalCenter: parent.verticalCenter
      text: ca.label
      color: caMouse.containsMouse ? root.brand : Qt.alpha(root.foreground, 0.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.underline: caMouse.containsMouse
    }
    MouseArea {
      id: caMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: ca.triggered()
    }
  }

  component AttentionRow: Item {
    id: arow
    property var item: ({})
    property bool closed: false
    // Inside a project group the client/repo label would repeat on every row.
    property bool grouped: false
    height: arow.grouped ? Style.space(42) : Style.space(50)
    // Mentions carry less weight than something addressed to you.
    opacity: arow.closed ? 0.6
      : ((arow.item.action === "mentioned") ? 0.72 : 1.0)

    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: Style.cornerRadius
      color: arowMouse.containsMouse ? Qt.alpha(root.foreground, 0.1) : "transparent"
    }

    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: arow.item.title || ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.strikeout: arow.closed
        elide: Text.ElideRight
      }
      Row {
        spacing: Style.space(8)

        Text {
          text: arow.closed
            ? (arow.item.state === "merged" ? "merged" : "closed")
            : root.actionLabel(arow.item.action)
          color: arow.closed ? Qt.alpha(root.foreground, 0.4) : root.actionColor(arow.item.action)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          visible: !arow.grouped
          text: (arow.item.client || "") + " · " + (arow.item.repo || "")
          color: Qt.alpha(root.foreground, 0.5)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          text: (arow.item.ref || "").indexOf("#") >= 0 ? "#" + (arow.item.ref || "").split("#")[1] : ""
          color: Qt.alpha(root.foreground, 0.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          text: root.ago(arow.item.updated)
          color: Qt.alpha(root.foreground, 0.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          visible: (arow.item.notes || 0) > 0
          text: arow.item.notes + " comments"
          color: Qt.alpha(root.foreground, 0.35)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    MouseArea {
      id: arowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.openUrl(arow.item.url)
    }
  }
}
