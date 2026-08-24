import QtQuick

Text {
	id: clock
	color: "white"
	font.pointSize: 14
	font.bold: false
	property alias fontSize: clock.font.pixelSize
	property var now: new Date()
	text: Qt.formatDateTime(now, "hh:mm:ss")
	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: clock.now = new Date()
	}
}
