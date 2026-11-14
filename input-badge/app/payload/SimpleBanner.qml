/*
 * Input Badge: the banner LG shows when an input is chosen, drawn as an HDMI Sources tile.
 * Laid over LG's own InputBanner/SimpleBanner.qml by restyle.sh, with the same id, properties
 * and functions LG's other files use, so they work with it unchanged. Not LG's code.
 */

import QtQuick 2.12
import "../../../Components"
import "../BannerItems"
import "../../../../Utilities/ChannelUtils.js" as ChUtils
import "../../../../Utilities/StringUtils.js" as StringUtils
import "../../../../Constants.js" as C

Selectable {

    // An HDMI Sources tile. 320x112, square, black at 95% with the subtle
    // outline (2px light outline on dark when focused), padding 20, the input's name at 26 over the HDMI port at 20 in grey.

    id: root

    property string voiceId: "S_B"
    property var voiceValue: [inputLabelItem.text, inputNameItem.text]
    property string guide: stringSheet.ch_banner_24
    property string deviceName: interfaces[C.NAME_EXTDEVCTRL] ? interfaces[C.NAME_EXTDEVCTRL].getDeviceName() : ""
    property string inputLabel: interfaces[C.NAME_EXTDEVCTRL] ? interfaces[C.NAME_EXTDEVCTRL]._inputLabel : ""

    property int maxWidth: styleSheet.banner.inputSimpleMaxWidth
    property int sideMargin: styleSheet.banner.zappingBannerSideMargin
    property bool displayOnlyZapping: true
    property bool needFocusHandle: hasFocus
    property bool storeModeIconVisible: true
    property bool remoteControlVisible: true
    property var inputLabelFont: styleSheet.banner.inputLabelFont

    property int pad: styleSheet.guiSize(20)
    // Over HDR the TV draws its interface brighter, so the text is scaled to 60% there, as in the
    // signal toast, whose reading of the picture this uses (an id in LG's root, so looked up safely).
    property bool hdrOn: typeof rangeToast !== "undefined" && rangeToast !== null && rangeToast.hdr
    property color bright: hdrOn ? "#8e8b86" : "#ece7df"
    property color second: hdrOn ? "#625e58" : "#a39d93"
    // Eased over when the picture changes between SDR and HDR, not switched at once.
    Behavior on bright { ColorAnimation { duration: 800 } }
    Behavior on second { ColorAnimation { duration: 800 } }

    width: styleSheet.guiSize(320)
    height: styleSheet.guiSize(112)

    onClicked: if (interfaces[C.NAME_INBANNER]) interfaces[C.NAME_INBANNER].handleBannerPressed()

    Rectangle {

        id: zappingBg

        anchors.fill: parent
        color: hasFocus ? "#141310" : Qt.rgba(0, 0, 0, 0.9)
        border.width: hasFocus ? 2 : 1
        border.color: hasFocus ? root.bright : Qt.rgba(244/255, 241/255, 234/255, 0.2)
        visible: root.needFocusHandle || root.displayOnlyZapping
    }

    Column {

        id: container

        spacing: styleSheet.guiSize(2)
        anchors {
            // The same space at the sides as above and below the text.
            left: parent.left
            leftMargin: Math.round((root.height - container.height) / 2)
            right: parent.right
            rightMargin: Math.round((root.height - container.height) / 2)
            verticalCenter: parent.verticalCenter
        }

        Text {

            id: inputLabelItem

            objectName: "inputLabel"
            width: parent.width
            elide: Text.ElideRight
            font: styleSheet.regularFont(styleSheet.guiSize(26))
            color: root.bright
            text: inputLabel
            visible: inputLabel !== "" && inputLabel !== deviceName
        }

        Text {

            id: inputNameItem

            objectName: "inputName"
            width: parent.width
            elide: Text.ElideRight
            font: inputLabelItem.visible ? styleSheet.regularFont(styleSheet.guiSize(20)) : styleSheet.regularFont(styleSheet.guiSize(26))
            color: inputLabelItem.visible ? root.second : root.bright
            text: deviceName
        }
    }

    // LG's extra marks, kept for the audio guide but not drawn.
    Item { id: remoteControl; visible: false }
    Item { id: storeModeIcon; visible: false }

    function voiceSelect () {
        if (visible) {
            root.clicked();
            return true;
        }
        return false;
    }

    function getSimpleGuideText () {
        if (inputLabelItem.visible) {
            return inputNameItem.text + " " + inputLabelItem.text;
        } else {
            return inputNameItem.text;
        }
    }

    function getIconStringGuideText () {
        return "";
    }
}
