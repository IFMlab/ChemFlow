# -*- mode: python -*-

block_cipher = None

a = Analysis(['GUI.py'],
             pathex=['/usr/lib/qt/plugins/platforms'],
             binaries=[],
             datas=[
             ('img/archive.png','img'),
             ('img/process.png','img'),
             ('img/run.png','img'),
             ('img/logo.png','img'),
             ('img/logo.ico','img')
             ],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)

pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='chemflow',
          debug=False,
          strip=False,
          upx=True,
          runtime_tmpdir=None,
          console=True,
          icon='logo.ico')
