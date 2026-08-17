import QtQuick
import Quickshell
import "."

// App launcher: search field + filtered app list. Reads DesktopEntries,
// filters by query, launches on click/Enter.
Item {
	id: lc
	Colors { id: colors }

	property bool active: false
	property string query: ""
	property int selected: 0
	property var filterIds: []            // when non-empty, restrict to these ids
	property string categoryTitle: ""     // shown as header in category mode
	signal closeRequested()

	// filtered, sorted app list
	property var apps: {
		var all = [];
		var vals = DesktopEntries.applications.values;
		for (var i = 0; i < vals.length; i++) {
			var d = vals[i];
			if (!d || !d.name) continue;
			// category filter: only include apps whose id is in filterIds
			if (lc.filterIds.length > 0 && lc.filterIds.indexOf(d.id) === -1) continue;
			all.push(d);
		}
		all.sort(function(a, b) { return a.name.localeCompare(b.name); });
		var q = lc.query.trim().toLowerCase();
		if (q === "") return all;
		return all.filter(function(d) {
			var name = (d.name || "").toLowerCase();
			var comment = (d.comment || "").toLowerCase();
			return name.indexOf(q) !== -1 || comment.indexOf(q) !== -1;
		});
	}

	// reset when opened, focus the field
	onActiveChanged: {
		if (active) {
			query = ""
			selected = 0
			field.forceActiveFocus()
		}
	}

	function launchSelected() {
		if (apps.length > 0 && selected >= 0 && selected < apps.length) {
			apps[selected].execute()
			lc.closeRequested()
		}
	}

	Column {
		anchors.fill: parent
		anchors.margins: 16
		spacing: 12

		// category title (only in category picker mode)
		Text {
			visible: lc.categoryTitle.length > 0
			text: lc.categoryTitle
			color: colors.text
			font.pixelSize: 15
			font.bold: true
		}

		// search field
		Rectangle {
			width: parent.width
			height: 44
			radius: 10
			color: colors.surface

			Row {
				anchors.fill: parent
				anchors.leftMargin: 14
				anchors.rightMargin: 14
				spacing: 10

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: "\uf002"   // magnifying glass
					font.family: "Symbols Nerd Font"
					font.pixelSize: 15
					color: colors.textDim
				}

				TextInput {
					id: field
					width: parent.width - 40
					anchors.verticalCenter: parent.verticalCenter
					color: colors.text
					font.pixelSize: 14
					clip: true
					onTextChanged: { lc.query = text; lc.selected = 0 }
					Keys.onDownPressed: if (lc.selected < lc.apps.length - 1) lc.selected++
					Keys.onUpPressed: if (lc.selected > 0) lc.selected--
					Keys.onReturnPressed: lc.launchSelected()
					Keys.onEnterPressed: lc.launchSelected()
					Keys.onEscapePressed: lc.closeRequested()

					Text {
						anchors.verticalCenter: parent.verticalCenter
						text: "Search applications…"
						color: colors.textDim
						font.pixelSize: 14
						visible: field.text.length === 0
					}
				}
			}
		}

		// app list
		ListView {
			width: parent.width
			height: parent.height - 56
			clip: true
			model: lc.apps
			currentIndex: lc.selected
			boundsBehavior: Flickable.StopAtBounds

			delegate: Rectangle {
				width: ListView.view.width
				height: 40
				radius: 8
				color: index === lc.selected ? colors.accent : "transparent"

				property var app: modelData

				Text {
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 12
					elide: Text.ElideRight
					text: app && app.name ? app.name : ""
					color: index === lc.selected ? colors.background : colors.text
					font.pixelSize: 13
				}

				MouseArea {
					anchors.fill: parent
					onClicked: {
						lc.selected = index
						lc.launchSelected()
					}
				}
			}
		}
	}
}
