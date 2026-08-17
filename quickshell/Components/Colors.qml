import QtQuick
import "."

// Catppuccin colors: Mocha (dark) / Latte (light), with a chosen accent.
// darkMode drives the flavor; accentName picks the accent from that flavor.
// Everything reads colors.X, so changes re-theme the whole shell live.
Item {
	id: root

	readonly property bool dark: Config.appearance.darkMode
	readonly property string accentName: Config.appearance.accentName

	// ---- base/surface/text roles per flavor ----
	readonly property color background: dark ? "#1e1e2e" : "#eff1f5"  // base
	readonly property color surface:    dark ? "#313244" : "#ccd0da"  // surface0
	readonly property color text:       dark ? "#cdd6f4" : "#4c4f69"
	readonly property color textDim:    dark ? "#a6adc8" : "#6c6f85"  // subtext0

	// ---- the 14 accents, both flavors ----
	readonly property var mochaAccents: ({
		"rosewater":"#f5e0dc","flamingo":"#f2cdcd","pink":"#f5c2e7","mauve":"#cba6f7",
		"red":"#f38ba8","maroon":"#eba0ac","peach":"#fab387","yellow":"#f9e2af",
		"green":"#a6e3a1","teal":"#94e2d5","sky":"#89dceb","sapphire":"#74c7ec",
		"blue":"#89b4fa","lavender":"#b4befe"
	})
	readonly property var latteAccents: ({
		"rosewater":"#dc8a78","flamingo":"#dd7878","pink":"#ea76cb","mauve":"#8839ef",
		"red":"#d20f39","maroon":"#e64553","peach":"#fe640b","yellow":"#df8e1d",
		"green":"#40a02b","teal":"#179299","sky":"#04a5e5","sapphire":"#209fb5",
		"blue":"#1e66f5","lavender":"#7287fd"
	})

	// resolved accent from the active flavor + chosen name
	readonly property color accent: {
		var tbl = dark ? mochaAccents : latteAccents
		return tbl[accentName] !== undefined ? tbl[accentName] : tbl["blue"]
	}

	// status colors (fixed roles)
	readonly property color good:    dark ? "#a6e3a1" : "#40a02b"
	readonly property color warning: dark ? "#f9e2af" : "#df8e1d"
	readonly property color danger:  dark ? "#f38ba8" : "#d20f39"

	// derived translucency
	readonly property color muted: Qt.rgba(text.r, text.g, text.b, 0.45)
	readonly property color line:  Qt.rgba(text.r, text.g, text.b, 0.10)
	readonly property color hover: Qt.rgba(text.r, text.g, text.b, 0.10)

	// list of accent names for the picker UI
	readonly property var accentList: ["blue","lavender","mauve","pink","red",
		"peach","yellow","green","teal","sky","sapphire","maroon","flamingo","rosewater"]

	function accentHex(name) {
		var tbl = dark ? mochaAccents : latteAccents
		return tbl[name] !== undefined ? tbl[name] : tbl["blue"]
	}

	function fgOn(c) {
		return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) > 0.6
			? background : "#ffffff"
	}
}
