import QtQuick
import "."

// A labelled on/off switch bound to a config bool. Emits toggled(newValue).
Item {
	id: row
	Colors { id: colors }

	property string label: ""
	property bool value: false
	signal toggled(bool v)

	height: 44

	Text {
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		text: row.label
		color: colors.text
		font.pixelSize: 13
	}

	// switch track
	Rectangle {
		id: track
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: 44; height: 24; radius: 12
		color: row.value ? colors.accent : colors.background
		Behavior on color { ColorAnimation { duration: 150 } }

		Rectangle {   // knob
			width: 18; height: 18; radius: 9
			color: colors.text
			y: (parent.height - height) / 2
			x: row.value ? parent.width - width - 3 : 3
			Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
		}

		MouseArea {
			anchors.fill: parent
			onClicked: row.toggled(!row.value)
		}
	}
}
