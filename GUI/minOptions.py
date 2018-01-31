import sys, os
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QWidget, QFileDialog, QMainWindow, QDialog, QMessageBox
from forceFieldMin.UImindialog import *
from dialogSaveRestore import *

execDir = os.path.dirname(os.path.abspath(__file__))
iniParameters = os.path.realpath(os.path.join(execDir, "ini/parameters.ini"))

class DialogMin(QDialog, Ui_minDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.doubleSpinBox_restraint.setEnabled(False)
        self.comboBox_run.currentIndexChanged.connect(self.checkRestraint)
        self.comboBox_run.setCurrentText('Sander')
        self.values = {}
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['MinRun'] = self.comboBox_run.currentText()
        self.values['MinSteps'] = self.spinBox_steps.value()
        self.values['MinGBModel'] = self.comboBox_gb.currentText()
        if self.values['MinRun'] == 'Minab':
            self.values['MinRestraint'] = self.doubleSpinBox_restraint.value()
        self.close()

    def cancel(self):
        del self.values
        self.close()

    def checkRestraint(self):
        runOption = self.comboBox_run.currentText()
        if runOption == 'Minab':
            self.doubleSpinBox_restraint.setEnabled(True)
        else:
            self.doubleSpinBox_restraint.setEnabled(False)
