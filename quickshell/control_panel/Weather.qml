import QtQuick
import Quickshell.Io
import"../pill"

Row {
	signal dateClicked()
	Column {
		Text {
			id: date
			color: "white"
			property var day: new Date()
			text: Qt.formatDateTime(day, "dddd d MMMM")
			font.pixelSize: 20
			Timer {
				interval: 60000
				running: true
				repeat: true
				onTriggered: date.day = new Date()
			}
			MouseArea {
				anchors.fill: parent
				onClicked: dateClicked()
			}
			
		}
		Clock {
			id: clock
			MouseArea {
				anchors.fill: parent
				onClicked: dateClicked()
			}
			fontSize: 20
		}
	}
	Column {
		id:root2
		//location
		property string detectedCity: ""
		property string detectedLat: ""
		property string detectedLng:""
		readonly property string city: detectedCity ||"Paris"
		//weather
		property string weatherText: "..."
		Process {
			id:geo
			command: ["curl", "-s", "https://ipinfo.io/json"]
			running: true
			stdout: StdioCollector {
				onStreamFinished: {
					try {
						var data = JSON.parse(this.text)
						root2.detectedCity = data.city || ""
						if (data.loc) {
							var parts = data.loc.split (",")
							root2.detectedLat = parts[0] || ""
							root2.detectedLng = parts [1] || ""
						}
						weather.running = true
					}
					catch (e) {
						console.log("geolocation failed:", e)
						weather.running = true
					}
				}
			}
		}
		Process {
			id: weather
			command: ["curl", "-s", "wttr.in/" + root2.city + "?format=%C+%t"]
			running: false
			stdout: StdioCollector {
				onStreamFinished: root2.weatherText = this.text.trim() || "?"
			}
		}

		Text {
			text: root2.city
			color: "white"
		}
		Text {
			text: root2.weatherText
			color: "white"
		}
	}

}
