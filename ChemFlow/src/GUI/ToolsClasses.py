import os
from PyQt5.QtWidgets import QDialog, QFileDialog
from PyQt5.QtCore import QSettings
from qt_creator.UItool_boundingshape import Ui_ToolBoundingShape
from utils import (
    WORKDIR, INI_FILE, EMPTY_VALUES,
    guiSave, guiRestore,
    missingParametersDialog, errorDialog,
)

class DialogToolBoundingShape(QDialog, Ui_ToolBoundingShape):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.pushButton_input.clicked.connect(self.select_input)
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        self.values['Shape'] = 'sphere' if self.radioButton_sphere.isChecked() else 'box'
        self.values['PyMOL'] = self.checkBox_pymol.isChecked()
        self.values['InputFile'] = self.lineEdit_path.text()
        self.values['Padding'] = self.doubleSpinBox_padding.value()
        if self.values['InputFile'] in EMPTY_VALUES:
            missingParametersDialog('- Input MOL2 file')
        else:
            self.close()

    def cancel(self):
        del self.values
        self.close()

    def select_input(self):
        filetypes =  "MOL2 Files (*.mol2);;All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select MOL2 file", os.getcwd(), filetypes)
        if value:
            self.lineEdit_path.setText(value)
