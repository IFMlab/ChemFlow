import os
from PyQt5.QtWidgets import QDialog, QFileDialog
from PyQt5.QtCore import QSettings
from qt_creator.UItool_boundingshape import Ui_ToolBoundingShape
from qt_creator.UItool_smiles_to_3d import Ui_ToolSmilesTo3d
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


class DialogToolSmilesTo3D(QDialog, Ui_ToolSmilesTo3d):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.cancel)
        self.pushButton_input.clicked.connect(self.select_input)
        self.lineEdit_input.textChanged.connect(lambda text: self.set_output(text))
        # Settings
        self.values = {}
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def validate(self):
        missing = []
        self.values['InputFile'] = self.lineEdit_input.text()
        self.values['OutputFile'] = self.lineEdit_output.text()
        self.values['SmilesColumn'] = self.spinBox_smiles_col.value()
        self.values['NamesColumn'] = self.spinBox_names_col.value()
        self.values['NThreads'] = self.spinBox_nthreads.value()
        self.values['Header'] = self.checkBox_header.isChecked()
        self.values['AllHydrogens'] = self.checkBox_hydrogen.isChecked()
        self.values['Verbose'] = self.checkBox_verbose.isChecked()
        self.values['MPI'] = self.checkBox_mpi.isChecked()
        value = self.comboBox_delimiter.currentText()
        if value == 'Tab':
            delimiter = '\t'
        elif value == 'Space':
            delimiter = ' '
        else:
            delimiter = value
        self.values['Delimiter'] = delimiter
        self.values['Method'] = self.comboBox_delimiter.currentText().lower()
        if self.values['InputFile'] in EMPTY_VALUES:
            missing.append('- Input SMILES file')
        if self.values['OutputFile'] in EMPTY_VALUES:
            missing.append('- Output SDF file')
        if len(missing):
            missingParametersDialog(*missing)
        else:
            self.close()

    def cancel(self):
        del self.values
        self.close()

    def select_input(self):
        filetypes =  "All Files (*)"
        value, _ = QFileDialog.getOpenFileName(None,"Select input SMILES file", os.getcwd(), filetypes)
        if value:
            self.lineEdit_input.setText(value)

    def set_output(self, text):
        """Suggest path to output file automatically from input file"""
        output = self.lineEdit_output.text()
        output_dir = os.path.dirname(output)
        input_dir = os.path.dirname(text)
        if (output_dir[:len(input_dir)] in input_dir) or (output in EMPTY_VALUES):
            filename, file_extension = os.path.splitext(text)
            self.lineEdit_output.setText('{}.sdf'.format(filename))
