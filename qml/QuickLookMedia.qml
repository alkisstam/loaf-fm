import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import app.loaf

// Loaded on demand by QuickLook so a missing QtMultimedia module only
// disables media previews instead of breaking the whole window.
Item {
    id: media

    property url source
    property bool isAudio: false
    property alias player: player

    function fmt(ms) {
        var s = Math.floor(ms / 1000);
        var m = Math.floor(s / 60);
        s = s % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    MediaPlayer {
        id: player
        source: media.source
        audioOutput: AudioOutput {}
        videoOutput: video
        onSourceChanged: play()
    }

    Component.onCompleted: player.play()
    Component.onDestruction: player.stop()

    VideoOutput {
        id: video
        anchors.fill: parent
        anchors.bottomMargin: controls.height + 8
        visible: !media.isAudio
    }

    LoafIcon {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -controls.height / 2
        visible: media.isAudio
        name: "music"
        size: 120
        color: theme.primary
    }

    MouseArea {
        anchors.fill: video
        onClicked: player.playing ? player.pause() : player.play()
    }

    RowLayout {
        id: controls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        spacing: 10

        LoafButton {
            icon: player.playing ? "pause" : "play"
            variant: "tonal"
            onClicked: player.playing ? player.pause() : player.play()
        }

        Text { text: media.fmt(player.position); color: theme.textMuted; font.pixelSize: 11 }

        Slider {
            id: seek
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            from: 0
            to: Math.max(1, player.duration)
            value: player.position
            enabled: player.seekable
            onMoved: player.position = value

            background: Rectangle {
                implicitWidth: 120
                implicitHeight: 4
                x: seek.leftPadding
                y: seek.topPadding + seek.availableHeight / 2 - height / 2
                width: seek.availableWidth
                height: implicitHeight
                radius: 2
                color: theme.outlineVariant

                Rectangle {
                    width: seek.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: theme.primary
                }
            }
            handle: Rectangle {
                implicitWidth: 14
                implicitHeight: 14
                x: seek.leftPadding + seek.visualPosition * (seek.availableWidth - width)
                y: seek.topPadding + seek.availableHeight / 2 - height / 2
                radius: 7
                color: theme.primary
            }
        }

        Text { text: media.fmt(player.duration); color: theme.textMuted; font.pixelSize: 11 }
    }
}
