import sys, os
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QWidget, QFileDialog, QMainWindow, QDialog
from runLocally.UIrunlocallydialog import *
from runPBS.UIrunpbsdialog import *
from runSlurm.UIrunslurmdialog import *
from dialogSaveRestore import *

def defaultRunParameters(runOption):
    if runOption == 'Locally':
        return {'numberCores':os.cpu_count()}
    elif runOption == 'PBS':
        return {'numberNodes':1,'numberPpn':1,'walltime':'24:00:00'}
    elif runOption == 'Slurm':
        return {'numberNodes':1,'numberPpn':1,'walltime':'24:00:00'}

execDir = os.path.dirname(os.path.abspath(__file__))
iniParameters = os.path.realpath(os.path.join(execDir, "ini/parameters.ini"))
iniPaths = os.path.realpath(os.path.join(execDir, "ini/paths.ini"))

class DialogRunLocally(QDialog, Ui_RunLocallyDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.spinBox.setValue(os.cpu_count())
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.values = {}
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['numberCores'] = self.spinBox.value()
        self.close()

    def cancel(self):
        self.close()

class DialogRunPBS(QDialog, Ui_RunPBSDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.comboBox.setCurrentText("24:00:00")
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.values = {}
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['numberNodes'] = self.spinBox_nodes.value()
        self.values['numberPpn'] = self.spinBox_ppn.value()
        self.values['walltime'] = self.comboBox.currentText()
        self.close()

    def cancel(self):
        self.close()

class DialogRunSlurm(QDialog, Ui_RunSlurmDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.comboBox.setCurrentText("24:00:00")
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.values = {}
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['numberNodes'] = self.spinBox_nodes.value()
        self.values['numberPpn'] = self.spinBox_ppn.value()
        self.values['walltime'] = self.comboBox.currentText()
        self.close()

    def cancel(self):
        self.close()
