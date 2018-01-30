import sys, os
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QWidget, QFileDialog, QMainWindow, QDialog, QMessageBox
from dockVina.UIdockvinadialog import *
from dockPlants.UIdockplantsdialog import *
from waterPlants.UIwaterplantsdialog import *
from dialogSaveRestore import *

# Absolute paths to files
execDir = os.path.dirname(os.path.realpath(sys.argv[0]))
iniParameters = os.path.realpath(os.path.join(execDir, "ini/parameters.ini"))
iniPaths = os.path.realpath(os.path.join(execDir, "ini/paths.ini"))

class DialogDockVina(QDialog, Ui_dockVinaDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    globalSettings = QSettings(iniPaths, QSettings.IniFormat)
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
        self.values['DockCenterX'] = self.doubleSpinBox_cx.value()
        self.values['DockCenterY'] = self.doubleSpinBox_cy.value()
        self.values['DockCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['DockSizeX'] = self.spinBox_sx.value()
        self.values['DockSizeY'] = self.spinBox_sy.value()
        self.values['DockSizeZ'] = self.spinBox_sz.value()
        self.values['Exhaustiveness'] = self.spinBox_exhaustiveness.value()
        self.values['EnergyRange'] = self.doubleSpinBox_energyRange.value()
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

class DialogDockPlants(QDialog, Ui_dockPlantsDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    globalSettings = QSettings(iniPaths, QSettings.IniFormat)
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
        self.values['DockCenterX'] = self.doubleSpinBox_cx.value()
        self.values['DockCenterY'] = self.doubleSpinBox_cy.value()
        self.values['DockCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['DockRadius'] = self.doubleSpinBox_radius.value()
        self.values['Ants'] = self.spinBox_ants.value()
        self.values['EvaporationRate'] = self.doubleSpinBox_evaporationRate.value()
        self.values['IterationScaling'] = self.doubleSpinBox_iterationScaling.value()
        self.values['ScoringFunction'] = self.comboBox_scoringFunction.currentText()
        self.values['SearchSpeed'] = self.comboBox_searchSpeed.currentText()
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

class DialogWaterPlants(QDialog, Ui_waterPlantsDialog):
    settings = QSettings(iniParameters, QSettings.IniFormat)
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_ok.clicked.connect(self.ok)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.pushButton_water.clicked.connect(self.selectWater)
        self.values = {}
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def ok(self):
        self.values['WaterCenterX'] = self.doubleSpinBox_cx.value()
        self.values['WaterCenterY'] = self.doubleSpinBox_cy.value()
        self.values['WaterCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['WaterRadius'] = self.doubleSpinBox_radius.value()
        self.values['WaterFile'] = self.textBrowser_water.toPlainText()
        try:
            self.values['WaterFile']
        except KeyError:
            self.missingParameters('Water MOL2 File')
        else:
            if self.values['WaterFile'] == '':
                del self.values['WaterFile']
                self.missingParameters('Water MOL2 File')
            else:
                self.close()

    def cancel(self):
        del self.values
        self.close()

    def selectWater(self):
        filetypes =  "MOL2 Files (*.mol2);;All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select MOL2 file of a single water", os.getcwd(), filetypes)
        if value:
            self.textBrowser_water.setPlainText(value)

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
