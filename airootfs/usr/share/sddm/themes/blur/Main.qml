import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

import "components"

Rectangle {
    id: root
    width:  Screen.width
    height: Screen.height
    color:  "#1e1e2e"

    // ── Background ───────────────────────────────────────────
    Image {
        id: bgImage
        anchors.fill: parent
        source: config.background !== "" ? config.background
                                         : Qt.resolvedUrl("assets/default.jpg")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false

        layer.enabled: true
        layer.effect: FastBlur {
            radius: 48
        }
    }

    // Dark tint over blurred background
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: 0.55
    }

    // ── Clock & date ─────────────────────────────────────────
    ClockWidget {
        anchors {
            top:              parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin:        root.height * 0.1
        }
    }

    // ── Login card ───────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  420
        height: cardColumn.implicitHeight + 56
        radius: 16
        color:  "#20313244"
        border.color: "#30cdd6f4"
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            radius:         24
            samples:        48
            color:          "#801e1e2e"
            verticalOffset: 8
        }

        // Glass blur behind the card
        FastBlur {
            anchors.fill: parent
            source:       bgImage
            radius:       40
        }

        // Card surface tint on top of blur
        Rectangle {
            anchors.fill: parent
            radius:       parent.radius
            color:        "#cc1e1e2e"
        }

        ColumnLayout {
            id:            cardColumn
            anchors {
                top:              parent.top
                left:             parent.left
                right:            parent.right
                topMargin:        28
                leftMargin:       28
                rightMargin:      28
                bottomMargin:     28
            }
            spacing: 16

            // ── Avatar ───────────────────────────────────────
            UserAvatar {
                id: userAvatar
                Layout.alignment: Qt.AlignHCenter
                avatarPath: userModel.data(
                    userModel.index(userList.currentIndex, 0),
                    Qt.UserRole + 5   // IconRole
                )
            }

            // ── Username display ──────────────────────────────
            Text {
                id: userDisplay
                Layout.alignment: Qt.AlignHCenter
                text: userModel.data(
                    userModel.index(userList.currentIndex, 0),
                    Qt.UserRole + 2   // NameRole → display name
                ) || sddm.lastUser
                font.pixelSize: 18
                font.weight:    Font.Medium
                color:          "#cdd6f4"
            }

            // ── User selector (if more than one user) ─────────
            UserSelect {
                id:               userList
                Layout.fillWidth: true
                visible:          userModel.rowCount() > 1
                model:            userModel
            }

            // ── Password field ───────────────────────────────
            Rectangle {
                id:               passwordBox
                Layout.fillWidth: true
                height:           48
                radius:           8
                color:            "#313244"
                border.color:     passwordInput.activeFocus ? "#7f5af0" : "#45475a"
                border.width:     1

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                TextInput {
                    id:              passwordInput
                    anchors {
                        left:         parent.left
                        right:        showPasswordBtn.left
                        verticalCenter: parent.verticalCenter
                        leftMargin:   16
                        rightMargin:  8
                    }
                    echoMode:        showPassword.checked
                                         ? TextInput.Normal
                                         : TextInput.Password
                    passwordCharacter: "●"
                    font.pixelSize:  15
                    color:           "#cdd6f4"
                    placeholderText: "Password"
                    placeholderTextColor: "#6c7086"
                    selectByMouse:   true
                    focus:           true

                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed:  doLogin()

                    Keys.onEscapePressed: {
                        passwordInput.text = ""
                        statusLabel.text   = ""
                    }
                }

                // Show / hide toggle
                CheckBox {
                    id:       showPassword
                    anchors {
                        right:         parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin:   8
                    }
                    checked:  false
                    indicator: Item {
                        width:  28
                        height: 28
                        Text {
                            anchors.centerIn: parent
                            text:  showPassword.checked ? "🙈" : "👁"
                            font.pixelSize: 16
                        }
                    }
                }
            }

            // ── Status / error message ────────────────────────
            Text {
                id:               statusLabel
                Layout.fillWidth: true
                text:             ""
                color:            "#f38ba8"
                font.pixelSize:   13
                horizontalAlignment: Text.AlignHCenter
                wrapMode:         Text.WordWrap
                visible:          text !== ""
            }

            // ── Login button ─────────────────────────────────
            Rectangle {
                id:               loginBtn
                Layout.fillWidth: true
                height:           48
                radius:           8
                color:            loginMouse.containsPress  ? "#6642c9"
                                : loginMouse.containsMouse ? "#9068f0"
                                                            : "#7f5af0"
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text:        "Sign In"
                    color:       "#cdd6f4"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }

                MouseArea {
                    id:          loginMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked:   doLogin()
                }
            }

            // ── Session selector ──────────────────────────────
            SessionSelect {
                id:               sessionSelector
                Layout.fillWidth: true
                model:            sessionModel
                initialIndex:     sessionModel.lastIndex
            }
        }
    }

    // ── Power buttons ────────────────────────────────────────
    Row {
        anchors {
            bottom:       parent.bottom
            right:        parent.right
            bottomMargin: 24
            rightMargin:  24
        }
        spacing: 12

        ActionButton {
            icon:    "⏸"
            tooltip: "Suspend"
            onClicked: sddm.suspend()
        }
        ActionButton {
            icon:    "↺"
            tooltip: "Reboot"
            onClicked: sddm.reboot()
        }
        ActionButton {
            icon:    "⏻"
            tooltip: "Shut Down"
            onClicked: sddm.powerOff()
        }
    }

    // ── Hostname label ────────────────────────────────────────
    Text {
        anchors {
            bottom:      parent.bottom
            left:        parent.left
            bottomMargin: 24
            leftMargin:  24
        }
        text:           sddm.hostName
        color:          "#45475a"
        font.pixelSize: 13
    }

    // ── Keyboard layout indicator ─────────────────────────────
    Text {
        anchors {
            bottom:      parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 24
        }
        text:           keyboard.layouts[keyboard.currentLayout] !== undefined
                            ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase()
                            : "EN"
        color:          "#585b70"
        font.pixelSize: 13
    }

    // ── SDDM connection ───────────────────────────────────────
    Connections {
        target: sddm

        function onLoginFailed() {
            passwordInput.text  = ""
            statusLabel.text    = "Incorrect password. Try again."
            passwordInput.focus = true

            shakeAnim.start()
        }

        function onLoginSucceeded() {
            statusLabel.text  = ""
            card.opacity      = 0
        }
    }

    // ── Card shake on bad password ────────────────────────────
    SequentialAnimation {
        id: shakeAnim
        property real origin: card.x
        NumberAnimation { target: card; property: "x"; to: card.x - 12; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: card; property: "x"; to: card.x + 12; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: card; property: "x"; to: card.x - 8;  duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: card; property: "x"; to: card.x + 8;  duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: card; property: "x"; to: card.x;      duration: 40; easing.type: Easing.InOutQuad }
    }

    // ── Card fade-out on login ────────────────────────────────
    Behavior on opacity { NumberAnimation { duration: 400 } }

    // ── Keyboard ──────────────────────────────────────────────
    KeyboardModel { id: keyboard }

    // ── Login helper ─────────────────────────────────────────
    function doLogin() {
        var username = userModel.data(
            userModel.index(userList.currentIndex, 0),
            Qt.UserRole + 1   // LoginRole
        ) || sddm.lastUser

        if (passwordInput.text === "") {
            statusLabel.text = "Enter your password."
            return
        }

        statusLabel.text = ""
        sddm.login(username, passwordInput.text, sessionSelector.currentIndex)
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
