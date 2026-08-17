import QtQuick
import Quickshell
import "."

// Apps tab: build persistent categories from installed apps.
// Left: category list (add/select/delete, shortcut toggle).
// Right: all apps — click to add/remove from the selected category.
Item {
	id: ae
	Colors { id: colors }

	property int selectedCat: -1
	property string appQuery: ""

	// all installed apps, sorted
	property var allApps: {
		var out = []
		var vals = DesktopEntries.applications.values
		for (var i = 0; i < vals.length; i++)
			if (vals[i] && vals[i].name) out.push(vals[i])
		out.sort(function(a, b) { return a.name.localeCompare(b.name) })
		return out
	}
	property var filteredApps: {
		var q = appQuery.trim().toLowerCase()
		if (q === "") return allApps
		return allApps.filter(function(d) {
			return (d.name || "").toLowerCase().indexOf(q) !== -1
		})
	}

	function catAppsFor(idx) {
		if (idx < 0 || idx >= Config.categories.length) return []
		return Config.categories[idx].apps || []
	}
	function appInSelected(desktopId) {
		return ae.catAppsFor(ae.selectedCat).indexOf(desktopId) !== -1
	}

	Row {
		anchors.fill: parent
		spacing: 12

		// ---- LEFT: categories ----
		Rectangle {
			width: (parent.width - 12) * 0.4
			height: parent.height
			radius: 12
			color: colors.surface

			Column {
				anchors.fill: parent
				anchors.margins: 10
				spacing: 8

				Row {
					width: parent.width
					Text {
						text: "Categories"
						color: colors.text
						font.pixelSize: 14; font.bold: true
						width: parent.width - 28
					}
					// add category
					Rectangle {
						width: 24; height: 24; radius: 12
						color: colors.accent
						Text { anchors.centerIn: parent; text: "+"; color: colors.background; font.pixelSize: 16 }
						MouseArea {
							anchors.fill: parent
							onClicked: {
								Config.addCategory("New category")
								ae.selectedCat = Config.categories.length - 1
							}
						}
					}
				}

				// category list
				ListView {
					width: parent.width
					height: parent.height - 40
					clip: true
					model: Config.categories
					spacing: 4
					delegate: Rectangle {
						required property int index
						required property var modelData
						width: ListView.view.width
						height: 46
						radius: 8
						color: index === ae.selectedCat ? colors.accent : colors.background

						property int appCount: modelData.apps ? modelData.apps.length : 0

						Column {
							anchors.left: parent.left
							anchors.leftMargin: 10
							anchors.right: parent.right
							anchors.rightMargin: 34
							anchors.verticalCenter: parent.verticalCenter
							spacing: 2
							// editable name — click to rename
							TextInput {
								id: nameInput
								width: parent.width
								text: modelData.name
								color: index === ae.selectedCat ? colors.background : colors.text
								font.pixelSize: 13
								clip: true
								selectByMouse: true
								onEditingFinished: {
									var nm = text.trim()
									if (nm.length > 0 && nm !== modelData.name)
										Config.renameCategory(index, nm)
								}
								// clicking the name selects the row AND focuses for edit
								onActiveFocusChanged: if (activeFocus) ae.selectedCat = index
							}
							Text {
								text: appCount === 0 ? "empty"
									: appCount === 1 ? "1 app — direct launch"
									: appCount + " apps — picker"
								color: index === ae.selectedCat
									? colors.background : colors.textDim
								font.pixelSize: 10
							}
						}

						// delete (× top-right)
						Rectangle {
							anchors.right: parent.right
							anchors.rightMargin: 8
							anchors.verticalCenter: parent.verticalCenter
							width: 18; height: 18; radius: 9
							color: "transparent"
							Text {
								anchors.centerIn: parent; text: "\uf00d"
								font.family: "Symbols Nerd Font"; font.pixelSize: 10
								color: index === ae.selectedCat ? colors.background : colors.danger
							}
							MouseArea {
								anchors.fill: parent
								onClicked: {
									Config.removeCategory(index)
									if (ae.selectedCat >= Config.categories.length)
										ae.selectedCat = Config.categories.length - 1
								}
							}
						}

						// row select — only the status-line area (below the name),
						// so clicking the name edits it instead of just selecting
						MouseArea {
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.bottom: parent.bottom
							height: parent.height / 2
							anchors.rightMargin: 34
							onClicked: ae.selectedCat = index
						}
					}
				}
			}
		}

		// ---- RIGHT: apps ----
		Rectangle {
			width: (parent.width - 12) * 0.6
			height: parent.height
			radius: 12
			color: colors.surface

			Column {
				anchors.fill: parent
				anchors.margins: 10
				spacing: 8

				// search
				Rectangle {
					width: parent.width
					height: 34
					radius: 8
					color: colors.background
					Row {
						anchors.fill: parent
						anchors.leftMargin: 10
						spacing: 8
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: "\uf002"; font.family: "Symbols Nerd Font"
							font.pixelSize: 12; color: colors.textDim
						}
						TextInput {
							id: appSearch
							width: parent.width - 40
							anchors.verticalCenter: parent.verticalCenter
							color: colors.text
							font.pixelSize: 12
							onTextChanged: ae.appQuery = text
							Text {
								anchors.verticalCenter: parent.verticalCenter
								text: "Search apps…"; color: colors.textDim
								font.pixelSize: 12; visible: appSearch.text.length === 0
							}
						}
					}
				}

				Text {
					visible: ae.selectedCat < 0
					text: "Select or create a category, then click apps to add them."
					color: colors.textDim
					font.pixelSize: 12
					width: parent.width
					wrapMode: Text.WordWrap
				}

				// app list
				ListView {
					width: parent.width
					height: parent.height - (ae.selectedCat < 0 ? 60 : 46)
					clip: true
					visible: ae.selectedCat >= 0
					model: ae.filteredApps
					spacing: 3
					delegate: Rectangle {
						required property var modelData
						width: ListView.view.width
						height: 36
						radius: 8
						property bool inCat: ae.appInSelected(modelData.id)
						color: inCat
							? Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.25)
							: "transparent"

						Text {
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
							anchors.leftMargin: 12
							text: modelData.name
							color: colors.text
							font.pixelSize: 12
						}
						Text {
							visible: parent.inCat
							anchors.verticalCenter: parent.verticalCenter
							anchors.right: parent.right
							anchors.rightMargin: 12
							text: "\uf00c"
							font.family: "Symbols Nerd Font"
							font.pixelSize: 11
							color: colors.accent
						}
						MouseArea {
							anchors.fill: parent
							onClicked: Config.toggleAppInCategory(ae.selectedCat, modelData.id)
						}
					}
				}
			}
		}
	}
}
