import os, sys
from PyQt5 import QtGui
from PyQt5.QtWidgets import QDialog, QFileDialog
from PyQt5.QtCore import QSettings
from qt_creator.UIdocking_plants import Ui_DockingPlants
from qt_creator.UIdocking_vina import Ui_DockingVina
from qt_creator.UIplants_water import Ui_PlantsWater
from utils import (
    WORKDIR, INI_FILE, EMPTY_VALUES,
    guiSave, guiRestore,
    missingParametersDialog, errorDialog,
)


class DialogDockVina(QDialog, Ui_DockingVina):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['DockCenterX'] = self.doubleSpinBox_cx.value()
        self.values['DockCenterY'] = self.doubleSpinBox_cy.value()
        self.values['DockCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['DockSizeX'] = self.spinBox_sx.value()
        self.values['DockSizeY'] = self.spinBox_sy.value()
        self.values['DockSizeZ'] = self.spinBox_sz.value()
        self.values['Exhaustiveness'] = self.spinBox_exhaustiveness.value()
        self.values['EnergyRange'] = self.doubleSpinBox_energyRange.value()
        self.close()


class DialogDockPlants(QDialog, Ui_DockingPlants):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        self.pushButton_water.clicked.connect(self.configure_water)
        self.checkBox_water.stateChanged.connect(self.check_configure_water)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['DockCenterX'] = self.doubleSpinBox_cx.value()
        self.values['DockCenterY'] = self.doubleSpinBox_cy.value()
        self.values['DockCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['DockRadius'] = self.doubleSpinBox_radius.value()
        self.values['Ants'] = self.spinBox_ants.value()
        self.values['EvaporationRate'] = self.doubleSpinBox_evaporationRate.value()
        self.values['IterationScaling'] = self.doubleSpinBox_iterationScaling.value()
        self.values['ClusterRMSD'] = self.doubleSpinBox_clusterRMSD.value()
        self.values['ScoringFunction'] = self.comboBox_scoringFunction.currentText()
        self.values['SearchSpeed'] = self.comboBox_searchSpeed.currentText()
        if self.checkBox_water.isChecked():
            try:
                self.values['WaterFile']
            except KeyError:
                missingParametersDialog('- Water MOL2 file')
            else:
                self.close()
        else:
            self.close()

    def check_configure_water(self):
        if self.checkBox_water.isChecked():
            self.pushButton_water.setEnabled(True)
        else:
            self.pushButton_water.setEnabled(False)

    def configure_water(self):
        waterDialog = DialogWaterPlants()
        waterDialog.exec_()
        try:
            waterDialog.values
        except AttributeError:
            pass
        else:
            for i in ['WaterCenterX','WaterCenterY','WaterCenterZ','WaterRadius','WaterFile']:
                self.values[i] = waterDialog.values[i]


class DialogWaterPlants(QDialog, Ui_PlantsWater):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        self.pushButton_water.clicked.connect(self.selectWater)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['WaterCenterX'] = self.doubleSpinBox_cx.value()
        self.values['WaterCenterY'] = self.doubleSpinBox_cy.value()
        self.values['WaterCenterZ'] = self.doubleSpinBox_cz.value()
        self.values['WaterRadius'] = self.doubleSpinBox_radius.value()
        self.values['WaterFile'] = self.lineEdit_water.text()
        try:
            if self.values['WaterFile'] in EMPTY_VALUES:
                missingParametersDialog('- Water MOL2 File')
            else:
                self.close()
        except KeyError:
            missingParametersDialog('- Water MOL2 File')


    def selectWater(self):
        filetypes =  "MOL2 Files (*.mol2);;All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select MOL2 file of a single water", os.getcwd(), filetypes)
        if value:
            self.lineEdit_water.setText(value)