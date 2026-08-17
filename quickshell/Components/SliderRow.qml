import QtQuick
import "."

// A labelled slider bound to a config value. Reads `value`, emits
// `moved(newValue)` which the parent writes to Config.
Item {
	id: row
	Colors { id: colors }

	property string label: ""
	property real value: 0
	property real from: 0
	property real to: 100
	property int  decimals: 0
	signal moved(real v)

	height: 44

	Text {
		id: lbl
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		text: row.label
		color: colors.text
		font.pixelSize: 13
		width: parent.width * 0.4
		elide: Text.ElideRight
	}

	Text {
		anchors.right: track.left
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		text: row.value.toFixed(row.decimals)
		color: colors.textDim
		font.pixelSize: 12
	}

	Rectangle {
		id: track
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: parent.width * 0.4
		height: 6
		radius: 3
		color: colors.background

		property real frac: (row.value - row.from) / (row.to - row.from)

		Rectangle {
			height: parent.height
			width: parent.width * Math.max(0, Math.min(1, track.frac))
			radius: 3
			color: colors.accent
		}

		Rectangle {
			width: 16; height: 16; radius: 8
			color: colors.accent
			y: (parent.height - height) / 2
			x: Math.max(0, Math.min(parent.width - width,
				track.frac * parent.width - width / 2))
		}

		MouseArea {
			anchors.fill: parent
			anchors.margins: -8
			// explicit (mouse) params, and a non-reserved function name
			onPressed: (mouse) => row.applyPos(mouse.x)
			onPositionChanged: (mouse) => { if (pressed) row.applyPos(mouse.x) }
		}
	}

	function applyPos(mx) {
		var f = Math.max(0, Math.min(1, mx / track.width))
		var v = row.from + f * (row.to - row.from)
		if (row.decimals === 0) v = Math.round(v)
		row.moved(v)
	}
}
