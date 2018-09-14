# -*- mode: python -*-

block_cipher = None

a = Analysis(['GUI.py'],
             pathex=['/home/cedric/Dropbox/work/ChemFlow/src/GUI'],
             binaries=[],
             datas=[
             ('img/archive.png','.'),
             ('img/process.png','.'),
             ('img/run.png','.'),
             ('img/logo.png','.'),
             ('img/logo.ico','.')
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
          name='ChemFlow',
          debug=False,
          strip=False,
          upx=True,
          runtime_tmpdir=None,
          console=True,
          icon='logo.ico')
