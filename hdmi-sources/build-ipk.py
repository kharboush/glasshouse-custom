#!/usr/bin/env python3
"""
Builds the Homebrew Channel package for the HDMI Sources: an .ipk made by LG's own
packager (ares-package, from @webos-tools/cli), plus the manifest the Homebrew
Channel's repository points at. The app's version, from app/appinfo.json, is filled
in for @VERSION@ in the launcher and in the panel page, which is how the launcher
tells that the page on Glasshouse's server is out of date.

    ./build-ipk.py  ->  dist/<id>_<version>_all.ipk
                        dist/<id>.manifest.json

ares-package is found on PATH, or named by $ARES_PACKAGE.
"""
import hashlib, json, os, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(HERE, 'app')
DIST = os.path.join(HERE, 'dist')
REPO = 'https://github.com/kharboush/glasshouse-custom'
ICON_URI = 'https://raw.githubusercontent.com/kharboush/glasshouse-custom/main/hdmi-sources/app/icon130.png'
FILL = ('index.html', os.path.join('payload', 'hdmi-sources.html'))

info = json.load(open(os.path.join(APP, 'appinfo.json')))
APP_ID, VER = info['id'], info['version']

ares = os.environ.get('ARES_PACKAGE') or shutil.which('ares-package')
if not ares:
    sys.exit('ares-package not found: npm install -g @webos-tools/cli, or set ARES_PACKAGE')

work = os.path.join(DIST, 'stage')
stage = os.path.join(work, APP_ID)
shutil.rmtree(work, ignore_errors=True)
shutil.copytree(APP, stage)
for rel in FILL:
    path = os.path.join(stage, rel)
    text = open(path, encoding='utf-8').read()
    if '@VERSION@' not in text:
        sys.exit(rel + ' has no @VERSION@ to fill in')
    open(path, 'w', encoding='utf-8').write(text.replace('@VERSION@', VER))
for name in os.listdir(os.path.join(stage, 'payload')):
    if name.endswith('.sh'):
        os.chmod(os.path.join(stage, 'payload', name), 0o755)

ipk_name = '%s_%s_all.ipk' % (APP_ID, VER)
ipk_path = os.path.join(DIST, ipk_name)
if os.path.exists(ipk_path):
    os.remove(ipk_path)
run = subprocess.run([ares, '--no-minify', '--outdir', DIST, stage], capture_output=True, text=True)
if run.returncode != 0 or not os.path.isfile(ipk_path):
    sys.exit('ares-package failed:\n' + run.stdout + run.stderr)
shutil.rmtree(work, ignore_errors=True)

ipk = open(ipk_path, 'rb').read()
manifest = {
    'id': APP_ID, 'version': VER, 'type': 'web', 'title': info['title'],
    'appDescription': info['appDescription'], 'iconUri': ICON_URI, 'sourceUrl': REPO,
    'rootRequired': True, 'ipkUrl': ipk_name,
    'ipkHash': {'sha256': hashlib.sha256(ipk).hexdigest()},
}
with open(os.path.join(DIST, APP_ID + '.manifest.json'), 'w') as f:
    json.dump(manifest, f, indent=2)
    f.write('\n')
print('%s  %d KB' % (ipk_name, len(ipk) // 1024))
