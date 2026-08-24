import QtQuick
import Quickshell.Hyprland

Row {
	id: workspaces
	spacing: 4
	Repeater {
		anchors.verticalCenter: parent.horizontalCenter
		model: Hyprland.workspaces.values
		Rectangle {
			width: modelData.active ? 15 : 10
			height: 7
			radius : width / 1.25
			color: modelData.active ? "white" : "grey"
			MouseArea {
				onClicked: modelData.activate()
			}

		}

	}

}
