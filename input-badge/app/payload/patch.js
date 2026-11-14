/*
 * Builds the banner files and the signal toast from this TV's own copies of LG's:
 *   node patch.js <LG's input app qml folder> <this payload folder> <output folder>
 * InputBanner.qml and BannerListView.qml are LG's, with a few exact replacements; SimpleBanner.qml
 * is this package's own. Every replacement must match exactly once, and LG's SimpleBanner must
 * still have what ours stands in for, or nothing is written and the script exits non-zero, so a
 * firmware that changes these files keeps LG's banner.
 */
var fs = require('fs');
var path = require('path');
var Q = process.argv[2], P = process.argv[3], OUT = process.argv[4];

var MV = 'UserInterfaceLayer/Containers/MainViewLayer/';
function read(f) { return fs.readFileSync(path.join(Q, f), 'utf8'); }
function swap(s, from, to, what) {
  if (s.split(from).length !== 2) throw new Error(what + ': not as expected in LG\'s file');
  return s.replace(from, function () { return to; });
}

try {
  var sb = read(MV + 'InputBanner/SimpleBanner.qml');
  ['Selectable {', 'getDeviceName()', '._inputLabel', 'function voiceSelect',
   'function getSimpleGuideText', 'function getIconStringGuideText'].forEach(function (m) {
    if (sb.indexOf(m) < 0) throw new Error('SimpleBanner: LG\'s file has changed (' + m + ')');
  });

  // The banner: a 112-high row, 32 in from the side, on a black box with a faint outline in
  // place of LG's two background pictures.
  var ib = read(MV + 'InputBanner/InputBanner.qml');
  ib = swap(ib, 'height: visible ? styleSheet.banner.zappingBannerHeight + recInfoIcon.heightWithMargin : 0',
    'height: visible ? styleSheet.guiSize(112) + recInfoIcon.heightWithMargin : 0', 'banner height');
  ib = swap(ib, '        width: childrenRect.width\n        height: styleSheet.banner.zappingBannerHeight\n        anchors {\n            left: parent.left\n',
    '        width: childrenRect.width\n        height: styleSheet.guiSize(112)\n        anchors {\n            left: parent.left\n            leftMargin: styleSheet.guiSize(32)\n',
    'banner row');
  ib = swap(ib, 'source: root.visible ? styleSheet.banner.middleBg : ""', 'source: ""', 'background');
  ib = swap(ib, 'source: root.visible ? styleSheet.banner.rightBg : ""', 'source: ""', 'background edge');
  ib = swap(ib, '        anchors.fill: bannerRow\n',
    '        anchors.fill: bannerRow\n\n' +
    '        Rectangle {\n' +
    '            anchors.fill: parent\n' +
    '            color: Qt.rgba(0, 0, 0, 0.9)\n' +
    '            border.width: 1\n' +
    '            border.color: Qt.rgba(244/255, 241/255, 234/255, 0.2)\n' +
    '        }\n', 'background box');

  // An input's banner keeps LG's own position setting (top or "bottom", left or right). At the top
  // it sits 32 down. LG's "bottom" is in fact the middle of the screen, so there it keeps LG's
  // height on screen, centred on where LG's taller banner was. The sides follow from the row's
  // 32 margin, which LG's mirroring moves to the right when the banner is on the right. The
  // channel banner, the detail view and Live Pick keep LG's places.
  var bl = read(MV + 'BannerItems/BannerListView.qml');
  bl = swap(bl, '                return styleSheet.banner.tZappingBannerTopMargin;',
    '                return isChannel ? styleSheet.banner.tZappingBannerTopMargin : styleSheet.guiSize(32);',
    'banner place at the top');
  bl = swap(bl, '            return bannerTopMargin;\n        }\n    }',
    '            if (!isChannel) {\n                return bannerTopMargin + (styleSheet.banner.zappingBannerHeight - styleSheet.guiSize(112)) / 2;\n            }\n            return bannerTopMargin;\n        }\n    }',
    'banner place in the middle');

  // The signal toast: this package's own block, added inside LG's root just before its last brace,
  // with the import its service watchers need.
  var rw = read('RootWindow.qml');
  if (rw.indexOf('FocusScope {') < 0 || rw.indexOf('property alias styleSheet') < 0) throw new Error('RootWindow: LG\'s file has changed');
  rw = swap(rw, 'import QtQuick 2.12\n', 'import QtQuick 2.12\nimport WebOSServices 1.0\n', 'imports');
  var end = rw.lastIndexOf('}');
  if (end < 0) throw new Error('RootWindow: no closing brace');
  rw = rw.slice(0, end).replace(/\s+$/, '') + '\n\n' + fs.readFileSync(path.join(P, 'signal-toast.qml.part'), 'utf8') + '}\n';

  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, 'InputBanner.qml'), ib);
  fs.writeFileSync(path.join(OUT, 'BannerListView.qml'), bl);
  fs.writeFileSync(path.join(OUT, 'RootWindow.qml'), rw);
  fs.writeFileSync(path.join(OUT, 'SimpleBanner.qml'), fs.readFileSync(path.join(P, 'SimpleBanner.qml')));
  console.log('built');
} catch (e) {
  console.log(e.message);
  process.exit(1);
}
