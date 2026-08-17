import Quickshell
import QtQuick
import "."

FloatingWindow {
	id: sw
	Colors { id: colors }
	title: "quickshell-settings"

	property int currentTab: 0
	property var tabs: [
		{ name: "Shortcuts", glyph: "\uf11c" },
		{ name: "Appearance", glyph: "\uf53f" },
		{ name: "System", glyph: "\uf085" },
		{ name: "Display", glyph: "\uf108" },
		{ name: "Network", glyph: "\uf1eb" }
	]

	implicitWidth: 620
	implicitHeight: 420
	color: colors.background

	Rectangle {
		anchors.fill: parent
		color: colors.background
		radius: 16

		Row {
			anchors.fill: parent
			anchors.margins: 12
			spacing: 12

			// LEFT: tabs (25%)
			Rectangle {
				width: (parent.width - 12) * 0.25
				height: parent.height
				radius: 12
				color: colors.surface

				Column {
					anchors.fill: parent
					anchors.margins: 8
					spacing: 4

					Text {
						text: "Settings"
						color: colors.text
						font.pixelSize: 15
						font.bold: true
						bottomPadding: 8
					}

					Repeater {
						model: sw.tabs
						Rectangle {
							width: parent.width
							height: 34
							radius: 8
							color: index === sw.currentTab ? colors.accent : "transparent"
							Behavior on color { ColorAnimation { duration: 120 } }

							Row {
								anchors.verticalCenter: parent.verticalCenter
								anchors.left: parent.left
								anchors.leftMargin: 10
								spacing: 10
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text: modelData.glyph
									font.family: "Symbols Nerd Font"
									font.pixelSize: 13
									color: index === sw.currentTab ? colors.background : colors.textDim
								}
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text: modelData.name
									font.pixelSize: 13
									color: index === sw.currentTab ? colors.background : colors.text
								}
							}
							MouseArea {
								anchors.fill: parent
								onClicked: sw.currentTab = index
							}
						}
					}
				}
			}

			// RIGHT: content (75%)
			Rectangle {
				width: (parent.width - 12) * 0.75
				height: parent.height
				radius: 12
				color: colors.surface

				Text {
					id: sectionTitle
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.margins: 16
					text: sw.tabs[sw.currentTab].name
					color: colors.text
					font.pixelSize: 16
					font.bold: true
				}

				Column {
					visible: sw.tabs[sw.currentTab].name === "Appearance"
					anchors.top: sectionTitle.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.margins: 16
					anchors.topMargin: 12
					spacing: 6

					SliderRow {
						width: parent.width
						label: "Pill width"; from: 100; to: 300
						value: Config.appearance.pillWidth
						onMoved: (v) => Config.appearance.pillWidth = v
					}
					SliderRow {
						width: parent.width
						label: "Pill height"; from: 24; to: 60
						value: Config.appearance.pillHeight
						onMoved: (v) => Config.appearance.pillHeight = v
					}
					SliderRow {
						width: parent.width
						label: "Notch size"; from: 6; to: 30
						value: Config.appearance.notch
						onMoved: (v) => Config.appearance.notch = v
					}
					SliderRow {
						width: parent.width
						label: "Panel width"; from: 360; to: 640
						value: Config.appearance.panelWidth
						onMoved: (v) => Config.appearance.panelWidth = v
					}
					SliderRow {
						width: parent.width
						label: "Corner radius"; from: 0; to: 30
						value: Config.appearance.cornerRadius
						onMoved: (v) => Config.appearance.cornerRadius = v
					}
				}

				Text {
					visible: sw.tabs[sw.currentTab].name !== "Appearance"
					anchors.centerIn: parent
					text: sw.tabs[sw.currentTab].name + " settings\n(coming soon)"
					horizontalAlignment: Text.AlignHCenter
					color: colors.textDim
					font.pixelSize: 13
				}
			}
		}

		Text {
			anchors.top: parent.top
			anchors.right: parent.right
			anchors.margins: 16
			text: "\uf00d"
			font.family: "Symbols Nerd Font"
			font.pixelSize: 15
			color: colors.textDim
			MouseArea {
				anchors.fill: parent
				anchors.margins: -8
				onClicked: sw.visible = false
			}
		}
	}
}
