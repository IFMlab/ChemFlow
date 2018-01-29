import sys, os
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QWidget, QFileDialog, QMainWindow
from UImainwindow import *
from runOptions import *
from dockOptions import *
from minOptions import *
from rescoreOptions import *
from dialogSaveRestore import *

class Main(QMainWindow, Ui_MainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.pushButton_runConfigure.clicked.connect(self.configureRun)
        self.comboBox_protocolPreset.currentIndexChanged.connect(self.checkConfiguration)
        self.pushButton_rec.clicked.connect(self.selectReceptor)
        self.pushButton_lig.clicked.connect(self.selectLigand)
        self.pushButton_output.clicked.connect(self.selectOutput)
        self.pushButton_dockingConfigure.clicked.connect(self.configureDocking)
        self.pushButton_minConfigure.clicked.connect(self.configureMin)
        self.pushButton_minConfigure.setEnabled(False)
        self.checkBox_min.setEnabled(False)
        self.checkBox_min.stateChanged.connect(self.checkConfigureMin)
        self.pushButton_rescoringConfigure.clicked.connect(self.configureRescoring)
        self.comboBox_rescoringSoftware.setEnabled(False)
        self.pushButton_rescoringConfigure.setEnabled(False)
        self.spinBox_rescoring.setEnabled(False)
        self.pushButton_run.clicked.connect(self.run)
        self.pushButton_writeConfig.clicked.connect(self.writeConfig)
        self.pushButton_readConfig.clicked.connect(self.readConfig)
        self.pushButton_cancel.clicked.connect(self.cancel)
        # dic for ligand, receptor and output files
        self.userInput = {}

    def selectLigand(self):
        if self.checkBox_lig.isChecked():
            self.userInput['ligandFolder'] = QFileDialog.getExistingDirectory(None, "Select directory of ligands", os.getcwd())
            if self.userInput['ligandFolder']:
                self.textBrowser_lig.setPlainText(self.userInput['ligandFolder'])
        else:
            filetypes = "Mol2 Files (*.mol2);;PDB Files (*.pdb);;SDF Files (*.sdf);;SMILES Files (*.smi);;All Files (*)"
            self.userInput['ligandFile'], _ = QFileDialog.getOpenFileName(None,"Select ligand(s) file", os.getcwd(), filetypes)
            if self.userInput['ligandFile']:
                self.textBrowser_lig.setPlainText(self.userInput['ligandFile'])

    def selectReceptor(self):
        filetypes = "PDB Files (*.pdb);;All Files (*)"
        self.userInput['receptorFile'], _ = QFileDialog.getOpenFileName(None,"Select receptor file", os.getcwd(), filetypes)
        if self.userInput['receptorFile']:
            self.textBrowser_rec.setPlainText(self.userInput['receptorFile'])

    def selectOutput(self):
        self.userInput['outputFolder'] = QFileDialog.getExistingDirectory(None, "Select output directory", os.getcwd())
        if self.userInput['outputFolder']:
            self.textBrowser_output.setPlainText(self.userInput['outputFolder'])

    def checkConfiguration(self):
        protocol = self.comboBox_protocolPreset.currentText()
        if protocol == 'Docking':
            self.pushButton_dockingConfigure.setEnabled(True)
            self.pushButton_minConfigure.setEnabled(False)
            self.pushButton_rescoringConfigure.setEnabled(False)
            self.comboBox_dockingSoftware.setEnabled(True)
            self.checkBox_min.setEnabled(False)
            self.comboBox_rescoringSoftware.setEnabled(False)
            self.spinBox_docking.setEnabled(True)
            self.spinBox_rescoring.setEnabled(False)
        elif protocol == 'Rescoring':
            self.pushButton_dockingConfigure.setEnabled(False)
            self.checkConfigureMin()
            self.pushButton_rescoringConfigure.setEnabled(True)
            self.comboBox_dockingSoftware.setEnabled(False)
            self.checkBox_min.setEnabled(True)
            self.comboBox_rescoringSoftware.setEnabled(True)
            self.spinBox_docking.setEnabled(False)
            self.spinBox_rescoring.setEnabled(True)
        elif protocol == 'Docking + Rescoring':
            self.pushButton_dockingConfigure.setEnabled(True)
            self.checkConfigureMin()
            self.pushButton_rescoringConfigure.setEnabled(True)
            self.comboBox_dockingSoftware.setEnabled(True)
            self.checkBox_min.setEnabled(True)
            self.comboBox_rescoringSoftware.setEnabled(True)
            self.spinBox_docking.setEnabled(True)
            self.spinBox_rescoring.setEnabled(True)

    def configureRun(self):
        runOption = self.comboBox_runOptions.currentText()
        if runOption == 'Locally':
            runDialog = DialogRunLocally()
        elif runOption == 'PBS':
            runDialog = DialogRunPBS()
        elif runOption == 'Slurm':
            runDialog = DialogRunSlurm()
        runDialog.exec_()
        self.runParameters = runDialog.values
        self.runOption = runOption

    def configureDocking(self):
        dockingSoftware = self.comboBox_dockingSoftware.currentText()
        if dockingSoftware == 'AutoDock Vina':
            dockingDialog = DialogDockVina()
        elif dockingSoftware == 'PLANTS':
            dockingDialog = DialogDockPlants()
        dockingDialog.exec_()
        try:
            dockingDialog.values
        except AttributeError:
            pass
        else:
            self.dockingParameters = dockingDialog.values
        self.dockingSoftware = dockingSoftware

    def checkConfigureMin(self):
        if self.checkBox_min.isChecked():
            self.pushButton_minConfigure.setEnabled(True)
        else:
            self.pushButton_minConfigure.setEnabled(False)

    def configureMin(self):
        minDialog = DialogMin()
        minDialog.exec_()
        try:
            minDialog.values
        except AttributeError:
            pass
        else:
            self.minParameters = minDialog.values

    def configureRescoring(self):
        rescoringSoftware = self.comboBox_rescoringSoftware.currentText()
        if rescoringSoftware == 'AutoDock Vina':
            rescoringDialog = DialogRescoreVina()
        elif rescoringSoftware == 'PLANTS':
            rescoringDialog = DialogRescorePlants()
        elif rescoringSoftware == 'MM/PBSA':
            rescoringDialog = DialogRescoreMmpbsa()
        rescoringDialog.exec_()
        try:
            rescoringDialog.values
        except AttributeError:
            pass
        else:
            self.rescoringParameters = rescoringDialog.values
        self.rescoringSoftware = rescoringSoftware

    def run(self):
        self.writeConfig()
        print("My developper is too lazy to implement this yet...")

    def writeConfig(self):
        self.values = {}
        missing = []
        missing_files = ['receptorFile', 'outputFolder']
        if self.checkBox_lig.isChecked():
            missing_files.append('ligandFolder')
        else:
            missing_files.append('ligandFile')
        for i in missing_files:
            try:
                self.userInput[i]
            except KeyError:
                missing.append(i)
            else:
                if self.userInput[i] == '':
                    missing.append(i)
                    del self.userInput[i]
                else:
                    self.values[i] = self.userInput[i]
        if missing:
            self.missingParameters(missing)
            return
        # Run parameters: Locally, PBS, Slurm
        runOption = self.comboBox_runOptions.currentText()
        try:
            self.runParameters
        except AttributeError:
            self.runParameters = defaultRunParameters(runOption)
            self.runOption = runOption
        else:
            if self.runOption != runOption:
                self.runParameters = defaultRunParameters(runOption)
                self.runOption = runOption
        finally:
            for value in self.runParameters:
                self.values[value] = self.runParameters[value]
            self.values['runOption'] = runOption
        # protocolPreset
        self.values['protocolPreset'] = self.comboBox_protocolPreset.currentText()
        # Docking Parameters
        if 'Docking' in self.values['protocolPreset']:
            self.values['dockingSoftware'] = self.comboBox_dockingSoftware.currentText()
            self.values['dockingPoses'] = self.spinBox_docking.value()
            dockingSoftware = self.values['dockingSoftware']
            try:
                self.dockingParameters
            except AttributeError:
                self.softwareNotParametrizedError(dockingSoftware, 'docking')
                return
            else:
                if self.dockingSoftware != dockingSoftware:
                    self.softwareNotParametrizedError(dockingSoftware, 'docking')
                    return
                else:
                    for value in self.dockingParameters:
                        self.values[value] = self.dockingParameters[value]
        if 'Rescoring' in self.values['protocolPreset']:
            self.values['Minimize'] = self.checkBox_min.isChecked()
            self.values['rescoringSoftware'] = self.comboBox_rescoringSoftware.currentText()
            self.values['rescoringPoses'] = self.spinBox_rescoring.value()
            # Force Field minimisation
            if self.checkBox_min.isChecked():
                try:
                    self.minParameters
                except AttributeError:
                    self.softwareNotParametrizedError('minimisation','min')
                    return
                else:
                    for value in self.minParameters:
                        self.values[value] = self.minParameters[value]
            # Rescoring Parameters
            rescoringSoftware = self.values['rescoringSoftware']
            try:
                self.rescoringParameters
            except AttributeError:
                self.softwareNotParametrizedError(rescoringSoftware, 'rescoring')
                return
            else:
                if self.rescoringSoftware != rescoringSoftware:
                    self.softwareNotParametrizedError(rescoringSoftware, 'rescoring')
                    return
                else:
                    for value in self.rescoringParameters:
                        self.values[value] = self.rescoringParameters[value]
        # Print output
        space = len(max(self.values, key=len))
        for value in self.values:
            print('{:{space}} --> {}'.format(value, self.values[value], space=space))
        print('-'*10)

    def readConfig(self):
        pass

    def cancel(self):
        cleanParameters()
        sys.exit()

    def softwareNotParametrizedError(self, software, toConfigure):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setText("You must configure {} !".format(software))
        msg.setWindowTitle("Error: {} not parametrized".format(software))
        msg.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        retval = msg.exec_()
        if retval == 1024: # Ok
            msg.close()
            if toConfigure == 'docking':
                self.configureDocking()
            elif toConfigure == 'rescoring':
                self.configureRescoring()
            elif toConfigure == 'min':
                self.configureMin()
        elif retval == 4194304: # Cancel
            msg.close()

    def missingParameters(self, missing):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setText("You must configure the following parameters:")
        msg.setInformativeText(', '.join(missing))
        msg.setWindowTitle("Error: Missing parameters")
        msg.setStandardButtons(QMessageBox.Ok)
        retval = msg.exec_()
        if retval == 1024: # Ok
            msg.close()

if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv)
    main = Main()
    main.show()
    sys.exit(app.exec_())
