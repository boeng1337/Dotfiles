import QtQuick
import Quickshell.Io
import "."

// Blue-light (sunsetr) on/off toggle via presets.
//   ON  = apply warm preset   (sunsetr preset night)
//   OFF = return to default    (sunsetr preset default)
//   state read from            (sunsetr preset active)
Rectangle {
	id: st
	Colors { id: colors }

	property bool isOn: false

	radius: 10
	color: colors.surface

	// ON = geo mode (automatic, location-based blue-light)
	Process {
		id: onProc
		command: ["sunsetr", "set", "transition_mode=geo"]
		running: false
	}
	// OFF = forced neutral daylight (no filter)
	Process {
		id: offProc
		command: ["sunsetr", "set", "transition_mode=static", "static_temp=6500"]
		running: false
	}
	// read current mode → on if geo, off if static
	Process {
		id: activeProc
		command: ["sunsetr", "get", "transition_mode"]
		running: false
		stdout: StdioCollector {
			id: activeCollector
			onStreamFinished: {
				var out = activeCollector.text.toLowerCase()
				st.isOn = out.indexOf("geo") !== -1
			}
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: activeProc.running = true
	}

	Row {
		anchors.verticalCenter: parent.verticalCenter
		anchors.left: parent.left
		anchors.leftMargin: 10
		spacing: 10

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: 28; height: 28; radius: 14
			color: st.isOn ? colors.accent : colors.background
			Behavior on color { ColorAnimation { duration: 150 } }
			Text {
				anchors.centerIn: parent
				text: st.isOn ? "\uf186" : "\uf185"   // moon (on) / sun (off)
				font.family: "Symbols Nerd Font"
				font.pixelSize: 14
				color: st.isOn ? colors.background : colors.textDim
			}
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: "Night Light"
			font.pixelSize: 13
			font.bold: true
			color: colors.text
		}
	}

	MouseArea {
		anchors.fill: parent
		onClicked: {
			if (st.isOn) offProc.running = true
			else onProc.running = true
			st.isOn = !st.isOn          // optimistic; poll corrects
			// re-check shortly after the command applies
			recheck.restart()
		}
	}
	Timer { id: recheck; interval: 800; onTriggered: activeProc.running = true }
}
