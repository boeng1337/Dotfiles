import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import "Components"

// STAGE A — minimal Panacea-style single overlay.
// Full-screen window, constant size, capsule morphs collapsed↔panel.
// Empty panel for now. Verifies: loads, morphs, mask lets clicks through.
ShellRoot {

PanelWindow {
	id: root
	Colors { id: colors }

	// ---- global shortcut: Hyprland triggers this to open the launcher ----
	// In hyprland.lua: hl.bind("SUPER + SPACE", hl.dsp.global("quickshell:launcher"))
	GlobalShortcut {
		appid: "quickshell"
		name: "launcher"
		description: "Open the app launcher"
		onPressed: {
			// toggle: open launcher, or close if already open
			if (root.uiState === "launcher") { root.uiState = "collapsed" } else { root.openFullLauncher() }
		}
	}

	GlobalShortcut {
		appid: "quickshell"
		name: "controlpanel"
		description: "Toggle the control panel"
		onPressed: {
			root.uiState = (root.uiState === "panel") ? "collapsed" : "panel"
		}
	}

	// ---- dynamic per-category shortcuts ----
	// Each enabled category registers a GlobalShortcut named cat_<index>.
	// In binds.lua: hl.bind(..., hl.dsp.global("quickshell:cat_0")) etc.
	Repeater {
		model: Config.categories
		Item {
			required property int index
			required property var modelData
			GlobalShortcut {
				appid: "quickshell"
				name: "cat_" + index
				description: "Category: " + (modelData.name || "")
				onPressed: {
					if (modelData.shortcutEnabled) root.launchCategory(modelData)
				}
			}
		}
	}

	// ---- sync GTK/env dark-light with the shell's darkMode ----
	// runs `gsettings set ... color-scheme prefer-dark|prefer-light` so GTK
	// apps (Nautilus etc.) follow the shell's dark/light toggle.
	Process {
		id: gtkThemeProc
		command: ["gsettings", "set", "org.gnome.desktop.interface",
			"color-scheme", Config.appearance.darkMode ? "prefer-dark" : "prefer-light"]
		running: false
	}

	// icon theme follows dark/light: Papirus-Dark (dark) / Papirus (light)
	Process {
		id: iconThemeProc
		command: ["gsettings", "set", "org.gnome.desktop.interface",
			"icon-theme", Config.appearance.darkMode ? "Papirus-Dark" : "Papirus"]
		running: false
	}

	// ---- sync Hyprland border colors with the shell's accent (live) ----
	// On Lua-based Hyprland (0.55+), runtime changes go through `hyprctl eval`
	// running an hl.config() Lua call — `keyword` is legacy-parser only.
	function hex6(c) {
		var s = c.toString().replace("#", "")
		if (s.length === 8) s = s.substring(2)   // strip leading alpha
		return s
	}
	Process {
		id: hyprBorderProc
		command: ["hyprctl", "eval",
			"hl.config({ general = { [\"col.active_border\"] = \"rgb("
			+ root.hex6(colors.accent)
			+ ")\", [\"col.inactive_border\"] = \"rgb("
			+ root.hex6(colors.surface) + ")\" } })"]
		running: false
	}

	// ---- persist the flavor: rewrite ~/.config/hypr/themes/current.lua so
	// Hyprland loads the right Catppuccin flavor on next start ----
	Process {
		id: hyprFlavorPersist
		command: ["sh", "-c",
			"echo \"return require('themes.catppuccin-"
			+ (Config.appearance.darkMode ? "mocha" : "latte")
			+ "')\" > \"$HOME/.config/hypr/themes/current.lua\""]
		running: false
	}

	// ---- fish colors follow flavor AND accent ----
	// First choose the flavor theme, then override the key accent-driven
	// colors (command/param) so fish matches the chosen accent live.
	Process {
		id: fishThemeProc
		command: ["fish", "-c",
			"fish_config theme choose \"Catppuccin "
			+ (Config.appearance.darkMode ? "Mocha" : "Latte") + "\"; "
			+ "set -U fish_color_command " + root.hex6(colors.accent) + "; "
			+ "set -U fish_color_host " + root.hex6(colors.accent)]
		running: false
	}

	// ---- kitty follows the flavor (built-in Catppuccin themes, live reload) ----
	Process {
		id: kittyThemeProc
		command: ["kitty", "+kitten", "themes", "--reload-in=all",
			Config.appearance.darkMode ? "Catppuccin-Mocha" : "Catppuccin-Latte"]
		running: false
	}

	// ---- Papirus folder icons follow flavor + accent ----
	// Uses a USER-LOCAL Papirus copy (~/.local/share/icons) so recoloring
	// never needs root. Set up once: copy Papirus there (see setup script).
	Process {
		id: papirusProc
		command: ["papirus-folders",
			"-t", Config.appearance.darkMode ? "Papirus-Dark" : "Papirus",
			"-C", "cat-" + (Config.appearance.darkMode ? "mocha" : "latte")
				+ "-" + Config.appearance.accentName,
			"-o"]
		running: false
	}

	// ---- ensure cursor themes are symlinked into ~/.icons/ on startup ----
	// Real files live in ~/.config/theme/cursor/ (portable dotfiles); this
	// links them where XCursor looks, so no separate setup script is needed.
	Process {
		id: cursorLinkProc
		command: ["sh", "-c",
			"mkdir -p \"$HOME/.icons\"; "
			+ "for d in \"$HOME/.config/theme/cursor\"/*/; do "
			+ "[ -d \"$d\" ] && ln -sfn \"$d\" \"$HOME/.icons/$(basename \"$d\")\"; "
			+ "done"]
		running: false
	}

	// ---- cursor follows both flavor AND accent (live via hyprctl setcursor) ----
	// theme names follow: catppuccin-{mocha|latte}-{accent}-cursors
	Process {
		id: cursorProc
		command: ["hyprctl", "setcursor",
			"catppuccin-" + (Config.appearance.darkMode ? "mocha" : "latte")
				+ "-" + Config.appearance.accentName + "-cursors",
			"24"]
		running: false
	}

	function applyTheme() {
		gtkThemeProc.running = true
		iconThemeProc.running = true
		hyprBorderProc.running = true
		hyprFlavorPersist.running = true
		fishThemeProc.running = true
		kittyThemeProc.running = true
		cursorProc.running = true
		papirusProc.running = true
	}

	Connections {
		target: Config.appearance
		function onDarkModeChanged()   { root.applyTheme() }
		function onAccentNameChanged() { root.applyTheme() }
	}
	// on startup: ensure cursor symlinks exist, then apply the saved theme
	Component.onCompleted: {
		cursorLinkProc.running = true
		applyTheme()
	}

	property string uiState: "collapsed"     // "collapsed" | "panel" | "settings" | "launcher"
	readonly property bool expanded: uiState !== "collapsed"
	readonly property bool settingsMode: uiState === "settings"
	readonly property bool launcherMode: uiState === "launcher"
	readonly property bool holdOpen: expanded
	property string openMenu: ""              // "" | "wifi" | "bt"

	// category picker: when non-empty, the launcher shows only these desktop ids
	property var categoryFilter: []           // [] = all apps (normal launcher)
	property string categoryTitle: ""

	// Act on a category: 1 app → launch directly; multiple → open filtered picker.
	function launchCategory(cat) {
		var apps = cat.apps || []
		if (apps.length === 0) return
		if (apps.length === 1) {
			// direct launch
			var vals = DesktopEntries.applications.values
			for (var i = 0; i < vals.length; i++) {
				if (vals[i] && vals[i].id === apps[0]) { vals[i].execute(); return }
			}
		} else {
			// open picker filtered to this category
			categoryFilter = apps
			categoryTitle = cat.name
			uiState = "launcher"
		}
	}
	function openFullLauncher() {
		categoryFilter = []
		categoryTitle = ""
		uiState = "launcher"
	}

	// wifi device + sorted networks
	property var wifiDevice: {
		var m = Networking.devices;
		var vals = m && m.values ? m.values : null;
		if (!vals) return null;
		for (var i = 0; i < vals.length; i++)
			if (vals[i] && vals[i].type === 1) return vals[i];
		return null;
	}
	property string connectedSsid: {
		var wd = wifiDevice;
		if (!wd || !wd.networks || !wd.networks.values) return "";
		var nv = wd.networks.values;
		for (var i = 0; i < nv.length; i++)
			if (nv[i] && nv[i].connected) return nv[i].name;
		return "";
	}
	property var sortedNetworks: {
		var wd = wifiDevice;
		if (!wd || !wd.networks || !wd.networks.values) return [];
		var arr = wd.networks.values.slice();
		arr.sort(function(a, b) {
			if (a.connected && !b.connected) return -1;
			if (b.connected && !a.connected) return 1;
			return (b.signalStrength || 0) - (a.signalStrength || 0);
		});
		return arr;
	}

	readonly property int pillH: 34
	readonly property int collapsedW: 150
	readonly property int panelW: 460
	readonly property int panelH: 240
	readonly property int settingsW: 780
	readonly property int settingsH: 540
	readonly property int launcherW: 560
	readonly property int launcherH: 400
	readonly property int notch: 16
	readonly property int animMs: 300

	// Anchor three edges, leaving the bottom free (the direction the panel
	// opens). Anchoring all four makes exclusiveZone ambiguous — the layer
	// would take the whole screen and reserve from the wrong edge.
	anchors.top: true
	anchors.left: true
	anchors.right: true
	// anchors.bottom intentionally omitted
	implicitHeight: screen ? screen.height : 1080
	implicitWidth: screen ? screen.width : 1920
	color: "transparent"
	exclusiveZone: pillH
	WlrLayershell.layer: WlrLayer.Overlay
	// request keyboard focus from the compositor when a panel needs typing
	// (launcher search, settings shortcut-capture). OnDemand lets fields grab keys.
	WlrLayershell.keyboardFocus: (root.launcherMode || root.settingsMode)
		? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

	// CRITICAL: input masked to the capsule when not pinned, so clicks pass
	// through the rest of the screen. When panel open, whole window interactive.
	mask: root.holdOpen ? null : capsuleRegion
	Region { id: capsuleRegion; item: capsule }

	// close areas around the capsule when panel open
	Repeater {
		model: 4
		MouseArea {
			required property int index
			enabled: root.holdOpen
			visible: enabled
			x: index === 3 ? capsule.x + capsule.width : 0
			y: index === 1 ? capsule.y + capsule.height : (index >= 2 ? capsule.y : 0)
			width:  index < 2 ? root.width
				  : index === 2 ? capsule.x
								: Math.max(0, root.width - capsule.x - capsule.width)
			height: index === 0 ? capsule.y
				  : index === 1 ? Math.max(0, root.height - capsule.y - capsule.height)
								: capsule.height
			onClicked: root.uiState = "collapsed"
		}
	}

	// ===== THE CAPSULE =====
	Rectangle {
		id: capsule
		color: colors.surface
		clip: true

		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter

		// settings detaches and centers; launcher stays at the top (panel-like)
		readonly property bool centered: root.settingsMode
		anchors.topMargin: capsule.centered
			? Math.max(24, (root.height - height) / 2)
			: 0
		Behavior on anchors.topMargin {
			NumberAnimation { duration: root.animMs; easing.type: Easing.InOutCubic }
		}

		width: root.settingsMode ? root.settingsW
			 : root.launcherMode ? root.launcherW
			 : root.expanded     ? root.panelW
								 : root.collapsedW
		Behavior on width {
			NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
		}

		height: root.settingsMode ? root.settingsH
			  : root.launcherMode ? root.launcherH
			  : root.expanded     ? (root.pillH + root.panelH)
								  : root.pillH
		Behavior on height {
			NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic }
		}

		// corners: flush to top edge normally (top square); when detached
		// (settings/launcher) → all four corners round
		topLeftRadius:  capsule.centered ? 26 : 0
		topRightRadius: capsule.centered ? 26 : 0
		bottomLeftRadius: root.expanded ? 26 : root.pillH / 2
		bottomRightRadius: root.expanded ? 26 : root.pillH / 2
		Behavior on topLeftRadius     { NumberAnimation { duration: root.animMs } }
		Behavior on topRightRadius    { NumberAnimation { duration: root.animMs } }
		Behavior on bottomLeftRadius  { NumberAnimation { duration: root.animMs } }
		Behavior on bottomRightRadius { NumberAnimation { duration: root.animMs } }

		// clock (collapsed only)
		Text {
			id: clock
			anchors.horizontalCenter: parent.horizontalCenter
			y: (root.pillH - height) / 2
			visible: !root.expanded
			opacity: root.expanded ? 0 : 1
			Behavior on opacity { NumberAnimation { duration: 120 } }
			color: colors.text
			font.pixelSize: 15
			font.bold: true
			property var now: new Date()
			text: Qt.formatDateTime(now, "hh:mm:ss")
			Timer { interval: 1000; running: true; repeat: true
				onTriggered: clock.now = new Date() }
		}

		// panel content: control center (only in panel state)
		Item {
			id: panel
			visible: root.uiState === "panel"
			opacity: root.uiState === "panel" ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 180 } }
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.leftMargin: 16
			anchors.rightMargin: 16
			anchors.bottomMargin: 16
			anchors.topMargin: root.pillH + 8

			property real gap: 12
			property real boxW: (width  - gap * 2) / 3
			property real boxH: (height - gap) / 2
			property real colH: boxH * 2 + gap

			// middle-top: app launcher trigger
			Rectangle {
				x: panel.boxW + panel.gap; y: 0; width: panel.boxW; height: panel.boxH; radius: 12
				color: colors.background
				Text { anchors.centerIn: parent; text: "\uf002"; font.family: "Symbols Nerd Font"
					font.pixelSize: 20; color: colors.textDim }
				MouseArea { anchors.fill: parent; onClicked: root.openFullLauncher() }
			}
			// top-right: settings gear
			Rectangle {
				x: (panel.boxW + panel.gap) * 2; y: 0; width: panel.boxW; height: panel.boxH; radius: 12
				color: colors.background
				Text { anchors.centerIn: parent; text: "\uf013"; font.family: "Symbols Nerd Font"
					font.pixelSize: 20; color: colors.textDim }
				MouseArea { anchors.fill: parent; onClicked: root.uiState = "settings" }
			}
			Rectangle { x: panel.boxW + panel.gap; y: panel.boxH + panel.gap; width: panel.boxW; height: panel.boxH; radius: 12; color: colors.background }
			Rectangle { x: (panel.boxW + panel.gap) * 2; y: panel.boxH + panel.gap; width: panel.boxW; height: panel.boxH; radius: 12; color: colors.background }

			// bottom-left: night light + reserved slot
			SunsetToggle {
				visible: root.openMenu === ""
				x: 0; y: panel.boxH + panel.gap
				width: panel.boxW; height: (panel.boxH - 6) / 2
			}
			Rectangle {
				visible: root.openMenu === ""
				x: 0; y: panel.boxH + panel.gap + (panel.boxH - 6) / 2 + 6
				width: panel.boxW; height: (panel.boxH - 6) / 2; radius: 10; color: colors.background
			}

			// top-left: wifi + bluetooth
			ToggleButton {
				id: wifiBtn
				x: 0; y: 0
				width: panel.boxW
				collapsedH: (panel.boxH - 6) / 2
				expandedH: panel.colH
				iconGlyph: "\uf1eb"; label: "Wi-Fi"
				isOn: Networking.wifiEnabled
				subtitle: Networking.wifiEnabled
					? (root.connectedSsid.length > 0 ? root.connectedSsid : "not connected") : "off"
				onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
				menuModel: root.sortedNetworks
				isExpanded: root.openMenu === "wifi"
				onRequestOpen: { root.openMenu = "wifi"; if (root.wifiDevice) root.wifiDevice.scannerEnabled = true }
				onRequestClose: { root.openMenu = ""; if (root.wifiDevice) root.wifiDevice.scannerEnabled = false }
				onPasswordRequested: function(network) {
					pwPrompt.ssid = network.name
					pwPrompt.network = network
					pwPrompt.visible = true
				}
				z: isExpanded ? 2 : 1
			}
			ToggleButton {
				id: btBtn
				x: 0
				width: panel.boxW
				collapsedH: (panel.boxH - 6) / 2
				expandedH: panel.colH
				iconGlyph: "\uf294"; label: "Bluetooth"
				isOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
				onToggled: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
				menuModel: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null
				isExpanded: root.openMenu === "bt"
				onRequestOpen: root.openMenu = "bt"
				onRequestClose: root.openMenu = ""
				y: isExpanded ? 0 : (wifiBtn.collapsedH + 6)
				Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
				z: isExpanded ? 2 : 1
			}
		}

		// settings content (only in settings state)
		SettingsContent {
			anchors.fill: parent
			anchors.margins: 0
			visible: root.settingsMode
			opacity: root.settingsMode ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 180 } }
			onBackRequested: root.uiState = "panel"
			onCloseRequested: root.uiState = "collapsed"
		}

		// launcher content (only in launcher state)
		LauncherContent {
			anchors.fill: parent
			active: root.launcherMode
			visible: root.launcherMode
			opacity: root.launcherMode ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 180 } }
			filterIds: root.categoryFilter
			categoryTitle: root.categoryTitle
			onCloseRequested: { root.categoryFilter = []; root.categoryTitle = ""; root.uiState = "collapsed" }
		}

		// click collapsed pill → open panel
		MouseArea {
			anchors.fill: parent
			enabled: !root.expanded
			onClicked: root.uiState = "panel"
		}
	}

	// concave notch corners beside the capsule (hidden in settings — detached)
	NotchCorner {
		side: "left"; r: root.notch; fill: colors.surface
		x: capsule.x - r; y: capsule.y
		visible: !capsule.centered
		opacity: capsule.centered ? 0 : 1
		Behavior on opacity { NumberAnimation { duration: root.animMs } }
	}
	NotchCorner {
		side: "right"; r: root.notch; fill: colors.surface
		x: capsule.x + capsule.width; y: capsule.y
		visible: !capsule.centered
		opacity: capsule.centered ? 0 : 1
		Behavior on opacity { NumberAnimation { duration: root.animMs } }
	}

	// wifi password prompt (floating window)
	WifiPassword { id: pwPrompt; visible: false }
}

}
