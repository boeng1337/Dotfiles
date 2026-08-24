import Quickshell
import Quickshell.Io
import QtQuick
import "test"
import "pill"
import "control_panel"

PanelWindow {
	Region {
		id: pillRegion
		Region { item: pill }
		Region { item: lcorner; intersection: Intersection.Combine }
		Region { item: rcorner; intersection: Intersection.Combine }
	}
	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: 500
	exclusiveZone: 30
	color: "transparent"

	// mask only when collapsed; panel/settings are click-through as needed
	mask: pill.isCollapsed ? pillRegion : null

	Corner {
		id: lcorner
		side: "left"
		x: pill.x - 12
		y: 0
		visible: pill.isCollapsed   // corners only make sense in collapsed state
	}
	Corner {
		id: rcorner
		side: "right"
		x: pill.x + pill.width
		y: 0
		visible: pill.isCollapsed
	}

	Rectangle {
		id: pill
		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter

		// ─── State: one string, three possible values ────────
		property string uiState: "collapsed"
		readonly property bool isCollapsed: uiState === "collapsed"
		readonly property bool isPanel:     uiState === "panel"
		readonly property bool isSettings:  uiState === "settings"

		// ─── Size varies by state ────────────────────────────
		// Chain of ternaries: check settings first, then panel, else collapsed.
		width:  isSettings ? 500
		      : isPanel    ? 400
		      : (clock.implicitWidth + workspaces.implicitWidth + 30)

		height: isSettings ? 400
		      : isPanel    ? 300
		      : 30

		topLeftRadius: 0
		topRightRadius: 0
		bottomLeftRadius:  isCollapsed ? height / 2 : 20
		bottomRightRadius: isCollapsed ? height / 2 : 20
		color: "#313244"

		Behavior on width  { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
		Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
		Behavior on bottomLeftRadius  { NumberAnimation { duration: 250; easing.type: Easing.Linear } }
		Behavior on bottomRightRadius { NumberAnimation { duration: 250; easing.type: Easing.Linear } }

		// ─── COLLAPSED state: clock + workspaces row ─────────
		Row {
			anchors.centerIn: parent
			visible: pill.isCollapsed
			spacing: 2
			Workspaces {
				id: workspaces
				anchors.verticalCenter: parent.verticalCenter
		}
		Clock {
			id: clock
			MouseArea {
				anchors.fill: parent
				onClicked: pill.uiState = "panel"
			} 
		}
	}

	// ─── PANEL state: weather + control buttons + gear ──
	Column {
		Row {
			anchors.top: parent.top
			visible: pill.isPanel
			Weather {
				onDateClicked: pill.uiState = "collapsed"   // click date in panel → close
			}
		}
		Row {
			Column {	
				visible: pill.isPanel
				spacing: 6
				Toggle_Buttons {
					id: wifiBtn
					type: "wifi"
				}
				Toggle_Buttons {
					id: btBtn
					type: "bluetooth"
				}
				// gear button — enters settings state
				Text {
					text: "\uf013"
					font.family: "Symbols Nerd Font"
					font.pixelSize: 18
					color: "white"
					anchors.horizontalCenter: parent.horizontalCenter
					MouseArea {
						anchors.fill: parent
						anchors.margins: -6   // easier to click
						onClicked: pill.uiState = "settings"
					}
				}
			}
		}
	}

		// ─── SETTINGS state: skeleton with back arrow and placeholder ──
		Rectangle {
			id: settingsContainer
			anchors.fill: parent
			anchors.margins: 12
			color: "transparent"
			visible: pill.isSettings

			// back arrow — returns to panel state
			Text {
				id: backArrow
				text: "\uf060"
				font.family: "Symbols Nerd Font"
				font.pixelSize: 20
				color: "white"
				anchors.top: parent.top
				anchors.left: parent.left
				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					onClicked: pill.uiState = "panel"
				}
			}

			// placeholder title
			Text {
				anchors.top: parent.top
				anchors.horizontalCenter: parent.horizontalCenter
				text: "Settings"
				color: "white"
				font.pixelSize: 18
				font.bold: true
			}

			// placeholder body — future tab navigation goes here
			Text {
				anchors.centerIn: parent
				text: "Settings skeleton\n(tabs and content coming later)"
				color: "#888888"
				horizontalAlignment: Text.AlignHCenter
			}
		}
	}
}
