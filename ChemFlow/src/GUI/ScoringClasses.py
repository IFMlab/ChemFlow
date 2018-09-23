import os, sys
from PyQt5 import QtGui
from PyQt5.QtWidgets import QDialog, QFileDialog
from PyQt5.QtCore import QSettings
from qt_creator.UIscoring_plants import Ui_ScoringPlants
from qt_creator.UIscoring_vina import Ui_ScoringVina
from DockingClasses import DialogWaterPlants
from qt_creator.UImmgbsa import Ui_ScoringMmgbsa
from utils import (
    WORKDIR, INI_FILE, EMPTY_VALUES,
    guiSave, guiRestore,
    missingParametersDialog, errorDialog,
)


class DialogScoreVina(QDialog, Ui_ScoringVina):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.cancel)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['CenterX'] = self.doubleSpinBox_cx.value()
        self.values['CenterY'] = self.doubleSpinBox_cy.value()
        self.values['CenterZ'] = self.doubleSpinBox_cz.value()
        self.values['SizeX'] = self.spinBox_sx.value()
        self.values['SizeY'] = self.spinBox_sy.value()
        self.values['SizeZ'] = self.spinBox_sz.value()
        self.values['ScoringFunction'] = 'vina'
        self.close()

    def cancel(self):
        del self.values
        self.close()


class DialogScorePlants(QDialog, Ui_ScoringPlants):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.cancel)
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
        self.values['CenterX'] = self.doubleSpinBox_cx.value()
        self.values['CenterY'] = self.doubleSpinBox_cy.value()
        self.values['CenterZ'] = self.doubleSpinBox_cz.value()
        self.values['Radius'] = self.doubleSpinBox_radius.value()
        self.values['ScoringFunction'] = self.comboBox_scoringFunction.currentText()
        if self.checkBox_water.isChecked():
            try:
                self.values['WaterFile']
            except KeyError:
                missingParametersDialog('- Water MOL2 file')
            else:
                self.close()
        else:
            self.close()

    def cancel(self):
        del self.values
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
            waterDialog.values['WaterFile']
        except KeyError:
            pass
        else:
            for i in ['WaterCenterX','WaterCenterY','WaterCenterZ','WaterRadius','WaterFile']:
                self.values[i] = waterDialog.values[i]


class DialogScoreMmgbsa(QDialog, Ui_ScoringMmgbsa):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.cancel)
        # checkbox exclusive
        self.checkBox_write_only.stateChanged.connect(self.checkbox_exclusive_write)
        self.checkBox_run_only.stateChanged.connect(self.checkbox_exclusive_run)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['Charges'] = self.comboBox_charges.currentText()
        if self.radioButton_implicit.isChecked():
            self.values['ExplicitSolvent'] = False
        else:
            self.values['ExplicitSolvent'] = True
        self.values['MaxCyc'] = self.spinBox_maxcyc.value()
        if self.checkBox_MD.isChecked():
            self.values['MD'] = True
        else:
            self.values['MD'] = False
        self.values['ScoringFunction'] = 'mmgbsa'
        self.close()

    def cancel(self):
        del self.values
        self.close()

    def checkbox_exclusive_run(self):
        if self.checkBox_run_only.isChecked():
            self.checkBox_write_only.setEnabled(False)
        else:
            self.checkBox_write_only.setEnabled(True)

    def checkbox_exclusive_write(self):
        if self.checkBox_write_only.isChecked():
            self.checkBox_run_only.setEnabled(False)
        else:
            self.checkBox_run_only.setEnabled(True)
