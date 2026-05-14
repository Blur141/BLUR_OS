import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width:  44
    height: 44
    radius: 22
    color:  mouse.containsPress  ? "#585b70"
          : mouse.containsMouse  ? "#45475a"
                                 : "#313244"

    property string icon:    ""
    property string tooltip: ""
    signal clicked()

    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text:    root.icon
        font.pixelSize: 18
        color:   "#cdd6f4"
    }

    MouseArea {
        id:           mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()

        ToolTip.visible:  containsMouse
        ToolTip.text:     root.tooltip
        ToolTip.delay:    600
    }
}
