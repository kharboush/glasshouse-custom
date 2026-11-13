#!/usr/bin/env python3
"""
Builds the Homebrew Channel package for Input Badge: an .ipk made by LG's own
packager (ares-package, from @webos-tools/cli), plus the manifest the Homebrew
Channel's repository points at.

    ./build-ipk.py  ->  dist/<id>_<version>_all.ipk
                        dist/<id>.manifest.json

ares-package is found on PATH, or named by $ARES_PACKAGE.
"""
import hashlib, json, os, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(HERE, 'app')
DIST = os.path.join(HERE, 'dist')
REPO = 'https://github.com/kharboush/glasshouse-custom'
ICON_URI = 'https://raw.githubusercontent.com/kharboush/glasshouse-custom/main/input-badge/app/icon130.png'

info = json.load(open(os.path.join(APP, 'appinfo.json')))
APP_ID, VER = info['id'], info['version']

ares = os.environ.get('ARES_PACKAGE') or shutil.which('ares-package')
if not ares:
    sys.exit('ares-package not found: npm install -g @webos-tools/cli, or set ARES_PACKAGE')

stage = os.path.join(DIST, 'stage', APP_ID)
shutil.rmtree(os.path.join(DIST, 'stage'), ignore_errors=True)
shutil.copytree(APP, stage)
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
shutil.rmtree(os.path.join(DIST, 'stage'), ignore_errors=True)

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
