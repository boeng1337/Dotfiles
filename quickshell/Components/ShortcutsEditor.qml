import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Keyboard-shortcuts editor, ported to the Colors-singleton architecture.
// Reads binds via bind_tool.py, groups them, lets you edit key/mods and
// capture a keypress, then saves via bind_tool.py setkey. No QtQuick.Controls.
Item {
	id: se
	Colors { id: colors }

	readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/scripts"

	property var groups: ({})
	property var workspace: ({ count: 5 })
	property string expandedGroup: "hyprland"
	property var edits: ({})           // id -> {super, combo, key}
	readonly property var groupOrder: ["hyprland", "quickshell", "programs", "system"]

	function groupLabel(g) {
		return g === "hyprland" ? "Hyprland"
			 : g === "quickshell" ? "Quickshell"
			 : g === "programs" ? "Programs"
			 : g === "system" ? "System" : g
	}

	Component.onCompleted: pRead.running = true
	function reload() { edits = ({}); pRead.running = true }

	// ---- read ----
	Process {
		id: pRead
		command: ["python3", se.scriptsDir + "/bind_tool.py", "read"]
		stdout: StdioCollector {
			id: readOut
			onStreamFinished: {
				try {
					var d = JSON.parse(readOut.text)
					se.groups = d.groups || ({})
					se.workspace = d.workspace || ({ count: 5 })
				} catch (e) { console.log("bind read parse error: " + e) }
			}
		}
	}

	// ---- write queue ----
	Process { id: pWrite }
	property var _queue: []
	function saveAll() {
		var q = []
		for (var id in edits) {
			var e = edits[id]
			var mods = []
			if (e.super) mods.push("SUPER")
			if (e.combo && e.combo.length > 0) mods.push(e.combo)
			q.push({ id: id, mods: mods.join(","), key: e.key })
		}
		_queue = q
		applyNext()
	}
	function applyNext() {
		if (_queue.length === 0) { reload(); return }
		var item = _queue.shift()
		pWrite.command = ["python3", se.scriptsDir + "/bind_tool.py",
			"setkey", item.id, item.mods, item.key]
		pWrite.running = true
	}
	Connections {
		target: pWrite
		function onRunningChanged() { if (!pWrite.running) se.applyNext() }
	}

	// ---- edit state helpers ----
	function stateOf(bind) {
		var _ = se.edits   // dependency: re-evaluate when edits changes
		var e = se.edits[bind.id]
		if (e) return e
		return { "super": bind.super, combo: bind.combo, key: bind.key }
	}
	function setEdit(bind, field, value) {
		var cur = Object.assign({}, stateOf(bind))
		cur[field] = value
		var next = Object.assign({}, edits)
		next[bind.id] = cur
		edits = next
	}
	function comboText(st) {
		var parts = []
		if (st.super) parts.push("SUPER")
		if (st.combo && st.combo.length > 0) parts.push(st.combo)
		if (st.key) parts.push(st.key)
		return parts.join(" + ")
	}

	// ---- Qt key event -> Hyprland keysym (incl. numpad + AZERTY) ----
	function keysymFor(event) {
		var k = event.key
		var t = event.text
		var isKeypad = (event.modifiers & Qt.KeypadModifier) !== 0
		if (isKeypad) {
			var kpm = {}
			kpm[Qt.Key_Slash] = "KP_Divide"; kpm[Qt.Key_Asterisk] = "KP_Multiply"
			kpm[Qt.Key_Minus] = "KP_Subtract"; kpm[Qt.Key_Plus] = "KP_Add"
			kpm[Qt.Key_Period] = "KP_Decimal"; kpm[Qt.Key_Enter] = "KP_Enter"
			if (kpm[k] !== undefined) return kpm[k]
			if (k >= Qt.Key_0 && k <= Qt.Key_9) return "KP_" + String.fromCharCode(k)
		}
		if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k).toUpperCase()
		if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
		var map = {}
		map[Qt.Key_Return] = "RETURN"; map[Qt.Key_Enter] = "KP_Enter"
		map[Qt.Key_Space] = "space"; map[Qt.Key_Tab] = "Tab"
		map[Qt.Key_Backspace] = "BackSpace"; map[Qt.Key_Delete] = "Delete"
		map[Qt.Key_Escape] = "Escape"; map[Qt.Key_Print] = "Print"
		map[Qt.Key_Home] = "Home"; map[Qt.Key_End] = "End"
		map[Qt.Key_PageUp] = "Prior"; map[Qt.Key_PageDown] = "Next"
		map[Qt.Key_Insert] = "Insert"; map[Qt.Key_Menu] = "Menu"
		map[Qt.Key_Up] = "Up"; map[Qt.Key_Down] = "Down"
		map[Qt.Key_Left] = "Left"; map[Qt.Key_Right] = "Right"
		if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1)
		if (map[k] !== undefined) return map[k]
		var punct = {
			"&": "ampersand", "é": "eacute", "\"": "quotedbl", "'": "apostrophe",
			"(": "parenleft", ")": "parenright", "-": "minus", "_": "underscore",
			"è": "egrave", "ç": "ccedilla", "à": "agrave", "=": "equal",
			"+": "plus", "*": "asterisk", "/": "slash", ".": "period",
			",": "comma", ";": "semicolon", ":": "colon"
		}
		if (t && punct[t] !== undefined) return punct[t]
		if (t && t.length === 1) return t
		return ""
	}

	// ================= UI =================
	Column {
		anchors.fill: parent
		anchors.margins: 4
		spacing: 10

		// group list
		Repeater {
			model: se.groupOrder
			Column {
				width: parent.width
				spacing: 4
				readonly property string gkey: modelData
				readonly property var binds: se.groups[gkey] || []
				readonly property bool isOpen: se.expandedGroup === gkey

				// group header
				Rectangle {
					width: parent.width
					height: 36
					radius: 10
					color: colors.surface
					Row {
						anchors.fill: parent
						anchors.leftMargin: 12
						anchors.rightMargin: 12
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: se.groupLabel(gkey)
							color: colors.text
							font.pixelSize: 13
							font.bold: true
							width: parent.width - 40
						}
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: binds.length + "  " + (isOpen ? "\uf078" : "\uf054")
							font.family: "Symbols Nerd Font"
							color: colors.textDim
							font.pixelSize: 11
						}
					}
					MouseArea {
						anchors.fill: parent
						onClicked: se.expandedGroup = isOpen ? "" : gkey
					}
				}

				// bind rows
				Column {
					width: parent.width
					visible: isOpen
					spacing: 4
					Repeater {
						model: isOpen ? binds : []
						Rectangle {
							id: rowRect
							required property var modelData
							// reactive current state: recomputes whenever edits changes
							readonly property var st: {
								var _ = se.edits
								var e = se.edits[modelData.id]
								return e ? e : { "super": modelData.super,
									combo: modelData.combo, key: modelData.key }
							}
							width: parent.width
							height: 40
							radius: 8
							color: Qt.rgba(colors.text.r, colors.text.g, colors.text.b, 0.03)
							opacity: modelData.editable ? 1.0 : 0.5

							Row {
								anchors.fill: parent
								anchors.leftMargin: 10
								anchors.rightMargin: 10
								spacing: 6

								// label (flexes to fill remaining space)
								Text {
									anchors.verticalCenter: parent.verticalCenter
									width: parent.width - 250   // leave room for controls
									text: rowRect.modelData.label
									color: colors.text
									font.pixelSize: 12
									elide: Text.ElideRight
								}

								// current combo text (compact, elides)
								Text {
									anchors.verticalCenter: parent.verticalCenter
									width: 70
									text: se.comboText(rowRect.st)
									color: colors.accent
									font.pixelSize: 10
									elide: Text.ElideRight
									visible: !rowRect.modelData.editable
								}

								// super toggle (editable only)
								Rectangle {
									visible: rowRect.modelData.editable
									anchors.verticalCenter: parent.verticalCenter
									width: 40; height: 22; radius: 6
									color: rowRect.st.super ? colors.accent : colors.background
									Text {
										anchors.centerIn: parent; text: "Super"
										color: rowRect.st.super ? colors.background : colors.textDim
										font.pixelSize: 9
									}
									MouseArea {
										anchors.fill: parent
										onClicked: se.setEdit(rowRect.modelData, "super",
											!rowRect.st.super)
									}
								}

								// combo cycle (none/SHIFT/CTRL/ALT)
								Rectangle {
									visible: rowRect.modelData.editable
									anchors.verticalCenter: parent.verticalCenter
									width: 40; height: 22; radius: 6
									color: rowRect.st.combo.length > 0
										? colors.accent : colors.background
									Text {
										anchors.centerIn: parent
										text: rowRect.st.combo.length > 0
											? rowRect.st.combo : "—"
										color: rowRect.st.combo.length > 0
											? colors.background : colors.textDim
										font.pixelSize: 9
									}
									MouseArea {
										anchors.fill: parent
										onClicked: {
											var cur = rowRect.st.combo
											var cycle = ["", "SHIFT", "CTRL", "ALT"]
											var i = cycle.indexOf(cur)
											se.setEdit(rowRect.modelData, "combo",
												cycle[(i + 1) % cycle.length])
										}
									}
								}

								// key capture box
								Rectangle {
									visible: rowRect.modelData.editable
									anchors.verticalCenter: parent.verticalCenter
									width: 74; height: 24; radius: 6
									color: keyField.activeFocus
										? Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.2)
										: colors.background
									border.width: keyField.activeFocus ? 1 : 0
									border.color: colors.accent
									TextInput {
										id: keyField
										anchors.fill: parent
										anchors.leftMargin: 8
										verticalAlignment: TextInput.AlignVCenter
										color: colors.text
										font.pixelSize: 11
										text: rowRect.st.key
										Keys.onPressed: (event) => {
											var sym = se.keysymFor(event)
											if (sym.length > 0) {
												se.setEdit(rowRect.modelData, "key", sym)
												text = sym
												event.accepted = true
											}
										}
										onEditingFinished: se.setEdit(rowRect.modelData, "key", text)
									}
								}
							}
						}
					}
				}
			}
		}

		// save button
		Rectangle {
			width: 100; height: 32; radius: 8
			color: saveMouse.containsMouse ? colors.accent : colors.surface
			Text {
				anchors.centerIn: parent
				text: "Save"
				color: saveMouse.containsMouse ? colors.background : colors.text
				font.pixelSize: 12; font.bold: true
			}
			MouseArea {
				id: saveMouse
				anchors.fill: parent
				hoverEnabled: true
				onClicked: se.saveAll()
			}
		}
	}
}
