import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts


PanelWindow {
	anchors.top: true
	implicitHeight: 30
	Rectangle {
		id: pill
		anchors.centerIn: parent   // (1) center this shape in its parent (the bar)
		height: 30                 // (2) fixed height for the pill
		radius: height / 2         // (3) half the height = fully rounded end
		width: toolbarRow.implicitWidth + 20   // (5) hug the content's width + padding

		RowLayout {
			id: toolbarRow
			anchors.centerIn: parent   // (6) center the row of items inside the pill
			spacing: 12                // (7) gap between each item

			Text { text: "🔊"; font.pixelSize: 16 }
			Text { text: "🔋"; font.pixelSize: 16 }
			Text { text: "🕐"; font.pixelSize: 16 }
		}
	}
}
