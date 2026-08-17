pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	property alias appearance: adapter.appearance
	property alias behavior:   adapter.behavior
	property alias nightlight: adapter.nightlight
	property alias categories: adapter.categories

	// ---- category helpers (categories stored in settings.json) ----
	// each: { name, apps:[desktopId], shortcutEnabled:bool, key:"", mods:"SUPER" }
	function addCategory(name) {
		var arr = adapter.categories.slice()
		arr.push({ name: name, apps: [], shortcutEnabled: false, key: "", mods: "SUPER" })
		adapter.categories = arr
	}
	function removeCategory(index) {
		var arr = adapter.categories.slice()
		arr.splice(index, 1)
		adapter.categories = arr
		// note: caller should also remove the bind via bind_tool setcat <i> "" ""
	}
	function renameCategory(index, name) {
		var arr = adapter.categories.slice()
		// a custom name (not the placeholder) makes it shortcut-eligible
		var custom = (name !== "New category" && name.trim().length > 0)
		arr[index] = Object.assign({}, arr[index],
			{ name: name, shortcutEnabled: arr[index].shortcutEnabled || false,
			  isCustom: custom })
		adapter.categories = arr
	}
	// a category counts for shortcuts once it has a custom (non-placeholder) name
	function isShortcutEligible(cat) {
		return cat && cat.name && cat.name !== "New category" && cat.name.trim().length > 0
	}
	function toggleAppInCategory(index, desktopId) {
		var arr = adapter.categories.slice()
		var cat = Object.assign({}, arr[index])
		var apps = cat.apps.slice()
		var i = apps.indexOf(desktopId)
		if (i === -1) apps.push(desktopId); else apps.splice(i, 1)
		cat.apps = apps
		arr[index] = cat
		adapter.categories = arr
	}
	function setCategoryShortcut(index, enabled, key, mods) {
		var arr = adapter.categories.slice()
		arr[index] = Object.assign({}, arr[index],
			{ shortcutEnabled: enabled, key: key, mods: mods })
		adapter.categories = arr
	}

	FileView {
		id: view
		path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeTimer.restart()
		onLoadFailed: writeAdapter()   // create from defaults if missing

		JsonAdapter {
			id: adapter

			property JsonObject appearance: JsonObject {
				property bool   darkMode:   true
				property string accentName: "blue"
				property int    pillWidth:   150
				property int    pillHeight:  34
				property int    notch:       16
				property int    panelWidth:  460
				property int    panelHeight: 240
			}
			property JsonObject behavior: JsonObject {
				property bool closeOnOutsideClick: true
				property int  animationDuration:   320
				property bool showSeconds:          true
			}
			property JsonObject nightlight: JsonObject {
				property bool geoMode:   true
				property int  nightTemp: 3500
			}
			property var categories: []
		}
	}

	Timer {
		id: writeTimer
		interval: 50
		onTriggered: view.writeAdapter()
	}
}
