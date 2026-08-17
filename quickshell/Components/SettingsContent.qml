import QtQuick
import "."

// Settings UI content (tabs + panels). Emits back/close for the host to morph.
Item {
	id: sc
	Colors { id: colors }

	signal backRequested()
	signal closeRequested()

	property int currentTab: 0
	property var tabs: [
		{ name: "Shortcuts", glyph: "\uf11c" },
		{ name: "Apps", glyph: "\uf5fc" },
		{ name: "Appearance", glyph: "\uf53f" },
		{ name: "System", glyph: "\uf085" },
		{ name: "Display", glyph: "\uf108" },
		{ name: "Network", glyph: "\uf1eb" }
	]

	Row {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 12

		// LEFT tabs 25%
		Rectangle {
			width: (parent.width - 12) * 0.25
			height: parent.height
			radius: 12
			color: colors.surface

			Column {
				anchors.fill: parent
				anchors.margins: 8
				spacing: 4

				Row {
					width: parent.width
					// back arrow → return to control panel
					Text {
						text: "\uf053"
						font.family: "Symbols Nerd Font"
						font.pixelSize: 13
						color: colors.textDim
						MouseArea { anchors.fill: parent; anchors.margins: -6
							onClicked: sc.backRequested() }
					}
					Item { width: 8; height: 1 }
					Text {
						text: "Settings"
						color: colors.text
						font.pixelSize: 15
						font.bold: true
					}
				}
				Item { width: 1; height: 6 }

				Repeater {
					model: sc.tabs
					Rectangle {
						width: parent.width
						height: 34
						radius: 8
						color: index === sc.currentTab ? colors.accent : "transparent"
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
								color: index === sc.currentTab ? colors.background : colors.textDim
							}
							Text {
								anchors.verticalCenter: parent.verticalCenter
								text: modelData.name
								font.pixelSize: 13
								color: index === sc.currentTab ? colors.background : colors.text
							}
						}
						MouseArea { anchors.fill: parent; onClicked: sc.currentTab = index }
					}
				}
			}
		}

		// RIGHT content 75%
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
				text: sc.tabs[sc.currentTab].name
				color: colors.text
				font.pixelSize: 16
				font.bold: true
			}

			Column {
				visible: sc.tabs[sc.currentTab].name === "Appearance"
				anchors.top: sectionTitle.bottom
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.margins: 16
				anchors.topMargin: 12
				spacing: 14

				ToggleRow {
					width: parent.width
					label: "Dark mode"
					value: Config.appearance.darkMode
					onToggled: (v) => Config.appearance.darkMode = v
				}

				// accent swatches
				Column {
					width: parent.width
					spacing: 8
					Text {
						text: "Accent"
						color: colors.text
						font.pixelSize: 13
					}
					Flow {
						width: parent.width
						spacing: 10
						Repeater {
							model: colors.accentList
							Rectangle {
								width: 28; height: 28; radius: 14
								color: colors.accentHex(modelData)
								border.width: Config.appearance.accentName === modelData ? 3 : 0
								border.color: colors.text
								MouseArea {
									anchors.fill: parent
									onClicked: Config.appearance.accentName = modelData
								}
							}
						}
					}
				}
			}

			// Shortcuts editor
			ShortcutsEditor {
				visible: sc.tabs[sc.currentTab].name === "Shortcuts"
				anchors.top: sectionTitle.bottom
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				anchors.margins: 16
				anchors.topMargin: 12
			}

			// Apps / category editor
			AppsCategoryEditor {
				visible: sc.tabs[sc.currentTab].name === "Apps"
				anchors.top: sectionTitle.bottom
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				anchors.margins: 16
				anchors.topMargin: 12
			}

			Text {
				visible: sc.tabs[sc.currentTab].name !== "Appearance"
					&& sc.tabs[sc.currentTab].name !== "Shortcuts"
					&& sc.tabs[sc.currentTab].name !== "Apps"
				anchors.centerIn: parent
				text: sc.tabs[sc.currentTab].name + " settings\n(coming soon)"
				horizontalAlignment: Text.AlignHCenter
				color: colors.textDim
				font.pixelSize: 13
			}
		}
	}

	// close (×) top-right
	Text {
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.margins: 16
		text: "\uf00d"
		font.family: "Symbols Nerd Font"
		font.pixelSize: 15
		color: colors.textDim
		MouseArea { anchors.fill: parent; anchors.margins: -8
			onClicked: sc.closeRequested() }
	}
}
