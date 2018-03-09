#!/usr/bin/env python
import sys, os, subprocess, re
from inspect import getsourcefile
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QWidget, QFileDialog, QMainWindow
from UImainwindow import *
from runOptions import *
from dockOptions import *
from minOptions import *
from rescoreOptions import *
from dialogSaveRestore import *

# directory where the binary is beign decompressed and executed, usually /tmp/_MEIxxxxxx
tempDir = os.path.dirname(resource_path(__file__))
# directory where the binary that was launched is
execDir = os.path.dirname(os.path.realpath(sys.argv[0]))

class Main(QMainWindow, Ui_MainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # set window icon and logo
        icon = QtGui.QIcon()
        iconPath = os.path.realpath(os.path.join(tempDir, "logo.png"))
        icon.addPixmap(QtGui.QPixmap(iconPath), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.setWindowIcon(icon)
        self.label_logo.setPixmap(QtGui.QPixmap(iconPath))
        # connect buttons with actions
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
        self.comboBox_analyse.currentIndexChanged.connect(self.checkAnalyse)
        self.pushButton_configureExp.clicked.connect(self.configureExp)
        # dic for ligand, receptor and output files
        self.userInput = {}

    def selectLigand(self):
        if self.checkBox_lig.isChecked():
            self.userInput['ligandInput'] = QFileDialog.getExistingDirectory(None, "Select directory of ligands", os.getcwd())
            if self.userInput['ligandInput']:
                self.textBrowser_lig.setPlainText(self.userInput['ligandInput'])
        else:
            filetypes = "Mol2 Files (*.mol2);;SDF Files (*.sdf);;SMILES Files (*.smi);;All Files (*)"
            self.userInput['ligandInput'], _ = QFileDialog.getOpenFileName(None,"Select ligand(s) file", os.getcwd(), filetypes)
            if self.userInput['ligandInput']:
                self.textBrowser_lig.setPlainText(self.userInput['ligandInput'])

    def selectReceptor(self):
        filetypes = "Mol2 Files (*.mol2);;PDB Files (*.pdb);;All Files (*)"
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

    def checkAnalyse(self):
        analysis = self.comboBox_analyse.currentText()
        if analysis == 'Current experiment':
            self.pushButton_configureExp.setEnabled(False)
        else:
            self.pushButton_configureExp.setEnabled(True)

    def configureExp(self):
        pass

    def run(self):
        self.writeConfig()
        # run
        with subprocess.Popen("DockFlow -f DockFlow.config".split(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=1, universal_newlines=True) as process:
            # write output as it runs
            for line in process.stdout:
                # fix progress bar and spinner printed every second without carriage return
                if ('Progress' in line) or ('Preparing' in line):
                    print('\r'+line.replace('\n',''), end='')
                # Fix no \n after the last print from the progress bar or spinner
                elif ('Execution time' in line) or ('Finished preparing' in line):
                    print('\n'+line, end='')
                else:
                    print(line, end='')
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, process.args)

    def writeConfig(self):
        self.values = {}
        missing = []
        missing_files = ['receptorFile', 'ligandInput', 'outputFolder']
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
        # Write Docking
        if 'Docking' in self.values['protocolPreset']:
            with open('{}/DockFlow.config'.format(os.getcwd()),'w') as f:
                # Make variables compatible with dockflow
                if self.values['runOption'] == 'Locally':
                    self.values['runMode'] = 'local' if self.values['numberCores'] == 1 else 'parallel'
                else:
                    self.values['runMode'] = self.values['runOption']
                for i in ['PlantsExec','VinaExec','MGLFolder',
                'DockRadius','DockSizeX','DockSizeY','DockSizeZ',
                'SearchSpeed','Ants','EvaporationRate','IterationScaling',
                'Exhaustiveness','EnergyRange',
                'WaterFile','WaterCenterX','WaterCenterY','WaterCenterZ','WaterRadius']:
                    try:
                        self.values[i]
                    except KeyError:
                        self.values[i] = ''
                if not self.values['DockSizeX']:
                    self.values['DockSize'] = ''
                else:
                    self.values['DockSize'] = '{} {} {}'.format(self.values['DockSizeX'],
                                                                self.values['DockSizeY'],
                                                                self.values['DockSizeZ'])
                if not self.values['WaterCenterX']:
                    self.values['WaterPosition'] = ''
                else:
                    self.values['WaterPosition'] = '{} {} {} {}'.format(self.values['WaterCenterX'],
                                                                        self.values['WaterCenterY'],
                                                                        self.values['WaterCenterZ'],
                                                                        self.values['WaterRadius'])
                if self.values['dockingSoftware'] == 'AutoDock Vina':
                    self.values['ScoringFunction'] = 'vina'
                toWrite = '''# Config file for DockFlow
# Absolute path to receptor's mol2 file
rec=\"{receptorFile}\"
# Absolute path to ligands file/folder
lig_input=\"{ligandInput}\"
# Output folder
output_folder=\"{outputFolder}\"
# Number of docking poses to generate
poses_number=\"{dockingPoses}\"
# Scoring function: vina, chemplp, plp or plp95
scoring_function=\"{ScoringFunction}\"
# xyz coordinates of the center of the sphere/grid binding site, separated by a space
bs_center=\"{DockCenterX} {DockCenterY} {DockCenterZ}\"

##########
# PLANTS #
##########
plants_exec=\"{PlantsExec}\"
# Radius of the spheric binding site in Angstrom
bs_radius=\"{DockRadius}\"
# Search speed : 1, 2 or 4. Default: 1
speed=\"{SearchSpeed}\"
# Number of ants. Default : 20
ants=\"{Ants}\"
# Evaporation rate of pheromones. Default : 0.15
evap_rate=\"{EvaporationRate}\"
# Iteration scaling factor. Default : 1.00
iteration_scaling=\"{IterationScaling}\"

########
# Vina #
########
vina_exec=\"{VinaExec}\"
mgltools_folder=\"{MGLFolder}\"
# Size of the sphere along the x, y and z axis in Angstrom, separated by a space
bs_size=\"{DockSize}\"
# Exhaustiveness of the global search. Default : 8
exhaustiveness=\"{Exhaustiveness}\"
# Max energy difference (kcal/mol) between the best and worst poses displayed. Default : 3.00
energy_range=\"{EnergyRange}\"

###################
# Optionnal input #
###################
# Run on this machine (default), in parallel, or on mazinger
# local, parallel, mazinger
run_mode=\"{runMode}\"
# If parallel is chosen, please specify the number of cores to use
core_number=\"{numberCores}\"
# Add a structural water molecule for PLANTS, centered on an xyz sphere and moving in a radius
# Absolute path to water molecule
water_molecule=\"{WaterFile}\"
# xyz coordinates and radius of the sphere, separated by a space
water_molecule_definition=\"{WaterPosition}\"
'''.format(
receptorFile=self.values['receptorFile'],
ligandInput=self.values['ligandInput'],
outputFolder=self.values['outputFolder'],
dockingPoses=self.values['dockingPoses'],
ScoringFunction=self.values['ScoringFunction'],
DockCenterX=self.values['DockCenterX'],
DockCenterY=self.values['DockCenterY'],
DockCenterZ=self.values['DockCenterZ'],
PlantsExec=self.values['PlantsExec'],
DockRadius=self.values['DockRadius'],
SearchSpeed=self.values['SearchSpeed'],
Ants=self.values['Ants'],
EvaporationRate=self.values['EvaporationRate'],
IterationScaling=self.values['IterationScaling'],
VinaExec=self.values['VinaExec'],
MGLFolder=self.values['MGLFolder'],
DockSize=self.values['DockSize'],
Exhaustiveness=self.values['Exhaustiveness'],
EnergyRange=self.values['EnergyRange'],
runMode=self.values['runMode'],
numberCores=self.values['numberCores'],
WaterFile=self.values['WaterFile'],
WaterPosition=self.values['WaterPosition'])
                f.write(toWrite)

        if 'Rescoring' in self.values['protocolPreset']:
            pass

    def readConfig(self):
        '''Just prints the parameters for now...'''
        d = {}
        filetypes = "Config Files (*.config);;Text Files (*.txt);;All Files (*)"
        configFile, _ = QFileDialog.getOpenFileName(None,"Select configuration file", os.getcwd(), filetypes)
        with open(configFile, 'r') as f:
            lines = f.readlines()
        for line in lines:
            if '=' in line:
                temp = line.split('=')
                var = str(temp[0])
                val = str(temp[1]).replace('"','').strip('\n')
                if val == '':
                    continue
                if var == 'rec':
                    d['receptorFile'] = val
                elif var == 'lig_input':
                    d['ligandInput'] = val
                elif var == 'output_folder':
                    d['outputFolder'] = val
                elif var == 'poses_number':
                    d['dockingPoses'] = val
                elif var == 'scoring_function':
                    d['ScoringFunction'] = val
                elif var == 'bs_center':
                    val = val.split()
                    d['DockCenterX'] = val[0]
                    d['DockCenterY'] = val[1]
                    d['DockCenterZ'] = val[2]
                elif var == 'plants_exec':
                    d['PlantsExec'] = val
                elif var == 'bs_radius':
                    d['DockRadius'] = val
                elif var == 'speed':
                    d['SearchSpeed'] = val
                elif var == 'ants':
                    d['Ants'] = val
                elif var == 'evap_rate':
                    d['EvaporationRate'] = val
                elif var == 'iteration_scaling':
                    d['IterationScaling'] = val
                elif var == 'vina_exec':
                    d['VinaExec'] = val
                elif var == 'mgltools_folder':
                    d['MGLFolder'] = val
                elif var == 'bs_size':
                    val = val.split()
                    d['DockSizeX'] = val[0]
                    d['DockSizeY'] = val[1]
                    d['DockSizez'] = val[2]
                elif var == 'exhaustiveness':
                    d['Exhaustiveness'] = val
                elif var == 'energy_range':
                    d['EnergyRange'] = val
                elif var == 'run_mode':
                    d['runMode'] = val
                elif var == 'core_number':
                    d['numberCores'] = val
                elif var == 'water_molecule':
                    d['WaterFile'] = val
                elif var == 'water_molecule_definition':
                    val = val.split()
                    d['WaterCenterX'] = val[0]
                    d['WaterCenterY'] = val[1]
                    d['WaterCenterZ'] = val[2]
                    d['WaterRadius'] = val[3]
        space = len(max(d, key=len))
        for var in d:
            print('{:{space}} --> {}'.format(var, d[var], space=space))
        print('-'*10)

    def cancel(self):
        cleanParameters(execDir)
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
