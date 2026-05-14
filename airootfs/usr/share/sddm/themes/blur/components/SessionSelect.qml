import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: root
    property int initialIndex: 0

    Component.onCompleted: currentIndex = initialIndex

    textRole: "name"

    background: Rectangle {
        color:        root.pressed ? "#45475a" : "transparent"
        radius:       8
        border.color: "#3d3d52"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    contentItem: Row {
        spacing: 6
        leftPadding: 8

        Text {
            text:    "⌘"
            font.pixelSize: 13
            color:   "#585b70"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text:    root.displayText
            font.pixelSize: 13
            color:   "#6c7086"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    indicator: Text {
        x:    root.width - width - 10
        y:    (root.height - height) / 2
        text: "▾"
        font.pixelSize: 11
        color: "#45475a"
    }

    popup: Popup {
        y:     root.height + 4
        width: root.width
        padding: 4

        background: Rectangle {
            color:        "#313244"
            radius:       8
            border.color: "#45475a"
            border.width: 1
        }

        contentItem: ListView {
            implicitHeight: contentHeight
            model:          root.delegateModel
            clip:           true
        }
    }

    delegate: ItemDelegate {
        width:  root.width - 8
        height: 36

        background: Rectangle {
            color:  parent.hovered ? "#45475a" : "transparent"
            radius: 6
        }

        contentItem: Text {
            leftPadding:    12
            text:           model.name
            font.pixelSize: 13
            color:          "#a6adc8"
            verticalAlignment: Text.AlignVCenter
        }
    }
}
