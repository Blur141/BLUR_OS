import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    width:  80
    height: 80

    property string avatarPath: ""

    // Circular clip
    Rectangle {
        id:           clipRect
        anchors.fill: parent
        radius:       width / 2
        color:        "#313244"
        border.color: "#7f5af0"
        border.width: 2
        clip:         true

        Image {
            id:           avatarImage
            anchors.fill: parent
            source:       root.avatarPath !== "" && root.avatarPath !== undefined
                              ? "file://" + root.avatarPath
                              : Qt.resolvedUrl("../assets/default-avatar.png")
            fillMode:     Image.PreserveAspectCrop
            smooth:       true
            asynchronous: true
            visible:      status === Image.Ready

            onStatusChanged: {
                if (status === Image.Error) source = Qt.resolvedUrl("../assets/default-avatar.png")
            }
        }

        // Fallback person icon when no image
        Text {
            anchors.centerIn: parent
            text:    "👤"
            font.pixelSize: 36
            visible: avatarImage.status !== Image.Ready
        }
    }

    // Glow ring
    DropShadow {
        anchors.fill: clipRect
        source:       clipRect
        radius:       12
        samples:      24
        color:        "#507f5af0"
    }
}
