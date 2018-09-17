import os, sys
from PyQt5 import QtGui
from PyQt5.QtWidgets import QDialog, QFileDialog
from PyQt5.QtCore import QSettings
from qt_creator.UIrun_local import Ui_RunLocal
from qt_creator.UIrun_pbs import Ui_RunPbs
from qt_creator.UIrun_slurm import Ui_RunSlurm
from utils import (
    WORKDIR, INI_FILE, EMPTY_VALUES,
    guiSave, guiRestore,
    missingParametersDialog, errorDialog,
)


class DialogRunLocal(QDialog, Ui_RunLocal):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        self.spinBox_cores.setValue(os.cpu_count())
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['NumCores'] = self.spinBox_cores.value()
        self.close()


class DialogRunPbs(QDialog, Ui_RunPbs):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        self.pushButton_header.clicked.connect(self.browse_header)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['NumNodes'] = self.spinBox_nodes.value()
        self.values['NumCores'] = self.spinBox_cores.value()
        self.values['HeaderFile'] = self.lineEdit_header.text()
        self.close()

    def browse_header(self):
        filetypes =  "All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select header file for PBS", os.getcwd(), filetypes)
        if value:
            self.lineEdit_header.setText(value)


class DialogRunSlurm(QDialog, Ui_RunSlurm):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        self.pushButton_header.clicked.connect(self.browse_header)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['NumNodes'] = self.spinBox_nodes.value()
        self.values['NumCores'] = self.spinBox_cores.value()
        self.values['HeaderFile'] = self.lineEdit_header.text()
        self.close()

    def browse_header(self):
        filetypes =  "All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select header file for SLURM", os.getcwd(), filetypes)
        if value:
            self.lineEdit_header.setText(value)
