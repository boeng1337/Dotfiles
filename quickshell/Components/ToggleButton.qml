import QtQuick
import "."

Rectangle {
	id: btn
	Colors { id: colors }

	property string iconGlyph: ""
	property string label: ""
	property string subtitle: ""
	property bool isOn: false
	property bool isExpanded: false
	property var menuModel: null
	property real collapsedH: 40
	property real expandedH: 40

	signal requestOpen()
	signal requestClose()
	signal toggled()
	signal passwordRequested(var network)

	radius: 12
	color: colors.surface
	clip: true

	height: isExpanded ? expandedH : collapsedH
	Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

	Item {
		id: header
		width: parent.width
		height: btn.collapsedH

		Rectangle {
			id: iconWrap
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: parent.left
			anchors.leftMargin: 8
			width: 28; height: 28; radius: 14
			color: btn.isOn ? colors.accent : colors.background
			Behavior on color { ColorAnimation { duration: 150 } }
			Text {
				anchors.centerIn: parent
				text: btn.iconGlyph
				font.family: "Symbols Nerd Font"
				font.pixelSize: 14
				color: btn.isOn ? colors.background : colors.textDim
			}
			MouseArea { anchors.fill: parent; onClicked: btn.toggled() }
		}

		Column {
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: iconWrap.right
			anchors.leftMargin: 10
			spacing: 0
			Text {
				text: btn.label
				font.pixelSize: 13
				font.bold: true
				color: colors.text
			}
			Text {
				visible: btn.subtitle.length > 0
				text: btn.subtitle
				font.pixelSize: 9
				color: colors.textDim
				elide: Text.ElideRight
				width: 90
			}
		}

		Text {
			id: chevron
			anchors.verticalCenter: parent.verticalCenter
			anchors.right: parent.right
			anchors.rightMargin: 10
			text: "\uf054"
			font.family: "Symbols Nerd Font"
			font.pixelSize: 12
			color: colors.textDim
			rotation: btn.isExpanded ? 90 : 0
			Behavior on rotation { NumberAnimation { duration: 200 } }
			MouseArea {
				anchors.fill: parent
				anchors.margins: -8
				onClicked: btn.isExpanded ? btn.requestClose() : btn.requestOpen()
			}
		}
	}

	Column {
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.margins: 10
		spacing: 6
		opacity: btn.isExpanded ? 1 : 0
		visible: opacity > 0
		Behavior on opacity { NumberAnimation { duration: 160 } }

		Repeater {
			model: btn.menuModel ? btn.menuModel : 3
			Rectangle {
				id: rowRect
				width: parent ? parent.width : 0
				height: 24; radius: 6
				color: colors.background

				property var item: btn.menuModel ? modelData : null
				property string itemName: item && item.name !== undefined ? item.name : ""
				property bool itemActive: item && item.connected !== undefined ? item.connected : false
				property bool isSecured: item && item.security !== undefined && item.security !== "" && item.security !== null
				property bool isWifi: item && item.security !== undefined

				Text {
					visible: rowRect.item !== null && rowRect.isWifi
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: 8
					text: rowRect.isSecured ? "\uf023" : "\uf09c"
					font.family: "Symbols Nerd Font"
					font.pixelSize: 11
					color: rowRect.itemActive ? colors.accent : colors.textDim
				}

				Text {
					visible: rowRect.item !== null
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: rowRect.isWifi ? 26 : 8
					anchors.right: parent.right
					anchors.rightMargin: 8
					elide: Text.ElideRight
					text: rowRect.itemName
					color: rowRect.itemActive ? colors.accent : colors.text
					font.pixelSize: 11
				}

				MouseArea {
					enabled: rowRect.item !== null
					anchors.fill: parent
					onClicked: {
						var it = rowRect.item
						if (!it) return
						if (it.connected) {
							if (it.requestDisconnect) it.requestDisconnect()
							return
						}
						if (rowRect.isWifi) {
							if (!rowRect.isSecured) {
								if (it.requestConnect) it.requestConnect()
							} else {
								btn.passwordRequested(it)
							}
						} else {
							if (it.connected !== undefined) it.connected = true
						}
					}
				}
			}
		}
	}
}
