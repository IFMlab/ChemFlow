import sys, os
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QWidget, QFileDialog, QMainWindow, QDialog, QMessageBox
from rescoreVina.UIrescorevinadialog import *
from rescorePlants.UIrescoreplantsdialog import *
from dockOptions import DialogWaterPlants
from rescoreMmpbsa.UIrescoremmpbsadialog import *
from MD.UImddialog import *
from dialogSaveRestore import *

class DialogRescoreVina(QDialog, Ui_rescoreVinaDialog):
    settings = QSettings("ini/parameters.ini", QSettings.IniFormat)
    globalSettings = QSettings("ini/paths.ini", QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.pushButton_exec.clicked.connect(self.selectVinaExec)
        self.pushButton_adtFolder.clicked.connect(self.selectADTFolder)
        self.values = {}
        guiRestore(self, self.settings)
        restoreUsefullPaths(self, self.globalSettings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        saveUsefullPaths(self, self.globalSettings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['RescoreCenterX'] = self.doubleSpinBox_cx.value()
        self.values['RescoreCenterY'] = self.doubleSpinBox_cy.value()
        self.values['RescoreCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['RescoreSizeX'] = self.spinBox_sx.value()
        self.values['RescoreSizeY'] = self.spinBox_sy.value()
        self.values['RescoreSizeZ'] = self.spinBox_sz.value()
        self.values['VinaExec'] = self.textBrowser_vinaExec.toPlainText()
        self.values['ADTFolder'] = self.textBrowser_adtFolder.toPlainText()
        missing = []
        for i in ['VinaExec', 'ADTFolder']:
            try:
                self.values[i]
            except KeyError:
                missing.append(i)
            else:
                if self.values[i] == '':
                    del self.values[i]
                    missing.append(i)
        if missing:
            self.missingParameters(missing)
        else:
            self.close()

    def cancel(self):
        del self.values
        self.close()

    def selectVinaExec(self):
        value, _ = QFileDialog.getOpenFileName(None,"Select Vina executable", '/', "All Files (*)")
        if value:
            self.textBrowser_vinaExec.setPlainText(value)

    def selectADTFolder(self):
        value = QFileDialog.getExistingDirectory(None, "Select directory of AutoDockTools", '/')
        if value:
            self.textBrowser_adtFolder.setPlainText(value)

    def missingParameters(self, missing):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setText("You must configure the following parameters:")
        msg.setInformativeText(', '.join(missing))
        msg.setWindowTitle("Error: Missing parameters")
        msg.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        retval = msg.exec_()
        if retval == 1024: # Ok
            msg.close()
        elif retval == 4194304: # Cancel
            self.close()

class DialogRescorePlants(QDialog, Ui_rescorePlantsDialog):
    settings = QSettings("ini/parameters.ini", QSettings.IniFormat)
    globalSettings = QSettings("ini/paths.ini", QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_water.setEnabled(False)
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.pushButton_PlantsExec.clicked.connect(self.selectPlantsExec)
        self.pushButton_SporesExec.clicked.connect(self.selectSporesExec)
        self.pushButton_water.clicked.connect(self.configureWater)
        self.checkBox_water.stateChanged.connect(self.checkConfigureWater)
        self.values = {}
        guiRestore(self, self.settings)
        restoreUsefullPaths(self, self.globalSettings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        saveUsefullPaths(self, self.globalSettings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['ScoringFunction'] = self.comboBox_scoringFunction.currentText()
        self.values['PlantsExec'] = self.textBrowser_PlantsExec.toPlainText()
        self.values['SporesExec'] = self.textBrowser_SporesExec.toPlainText()
        missing = []
        test_missing = ['PlantsExec','SporesExec']
        if self.checkBox_water.isChecked():
            test_missing.append('WaterFile')
        for i in test_missing:
            try:
                self.values[i]
            except KeyError:
                missing.append(i)
            else:
                if self.values[i] == '':
                    del self.values[i]
                    missing.append(i)
        if missing:
            self.missingParameters(missing)
        else:
            self.close()

    def cancel(self):
        del self.values
        self.close()

    def selectPlantsExec(self):
        value, _ = QFileDialog.getOpenFileName(None,"Select PLANTS executable", '/', "All Files (*)")
        if value:
            self.textBrowser_PlantsExec.setPlainText(value)

    def selectSporesExec(self):
        value, _ = QFileDialog.getOpenFileName(None,"Select SPORES executable", '/', "All Files (*)")
        if value:
            self.textBrowser_SporesExec.setPlainText(value)

    def checkConfigureWater(self):
        if self.checkBox_water.isChecked():
            self.pushButton_water.setEnabled(True)
        else:
            self.pushButton_water.setEnabled(False)

    def configureWater(self):
        waterDialog = DialogWaterPlants()
        waterDialog.exec_()
        try:
            waterDialog.values
        except AttributeError:
            pass
        else:
            for i in ['WaterCenterX','WaterCenterY','WaterCenterZ','WaterRadius','WaterFile']:
                self.values[i] = waterDialog.values[i]

    def missingParameters(self, missing):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setText("You must configure the following parameters:")
        msg.setInformativeText(', '.join(missing))
        msg.setWindowTitle("Error: Missing parameters")
        msg.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        retval = msg.exec_()
        if retval == 1024: # Ok
            msg.close()
        elif retval == 4194304: # Cancel
            self.close()

class DialogRescoreMmpbsa(QDialog, Ui_rescoreMmpbsaDialog):
    settings = QSettings("ini/parameters.ini", QSettings.IniFormat)
    globalSettings = QSettings("ini/paths.ini", QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_MD.setEnabled(False)
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.pushButton_amber.clicked.connect(self.selectAmber)
        self.pushButton_MD.clicked.connect(self.configureMD)
        self.checkBox_MD.stateChanged.connect(self.checkConfigureMD)
        self.tableWidget.resizeColumnsToContents()
        self.values = {}
        guiRestore(self, self.settings)
        restoreUsefullPaths(self, self.globalSettings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        saveUsefullPaths(self, self.globalSettings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['Model'] = self.comboBox_model.currentText()
        self.values['AmberShFile'] = self.textBrowser_amber.toPlainText()
        try:
            self.values['AmberShFile']
        except KeyError:
            self.missingParameters('amber.sh file')
        else:
            if self.values['AmberShFile'] == '':
                del self.values['AmberShFile']
                self.missingParameters('amber.sh file')
            else:
                self.close()

    def cancel(self):
        del self.values
        self.close()

    def selectAmber(self):
        filetypes = "Shell files (*.sh);;All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select amber.sh file", '/', filetypes)
        if value:
            self.textBrowser_amber.setPlainText(value)

    def checkConfigureMD(self):
        if self.checkBox_MD.isChecked():
            self.pushButton_MD.setEnabled(True)
        else:
            self.pushButton_MD.setEnabled(False)

    def configureMD(self):
        MDDialog = DialogMD()
        MDDialog.exec_()
        try:
            MDDialog.values
        except AttributeError:
            pass
        else:
            for i in ['MDRun','ProductionLength']:
                self.values[i] = MDDialog.values[i]

    def missingParameters(self, missing):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setText("You must configure the following parameter:")
        msg.setInformativeText(missing)
        msg.setWindowTitle("Error: Missing parameter")
        msg.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        retval = msg.exec_()
        if retval == 1024: # Ok
            msg.close()
        elif retval == 4194304: # Cancel
            self.close()

class DialogMD(QDialog, Ui_MDDialog):
    settings = QSettings("ini/parameters.ini", QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.values = {}
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['MDRun'] = self.comboBox_run.currentText()
        self.values['ProductionLength'] = self.spinBox_time.value()
        self.values['MDGBModel'] = self.comboBox_gb.currentText()
        self.close()

    def cancel(self):
        del self.values
        self.close()
