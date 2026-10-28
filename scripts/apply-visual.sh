#!/usr/bin/env bash
# Called by theme.sh; preserve unrelated INI settings and back up before edits.
set -euo pipefail
[[ $# == 1 ]] || exit 2
backup=$1
python3 - "$backup" <<'PY'
import configparser
import os
from pathlib import Path
import shutil
import subprocess
import sys
home=Path.home()
config=Path(os.environ.get('XDG_CONFIG_HOME', home/'.config'))
backup=Path(sys.argv[1])/'visual'
backup.mkdir(parents=True, exist_ok=True)
def preserve(path):
    key=path.relative_to(home) if path.is_relative_to(home) else Path('external')/str(path).lstrip('/')
    dest=backup/key
    dest.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() or path.is_symlink():
        shutil.copy2(path, str(dest)+'.link', follow_symlinks=False)
        if path.is_file(): shutil.copy2(path, dest)
    else:
        Path(str(dest)+'.absent').touch()
def ini(path, values):
    preserve(path)
    parser=configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform=str
    if path.exists(): parser.read(path)
    if not parser.has_section('Settings'): parser.add_section('Settings')
    for key,value in values.items(): parser['Settings'][key]=value
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w') as f: parser.write(f)
common={'gtk-icon-theme-name':'Papirus-Dark','gtk-font-name':'DejaVu Sans 10',
        'gtk-cursor-theme-name':'Adwaita','gtk-cursor-theme-size':'24'}
ini(config/'gtk-3.0/settings.ini', dict(common, **{'gtk-theme-name':'Arc-Dark','gtk-application-prefer-dark-theme':'1'}))
# GTK4/libadwaita gets dark preference via GSettings; no forced GTK3 stylesheet.
ini(config/'gtk-4.0/settings.ini', common)
p=home/'.gtkrc-2.0'
preserve(p)
content=p.read_text() if p.exists() else ''
values={'gtk-theme-name':'Arc-Dark', 'gtk-icon-theme-name':'Papirus-Dark', 'gtk-font-name':'DejaVu Sans 10', 'gtk-cursor-theme-name':'Adwaita', 'gtk-cursor-theme-size':24}
lines=[line for line in content.splitlines() if not any(line.lstrip().startswith(key+'=') or line.lstrip().startswith(key+' ') for key in values)]
for key,value in values.items(): lines.append(f'{key}={value}' if isinstance(value,int) else f'{key}="{value}"')
p.write_text('\n'.join(lines)+'\n')
p=config/'xsettingsd/xsettingsd.conf'
preserve(p)
values={'Net/ThemeName':'"Arc-Dark"', 'Net/IconThemeName':'"Papirus-Dark"', 'Gtk/FontName':'"DejaVu Sans 10"', 'Gtk/CursorThemeName':'"Adwaita"', 'Gtk/CursorThemeSize':'24', 'Gtk/ApplicationPreferDarkTheme':'1'}
lines=p.read_text().splitlines() if p.exists() else []
lines=[line for line in lines if not line.strip() or line.split()[0] not in values]
lines.extend(f'{key} {value}' for key,value in values.items())
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text('\n'.join(lines)+'\n')
p=config/'linux-autosetup/cursor.Xresources'
preserve(p)
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text('Xcursor.theme: Adwaita\nXcursor.size: 24\n')
# Skip D-Bus writes in isolated validation runs.
if os.environ.get('SETUP_SKIP_GSETTINGS') != '1' and shutil.which('gsettings'):
    schema='org.gnome.desktop.interface'
    schemas=subprocess.run(['gsettings','list-schemas'],capture_output=True,text=True,check=True).stdout.splitlines()
    if schema in schemas:
        values={'gtk-theme':"'Arc-Dark'", 'icon-theme':"'Papirus-Dark'", 'cursor-theme':"'Adwaita'", 'font-name':"'DejaVu Sans 10'", 'color-scheme':"'prefer-dark'"}
        old={key:subprocess.check_output(['gsettings','get',schema,key],text=True).strip() for key in values}
        import json
        (backup/'gsettings.json').write_text(json.dumps(old, indent=2)+'\n')
        for key,value in values.items(): subprocess.run(['gsettings','set',schema,key,value],check=True)
PY
