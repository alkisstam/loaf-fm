import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import app.loaf

// QuickLook -- Finder-style preview overlay. Space toggles it, arrows step
// through the selection, Return opens the file with its default app.
Popup {
    id: ql

    property var info: ({})
    property string path: ""
    property string iconPath: ""
    readonly property string kind: info.kind || ""

    signal navigate(int dx, int dy)

    function showFor(itemPath, itemIconPath) {
        path = itemPath;
        iconPath = itemIconPath || "";
        info = JSON.parse(engine.quick_look(itemPath) || "{}");
        if (!visible)
            open();
        keyCatcher.forceActiveFocus();
    }

    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent ? parent.width * 0.78 : 900, 1100)
    height: Math.min(parent ? parent.height * 0.82 : 700, 820)
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: "#000000"
        opacity: 0.45
    }

    transformOrigin: Item.Center
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "scale"; from: 1.0; to: 0.94; duration: 120; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
        }
    }

    onClosed: info = ({})

    background: Rectangle {
        radius: theme.radiusL
        color: theme.menuSurface
        border.color: theme.borderSubtle
        border.width: 1
    }

    contentItem: Item {
        id: keyCatcher
        focus: true

        Keys.onPressed: function(event) {
            switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Escape:
                ql.close();
                break;
            case Qt.Key_Left:
                ql.navigate(-1, 0);
                break;
            case Qt.Key_Right:
                ql.navigate(1, 0);
                break;
            case Qt.Key_Up:
                ql.navigate(0, -1);
                break;
            case Qt.Key_Down:
                ql.navigate(0, 1);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                engine.open_item(ql.path);
                ql.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header: name, metadata, actions
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: ql.info.name || ""
                        color: theme.textMain
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideMiddle
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (ql.kind === "folder")
                                return ql.info.child_count + (ql.info.child_count === 1 ? " item" : " items") + "  ·  Modified " + (ql.info.modified || "-");
                            return (ql.info.size || "") + "  ·  Modified " + (ql.info.modified || "-");
                        }
                        color: theme.textMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                LoafButton {
                    text: "Open"
                    icon: "arrow-square-out"
                    variant: "tonal"
                    onClicked: {
                        if (ql.kind === "folder")
                            engine.set_path(ql.path);
                        else
                            engine.open_item(ql.path);
                        ql.close();
                    }
                }
                LoafButton {
                    icon: "x"
                    variant: "text"
                    onClicked: ql.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.separator
            }

            // Preview body
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                AnimatedImage {
                    anchors.fill: parent
                    anchors.margins: 16
                    source: (ql.kind === "image" || ql.kind === "pdf") ? (ql.info.url || "") : ""
                    visible: source.toString().length > 0 && status !== Image.Error
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    playing: visible
                }

                ScrollView {
                    id: textScroll
                    anchors.fill: parent
                    visible: ql.kind === "text"

                    TextArea {
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.NoWrap
                        textFormat: TextEdit.PlainText
                        text: ql.kind === "text"
                            ? (ql.info.text + (ql.info.truncated ? "\n\n… (preview truncated)" : ""))
                            : ""
                        color: theme.textMain
                        font.family: "monospace"
                        font.pixelSize: 12
                        leftPadding: 16
                        rightPadding: 16
                        topPadding: 12
                        bottomPadding: 12
                        background: null
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: ql.visible && (ql.kind === "video" || ql.kind === "audio")
                    source: "QuickLookMedia.qml"
                    onLoaded: {
                        item.source = Qt.binding(function() { return ql.info.url || ""; });
                        item.isAudio = Qt.binding(function() { return ql.kind === "audio"; });
                    }
                }

                // Folders and anything without a rich preview: large icon.
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: ql.kind === "folder" || ql.kind === "other"
                        || ((ql.kind === "image" || ql.kind === "pdf") && !ql.info.url)

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 128
                        Layout.preferredHeight: 128

                        LoafIcon {
                            anchors.centerIn: parent
                            visible: theme.iconSource === "phosphor" || ql.iconPath.length === 0
                            name: ql.info.icon || (ql.kind === "folder" ? "folder" : "file")
                            size: 120
                            color: ql.kind === "folder" ? theme.primary : theme.textMain
                        }
                        Image {
                            anchors.fill: parent
                            visible: theme.iconSource !== "phosphor" && ql.iconPath.length > 0
                            source: visible ? ql.iconPath : ""
                            sourceSize.width: 256
                            sourceSize.height: 256
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: ql.kind === "folder" ? "Folder" : "No preview available"
                        color: theme.textMuted
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
