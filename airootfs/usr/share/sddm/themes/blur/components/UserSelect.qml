import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: root
    property alias currentIndex: root.currentIndex

    background: Rectangle {
        color:        root.pressed ? "#45475a" : "#313244"
        radius:       8
        border.color: root.activeFocus ? "#7f5af0" : "#45475a"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    contentItem: Text {
        leftPadding: 12
        text:        root.displayText
        font.pixelSize: 14
        color:       "#cdd6f4"
        verticalAlignment: Text.AlignVCenter
    }

    indicator: Text {
        x:    root.width - width - 12
        y:    (root.height - height) / 2
        text: "▾"
        font.pixelSize: 12
        color: "#6c7086"
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
        height: 40

        background: Rectangle {
            color:  parent.hovered ? "#45475a" : "transparent"
            radius: 6
        }

        contentItem: Text {
            leftPadding:    12
            text:           modelData
            font.pixelSize: 14
            color:          "#cdd6f4"
            verticalAlignment: Text.AlignVCenter
        }
    }
}
