pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistent category store. Each category:
//   { name, apps: [desktopId,...], shortcutEnabled: bool, key: "", mods: "" }
// Saved to ~/.config/quickshell/categories.json via FileView + JsonAdapter.
Singleton {
	id: root

	property alias list: adapter.categories

	function addCategory(name) {
		var arr = adapter.categories.slice()
		arr.push({ name: name, apps: [], shortcutEnabled: false, key: "", mods: "SUPER" })
		adapter.categories = arr
		save()
	}
	function removeCategory(index) {
		var arr = adapter.categories.slice()
		arr.splice(index, 1)
		adapter.categories = arr
		save()
	}
	function renameCategory(index, name) {
		var arr = adapter.categories.slice()
		arr[index] = Object.assign({}, arr[index], { name: name })
		adapter.categories = arr
		save()
	}
	function toggleApp(index, desktopId) {
		var arr = adapter.categories.slice()
		var cat = Object.assign({}, arr[index])
		var apps = cat.apps.slice()
		var i = apps.indexOf(desktopId)
		if (i === -1) apps.push(desktopId); else apps.splice(i, 1)
		cat.apps = apps
		arr[index] = cat
		adapter.categories = arr
		save()
	}
	function setShortcut(index, enabled, key, mods) {
		var arr = adapter.categories.slice()
		arr[index] = Object.assign({}, arr[index],
			{ shortcutEnabled: enabled, key: key, mods: mods })
		adapter.categories = arr
		save()
	}
	function save() { saveTimer.restart() }

	Timer { id: saveTimer; interval: 50; onTriggered: fileView.writeAdapter() }

	FileView {
		id: fileView
		path: Quickshell.env("HOME") + "/.config/quickshell/categories.json"
		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
		JsonAdapter {
			id: adapter
			property var categories: []
		}
	}
}
