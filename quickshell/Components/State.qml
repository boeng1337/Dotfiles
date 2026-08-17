pragma Singleton
import QtQuick

QtObject {
    // The single source of truth both windows read.
    property bool expanded: false

    // Where the pill sits horizontally (screen X of its center),
    // so the popup can drop from the same spot. Updated by the bar.
    property real pillCenterX: 0
}
