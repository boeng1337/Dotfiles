import QtQuick
import "."

// Android-style filled toggle button.
// OFF: dim surface. ON: accent fill. Tap to toggle.
Rectangle {
	id: tile
	Colors { id: colors }

	property string iconGlyph: ""
	property string title: ""
	property string subtitle: ""
	property bool on: false

	radius: 14
	color: on ? colors.accent : colors.surface
	Behavior on color { ColorAnimation { duration: 160 } }

	Row {
		anchors.fill: parent
		anchors.leftMargin: 14
		anchors.rightMargin: 14
		spacing: 12

		// icon in a little circle, like Android quick-settings
		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: 34; height: 34; radius: 17
			color: tile.on ? Qt.rgba(1,1,1,0.18) : colors.background
			Text {
				anchors.centerIn: parent
				text: tile.iconGlyph
				font.family: "Symbols Nerd Font"
				font.pixelSize: 16
				color: tile.on ? colors.background : colors.textDim
			}
		}

		Column {
			anchors.verticalCenter: parent.verticalCenter
			spacing: 1
			Text {
				text: tile.title
				font.pixelSize: 14
				font.bold: true
				color: tile.on ? colors.background : colors.text
			}
			Text {
				text: tile.subtitle
				font.pixelSize: 11
				color: tile.on ? Qt.rgba(0,0,0,0.6) : colors.textDim
			}
		}
	}

	MouseArea {
		anchors.fill: parent
		onClicked: tile.on = !tile.on
	}
}
