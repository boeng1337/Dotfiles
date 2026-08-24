import QtQuick

Rectangle {
	id: btn
	width: 200
	height: 56
	radius: 12
	color: mouseBody.containsMouse ? "#3b3b52" : "#313244"

	property string type: "wifi"
	property string status: "off"
	property bool isOn: false
	property bool isExpanded: false

	signal iconClicked()
	signal chevronClicked()
	signal bodyClicked()
	signal close()
	signal open ()
	signal enable()
	signal disable()

	readonly property var allStates: ({
		"wifi": {
			"off":          { icon: "󰤮", label: "Wi-Fi",     subtitle: "Off",         color: "#585b70" },
			"connecting":   { icon: "󰤩", label: "Connecting", subtitle: "Please wait", color: "#f9e2af" },
			"connected":    { icon: "󰤨", label: "MyNetwork",  subtitle: "Connected",   color: "#89b4fa" },
			"disconnected": { icon: "󰤯", label: "Wi-Fi",     subtitle: "No signal",   color: "#f38ba8" }
		},
		"bluetooth": {
			"off":       { icon: "󰂲", label: "Bluetooth",  subtitle: "Off",       color: "#585b70" },
			"on":        { icon: "󰂯", label: "Bluetooth",  subtitle: "On",        color: "#89b4fa" },
			"connected": { icon: "󰂱", label: "Headphones", subtitle: "Connected", color: "#89b4fa" }
		},
		"night-mode": {
			"off": { icon: "󱩍", label: "Night mode", color: "#585b70" },
			"on":  { icon: "󱩌", label: "Night mode", color: "#f9e2af" }
		},
		"dnd": {
			"off": { icon: "󰂛", label: "Focus", color: "#585b70" },
			"on":  { icon: "󰂚", label: "Focus", color: "#cba6f7" }
		}
	})

	readonly property var current: allStates[type] ? (allStates[type][status] || {}) : {}
	readonly property string currentIcon:     current.icon     || "?"
	readonly property string currentLabel:    current.label    || ""
	readonly property string currentSubtitle: current.subtitle || ""
	readonly property color  currentColor:    current.color    || "#585b70"

	MouseArea {
		id: mouseBody
		anchors.fill: parent
		hoverEnabled: true
		onClicked: btn.bodyClicked()
	}

	Row {
		id: contentRow
		anchors.left: parent.left
		anchors.right: chevron.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.leftMargin: 12
		anchors.rightMargin: 8
		spacing: 10

		Rectangle {
			id: iconCircle
			width: btn.height - 20
			height: width
			radius: width / 2
			color: btn.currentColor
			anchors.verticalCenter: parent.verticalCenter

			Text {
				anchors.centerIn: parent
				text: btn.currentIcon
				font.family: "Symbols Nerd Font"
				font.pixelSize: iconCircle.width * 0.55
				color: "white"
			}

			MouseArea {
				anchors.fill: parent
				onClicked: btn.iconClicked()
			}
		}

		Column {
			anchors.verticalCenter: parent.verticalCenter
			spacing: 1

			Text {
				text: btn.currentLabel
				color: "white"
				font.pixelSize: 14
				font.bold: true
				visible: text !== ""
			}
			Text {
				text: btn.currentSubtitle
				color: "#a6adc8"
				font.pixelSize: 11
				visible: text !== ""
			}
		}
	}

	Text {
		id: chevron
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		text: "\uf054"
		font.family: "Symbols Nerd Font"
		font.pixelSize: 12
		color: "#a6adc8"
		rotation: btn.isExpanded ? 90 : 0
		Behavior on rotation { NumberAnimation { duration: 200 } }

		MouseArea {
			anchors.fill: parent
			anchors.margins: -8
			onClicked: btn.isExpanded ? btn.close() : btn.open()
		}
	}
}
