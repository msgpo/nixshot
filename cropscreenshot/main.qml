import QtQuick 2.5
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0

Window {
    id: main
    visible: true
    flags: Qt.FramelessWindowHint | Qt.X11BypassWindowManagerHint | Qt.WindowStaysOnTopHint
    width: image.sourceSize.width
    height: image.sourceSize.height
    property rect crop
    property string inFilename: ""
    property int cursorX: 0
    property int cursorY: 0
    property string imageUrl: 'file://' + inFilename
    property bool isCropping: false
    property bool exitOnRelease: true

    signal regionSelected(rect region)
    signal quitApp(int exitCode)

    function finish() {
        regionSelected(crop)
        Qt.quit();
    }

    function reset() {
        main.isCropping = false
        crop.x = 0
        crop.y = 0
        crop.width = 0
        crop.height = 0
    }

    Component.onCompleted: {
        requestActivate()
    }

    Item {
        focus: true

        Keys.onReturnPressed: {
            console.log('onReturnPressed')
            if (crop.width > 0 && crop.height > 0) {
                main.finish()
            }
        }

        Keys.onEscapePressed: {
            console.log('onEscapePressed')
            if (main.isCropping) {
                main.reset()
            } else {
                quitApp(1)
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        // cursorShape: Qt.ArrowCursor // http://doc.qt.io/qt-5/qt.html#CursorShape-enum

        onPressed: {
            main.isCropping = true
            crop.x = mouse.x
            crop.y = mouse.y
            crop.width = 1
            crop.height = 1
        }
        onPositionChanged: {
            cursorX = mouse.x
            cursorY = mouse.y

            if (pressed && main.isCropping) {
                crop.width = mouse.x - crop.x + 1
                crop.height = mouse.y - crop.y + 1
            }
        }

        onReleased: {
            if (main.isCropping && main.exitOnRelease) {
                main.finish()
            }
        }
    }

    Image {
        id: image
        source: imageUrl

        Rectangle {
            id: dimOverlay
            anchors.fill: parent
            color: "#000"
            opacity: 0.5
            visible: true
        }
    }

    Rectangle {
        id: cropRect
        x: crop.x
        y: crop.y
        width: crop.width
        height: crop.height

        clip: true
        Image {
            id: croppedImage
            source: imageUrl
            x: -crop.x
            y: -crop.y
        }
    }

    Rectangle {
        id: cropOutline
        anchors.fill: cropRect
        color: "transparent"
        border.color: "black"
        border.width: 1
    }

    property int zoomPixels: 9
    property int zoomScale: 16
    Rectangle {
        id: magnifier
        x: (cursorX + 10 + width) <= image.sourceSize.width ? cursorX + 10 : cursorX - width - 10
        y: (cursorY + 10 + height) <= image.sourceSize.height ? cursorY + 10 : cursorY - height - 10
        width: zoomPixels * zoomScale
        height: zoomPixels * zoomScale
        color: "black"
        border.color: "black"
        border.width: 1
        clip: true

        Image {
            id: imageZoom
            source: imageUrl

            x: -cursorX*scale + parent.width/2 - scale/2
            y: -cursorY*scale + parent.height/2 - scale/2
            scale: zoomScale
            smooth: false // Don't blur when scaling
            transformOrigin: Item.TopLeft
        }

        Rectangle {
            color: "transparent"
            border.color: "white"
            border.width: 1
            x: parent.width/2 - imageZoom.scale/2 - 1
            y: 0
            width: imageZoom.scale + 2
            height: parent.height
        }
        Rectangle {
            color: "transparent"
            border.color: "white"
            border.width: 1
            x: 0
            y: parent.width/2 - imageZoom.scale/2 - 1
            width: parent.width
            height: imageZoom.scale + 2
        }
        Rectangle {
            color: "transparent"
            border.color: "black"
            border.width: 1
            x: parent.width/2 - imageZoom.scale/2
            y: 0
            width: imageZoom.scale
            height: parent.height
        }
        Rectangle {
            color: "transparent"
            border.color: "black"
            border.width: 1
            x: 0
            y: parent.width/2 - imageZoom.scale/2
            width: parent.width
            height: imageZoom.scale
        }
    }

    property bool showPositionAndSize: true
    Item {
        id: pointPositionOverlay
        visible: showPositionAndSize && crop.width != 0 && crop.height != 0
        x: crop.x
        y: crop.y - height - 4
        width: pointPositionText.implicitWidth + padding * 2
        height: pointPositionText.implicitHeight + padding * 2
        property int padding: 2

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.75
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "black"
            border.width: 1
        }

        Text {
            id: pointPositionText
            color: "white"
            anchors.fill: parent
            anchors.margins: parent.padding
            textFormat: Text.RichText
            text: "<b>X:</b> " + crop.x + " <b>Y:</b> " + crop.y + " <b>W:</b> " + crop.width + " <b>H:</b> " + crop.height
        }
    }

    Item {
        id: cursorPositionOverlay
        visible: showPositionAndSize
        x: magnifier.x + magnifier.width/2 - width/2
        y: magnifier.y + magnifier.height + 4
        width: cursorPositionText.implicitWidth + padding * 2
        height: cursorPositionText.implicitHeight + padding * 2
        property int padding: 2


        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.75
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "black"
            border.width: 1
        }

        Text {
            id: cursorPositionText
            color: "white"
            anchors.fill: parent
            anchors.margins: parent.padding
            textFormat: Text.RichText
            text: "<b>X:</b> " + cursorX + " <b>Y:</b> " + cursorY
        }
    }

    property bool showHelp: true
    Item {
        id: helpOverlay
        visible: showHelp
        x: cursorX <= image.sourceSize.width/2 ? image.sourceSize.width - 10 - width : 10 // Opposite side
        y: 10
        width: helpText.implicitWidth + padding * 2
        height: helpText.implicitHeight + padding * 2
        property int padding: 10

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.75
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "black"
            border.width: 1
        }

        Text {
            id: helpText
            color: "white"
            anchors.fill: parent
            anchors.margins: parent.padding
            textFormat: Text.RichText
            text: {
                var lines = [
                    // "[F1] Hide Tips",
                    // "",
                    "[Hold left click] Start region selection",
                    "[Esc] Cancel capture",
                    // "",
                    // "[Space] Fullscreen capture",
                    // "",
                    // "[Mouse wheel] Change magnifier pixel count",
                    // "[Ctrl + Mouse wheel] Change magnifier pixel size",
                    // "[I] Hide position and size info",
                    // "[M] Hide magnifier",
                    // "[C] Show screen wide crosshair"
                    

                ];

                return lines.join('<br>');
            }
        }
    }
    

}

