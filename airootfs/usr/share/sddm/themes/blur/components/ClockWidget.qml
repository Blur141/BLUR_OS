import QtQuick 2.15

Column {
    spacing: 6

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text:            Qt.formatTime(new Date(), "HH:mm")
        font.pixelSize:  72
        font.weight:     Font.Light
        color:           "#cdd6f4"
        style:           Text.Normal

        Timer {
            interval: 1000
            repeat:   true
            running:  true
            onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm")
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text:            Qt.formatDate(new Date(), "dddd, MMMM d")
        font.pixelSize:  16
        font.weight:     Font.Normal
        color:           "#a6adc8"

        Timer {
            interval: 60000
            repeat:   true
            running:  true
            onTriggered: parent.text = Qt.formatDate(new Date(), "dddd, MMMM d")
        }
    }
}
