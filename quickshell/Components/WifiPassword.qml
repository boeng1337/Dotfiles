import Quickshell
import QtQuick
import "."

// Floating password prompt — normal toplevel window, no QtQuick.Controls dep.
FloatingWindow {
	id: win
	Colors { id: colors }

	title: "quickshell-wifi-password"

	property string ssid: ""
	property var network: null
	property string mockState: "input"

	implicitWidth: 380
	implicitHeight: 190
	color: colors.background

	Rectangle {
		anchors.fill: parent
		color: colors.background

		Column {
			anchors.centerIn: parent
			width: parent.width - 48
			spacing: 14

			Text {
				text: "Connect to " + win.ssid
				color: colors.text
				font.pixelSize: 15
				font.bold: true
				width: parent.width
				elide: Text.ElideRight
			}

			// ----- INPUT / FAILED -----
			Column {
				width: parent.width
				spacing: 10
				visible: win.mockState === "input" || win.mockState === "failed"

				Rectangle {
					width: parent.width
					height: 40
					radius: 8
					color: colors.surface
					border.width: win.mockState === "failed" ? 2 : 0
					border.color: colors.danger

					// plain TextInput (core QtQuick) instead of TextField
					TextInput {
						id: pwField
						anchors.fill: parent
						anchors.leftMargin: 12
						anchors.rightMargin: 12
						verticalAlignment: TextInput.AlignVCenter
						echoMode: TextInput.Password
						color: colors.text
						font.pixelSize: 13
						clip: true
						onAccepted: win.submit()

						// placeholder
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: "Password"
							color: colors.textDim
							font.pixelSize: 13
							visible: pwField.text.length === 0 && !pwField.activeFocus
						}
					}
				}

				Text {
					visible: win.mockState === "failed"
					text: "Incorrect password"
					color: colors.danger
					font.pixelSize: 12
				}

				Row {
					width: parent.width
					spacing: 10
					layoutDirection: Qt.RightToLeft

					Rectangle {
						width: 92; height: 34; radius: 8
						color: colors.accent
						Text {
							anchors.centerIn: parent
							text: win.mockState === "failed" ? "Retry" : "Connect"
							color: colors.background; font.pixelSize: 13; font.bold: true
						}
						MouseArea { anchors.fill: parent; onClicked: win.submit() }
					}
					Rectangle {
						visible: win.mockState === "failed"
						width: 92; height: 34; radius: 8
						color: colors.surface
						Text {
							anchors.centerIn: parent
							text: "Reinput"; color: colors.text; font.pixelSize: 13
						}
						MouseArea {
							anchors.fill: parent
							onClicked: {
								pwField.text = ""
								win.mockState = "input"
								pwField.forceActiveFocus()
							}
						}
					}
					Rectangle {
						width: 72; height: 34; radius: 8
						color: colors.surface
						Text {
							anchors.centerIn: parent
							text: "Quit"; color: colors.text; font.pixelSize: 13
						}
						MouseArea { anchors.fill: parent; onClicked: win.visible = false }
					}
				}
			}

			// ----- CONNECTING -----
			Row {
				visible: win.mockState === "connecting"
				spacing: 10
				// simple rotating spinner instead of BusyIndicator
				Rectangle {
					width: 18; height: 18; radius: 9
					color: "transparent"
					border.width: 2
					border.color: colors.accent
					anchors.verticalCenter: parent.verticalCenter
					Rectangle {
						width: 6; height: 6; radius: 3
						color: colors.accent
						x: parent.width - 6; y: parent.height/2 - 3
					}
					RotationAnimation on rotation {
						from: 0; to: 360; duration: 900
						loops: Animation.Infinite; running: win.mockState === "connecting"
					}
				}
				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: "Connecting…"; color: colors.textDim; font.pixelSize: 13
				}
			}

			// ----- SUCCESS -----
			Text {
				visible: win.mockState === "success"
				text: "Connected ✓"
				color: colors.good
				font.pixelSize: 14
				font.bold: true
			}
		}
	}

	function submit() {
		if (!win.network) { win.mockState = "failed"; return }
		win.mockState = "connecting"
		win.network.requestConnectWithPsk(pwField.text)
		timeoutTimer.restart()
	}

	Connections {
		target: win.network
		function onConnectedChanged() {
			if (win.network && win.network.connected && win.mockState === "connecting") {
				timeoutTimer.stop()
				win.mockState = "success"
				successTimer.start()
			}
		}
		function onConnectionFailed() {
			if (win.mockState === "connecting") {
				timeoutTimer.stop()
				win.mockState = "failed"
			}
		}
	}

	Timer {
		id: timeoutTimer
		interval: 10000
		onTriggered: if (win.mockState === "connecting") win.mockState = "failed"
	}
	Timer {
		id: successTimer
		interval: 900
		onTriggered: win.visible = false
	}

	onVisibleChanged: {
		if (visible) { win.mockState = "input"; pwField.text = ""; pwField.forceActiveFocus() }
	}
}
