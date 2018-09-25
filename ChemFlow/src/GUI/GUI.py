#!/usr/bin/env python

from PyQt5 import QtGui, QtWidgets
from PyQt5.QtWidgets import QFileDialog, QMainWindow
from PyQt5.QtCore import QProcess, QByteArray, QRegExp
from webbrowser import open as browser_open
from time import strftime, gmtime
import sys, os, logging
from utils import (
    WORKDIR, CWDIR, EMPTY_VALUES, PROCESS_ERROR, PROCESS_STATE,
    cleanParameters, missingParametersDialog, errorDialog, yesNoDialog,
)
from MainClasses import DialogAbout, DialogNewProject, DialogQuestion, LogfileDialog
from DockingClasses import DialogDockVina, DialogDockPlants
from ScoringClasses import DialogScoreVina, DialogScorePlants, DialogScoreMmgbsa
from ExecutionClasses import DialogRunLocal, DialogRunPbs, DialogRunSlurm
from qt_creator.UImainwindow import Ui_MainWindow


class Main(QMainWindow, Ui_MainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # set window icon and logo
        icon = QtGui.QIcon()
        logo_path = os.path.realpath(os.path.join(WORKDIR, "img", "logo.png"))
        icon.addPixmap(QtGui.QPixmap(logo_path), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.setWindowIcon(icon)
        self.label_logo.setPixmap(QtGui.QPixmap(logo_path))
        # set other icons
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap(os.path.realpath(os.path.join(WORKDIR, "img", "run.png"))), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.commandLinkButton_ligflow_run.setIcon(icon)
        self.commandLinkButton_docking_run.setIcon(icon)
        self.commandLinkButton_scoring_run.setIcon(icon)
        self.commandLinkButton_tools_run.setIcon(icon)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap(os.path.realpath(os.path.join(WORKDIR, "img", "process.png"))), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.commandLinkButton_docking_postprocess.setIcon(icon)
        self.commandLinkButton_scoring_postprocess.setIcon(icon)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap(os.path.realpath(os.path.join(WORKDIR, "img", "archive.png"))), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.commandLinkButton_docking_archive.setIcon(icon)
        self.commandLinkButton_scoring_archive.setIcon(icon)
        # connect buttons with actions
        ## Menu
        self.actionAbout.triggered.connect(self.about)
        self.actionGitHub.triggered.connect(self.github)
        self.actionReport_issue.triggered.connect(self.report_issue)
        self.actionTutorial.triggered.connect(self.tutorial)
        self.actionDebug_mode.triggered.connect(self.debug_mode)
        self.actionLogfile.triggered.connect(self.read_logs)
        self.actionNew_project.triggered.connect(self.create_project)
        self.actionLoad_project.triggered.connect(self.load_project)
        self.actionExit.triggered.connect(self.close)
        ## Input
        self.pushButton_ligflow_lig.clicked.connect(self.browse_ligand)
        self.pushButton_docking_rec.clicked.connect(self.browse_receptor)
        self.pushButton_docking_lig.clicked.connect(self.browse_ligand)
        self.pushButton_scoring_rec.clicked.connect(self.browse_receptor)
        self.pushButton_scoring_lig.clicked.connect(self.browse_ligand)
        ## Protocol
        self.pushButton_docking_configure_protocol.clicked.connect(self.configure_docking_protocol)
        self.pushButton_scoring_configure_protocol.clicked.connect(self.configure_scoring_protocol)
        ## Execution
        self.pushButton_ligflow_configure_job_queue.clicked.connect(self.configure_workflow_execution)
        self.pushButton_docking_configure_job_queue.clicked.connect(self.configure_workflow_execution)
        self.pushButton_scoring_configure_job_queue.clicked.connect(self.configure_workflow_execution)
        ## Actions
        self.commandLinkButton_ligflow_run.clicked.connect(self.run_ligflow)
        self.commandLinkButton_docking_run.clicked.connect(self.run_docking)
        self.commandLinkButton_docking_postprocess.clicked.connect(self.run_docking_postprocess)
        self.commandLinkButton_docking_archive.clicked.connect(self.run_docking_archive)
        self.commandLinkButton_scoring_run.clicked.connect(self.run_scoring)
        self.commandLinkButton_scoring_postprocess.clicked.connect(self.run_scoring_postprocess)
        self.commandLinkButton_scoring_archive.clicked.connect(self.run_scoring_archive)
        self.commandLinkButton_tools_run.clicked.connect(self.run_tools)
        self.action_buttons = [
            self.commandLinkButton_ligflow_run,
            self.commandLinkButton_docking_run,
            self.commandLinkButton_docking_postprocess,
            self.commandLinkButton_docking_archive,
            self.commandLinkButton_scoring_run,
            self.commandLinkButton_scoring_postprocess,
            self.commandLinkButton_scoring_archive,
            self.commandLinkButton_tools_run,
        ]
        # Output tab
        self.tabWidget.currentChanged.connect(lambda index: self.remove_notification(index))
        self.pushButton_kill.clicked.connect(self.kill_process)
        # Validators
        validator = QtGui.QRegExpValidator(QRegExp('[\w\-\+\.]+')) # only accept letters/numbers and .+-_ as valid
        self.lineEdit_docking_protocol.setValidator(validator)
        self.lineEdit_scoring_protocol.setValidator(validator)
        # Create dictionary that stores all ChemFlow variables
        self.input = {
            'PostProcess': False,
            'Archive': False,
        }
        self.output_nlines = 0
        self.DEBUG = False
        # Logfile
        self.logfile = os.path.join(os.getenv('CHEMFLOW_HOME', os.environ['HOME']), 'chemflow.log')
        logging.basicConfig(filename=self.logfile, level=logging.DEBUG,
            format='%(asctime)s - %(message)s', datefmt='%H:%M:%S')
        timestamp = strftime("%A %d %B %Y", gmtime())
        logging.info('Launching ChemFlow GUI: {}'.format(timestamp))

    def about(self):
        """Show the About section"""
        dialog_about = DialogAbout(parent=main)
        dialog_about.show()

    def github(self):
        """Open the GitHub page in a web browser"""
        browser_open('https://github.com/IFMlab/ChemFlow')

    def report_issue(self):
        """Open the Issue page from the GitHub in a web browser"""
        browser_open('https://github.com/IFMlab/ChemFlow/issues')

    def tutorial(self):
        """Open the tutorial section in a web browser"""
        # TODO update link when commit to master branch
        browser_open('https://github.com/IFMlab/ChemFlow/blob/devel/tutorial/TUTORIAL.rst')

    def debug_mode(self):
        """Activate the debug mode. Prints commands instead of running them"""
        if self.DEBUG:
            self.DEBUG = False
            self.statusBar.showMessage("Debug mode is off", 5000)
        else:
            self.DEBUG = True
            self.statusBar.showMessage("Debug mode is on", 5000)

    def read_logs(self):
        """Open the logfile"""
        if os.path.isfile(self.logfile):
            logger = LogfileDialog(self.logfile, parent=main)
            logger.show()
        else:
            errorDialog(message='No logfile to show')

    def create_project(self):
        """Create a new ChemFlow project"""
        new_project = DialogNewProject()
        new_project.exec_()
        try:
            self.WORKDIR = new_project.project_path
            self.input['Project'] = new_project.project_name
        except AttributeError:
            pass
        else:
            if self.input['Project'][-9:] == '.chemflow':
                self.input['Project'] = self.input['Project'][:-9]

    def load_project(self):
        """Load a ChemFlow project"""
        project_path = QFileDialog.getExistingDirectory(None, "Select ChemFlow project [*.chemflow]", os.getcwd() )
        if project_path not in EMPTY_VALUES:
            if project_path[-9:] != '.chemflow':
                errorDialog(
                    message="This is not a valid ChemFlow project",
                    info="A chemflow project must be a directory ending with .chemflow"
                )
            else:
                self.WORKDIR, self.input['Project'] = os.path.split(project_path)
                self.input['Project'] = self.input['Project'][:-9]

    def browse_receptor(self):
        filetypes = "Mol2 Files (*.mol2);;All Files (*)"
        self.input['Receptor'], _ = QFileDialog.getOpenFileName(None,"Select receptor MOL2 file", os.getcwd(), filetypes)
        if self.input['Receptor']:
            self.lineEdit_docking_rec.setText(self.input['Receptor'])
            self.lineEdit_scoring_rec.setText(self.input['Receptor'])

    def browse_ligand(self):
        filetypes = "Mol2 Files (*.mol2);;All Files (*)"
        self.input['Ligand'], _ = QFileDialog.getOpenFileName(None,"Select ligands MOL2 file", os.getcwd(), filetypes)
        if self.input['Ligand']:
            self.lineEdit_ligflow_lig.setText(self.input['Ligand'])
            self.lineEdit_docking_lig.setText(self.input['Ligand'])
            self.lineEdit_scoring_lig.setText(self.input['Ligand'])

    def configure_docking_protocol(self):
        '''Configure the docking protocol'''
        self.input['docking_software'] = self.comboBox_docking_software.currentText()
        if self.input['docking_software'] == 'AutoDock Vina':
            docking_dialog = DialogDockVina()
        elif self.input['docking_software'] == 'PLANTS':
            docking_dialog = DialogDockPlants()
        docking_dialog.exec_()
        # save the parameters
        try:
            self.docking_protocol = docking_dialog.values
        except AttributeError:
            self.docking_protocol = None
        if self.docking_protocol:
            if self.input['docking_software'] == 'AutoDock Vina':
                # Protocol for Vina
                for kw in [
                'CenterX','CenterY','CenterZ',
                'SizeX','SizeY','SizeZ',
                'Exhaustiveness','EnergyRange','ScoringFunction'
                ]:
                    self.input[kw] = self.docking_protocol[kw]
            elif self.input['docking_software'] == 'PLANTS':
                # Protocol for PLANTS
                for kw in [
                'CenterX','CenterY','CenterZ',
                'Radius','ScoringFunction','ClusterRMSD',
                'Ants','EvaporationRate','IterationScaling','SearchSpeed'
                ]:
                    self.input[kw] = self.docking_protocol[kw]
                # Protocol with Water
                try:
                    self.docking_protocol['WaterFile']
                except KeyError:
                    pass
                else:
                    for kw in ['WaterCenterX','WaterCenterY','WaterCenterZ','WaterRadius','WaterFile']:
                        self.input[kw] = self.docking_protocol[kw]

    def configure_scoring_protocol(self):
        """Configure the rescoring protocol"""
        self.input['scoring_software'] = self.comboBox_scoring_software.currentText()
        if self.input['scoring_software'] == 'AutoDock Vina':
            scoring_dialog = DialogScoreVina()
        elif self.input['scoring_software'] == 'PLANTS':
            scoring_dialog = DialogScorePlants()
        elif self.input['scoring_software'] == 'MM/GBSA':
            scoring_dialog = DialogScoreMmgbsa()
        scoring_dialog.exec_()
        # save the parameters
        try:
            self.scoring_protocol = scoring_dialog.values
        except AttributeError:
            self.scoring_protocol = None
        if self.scoring_protocol:
            if self.input['scoring_software'] == 'AutoDock Vina':
                # Protocol for Vina
                for kw in [
                'CenterX','CenterY','CenterZ',
                'SizeX','SizeY','SizeZ',
                'ScoringFunction','RescoringMode',
                ]:
                    self.input[kw] = self.scoring_protocol[kw]
            elif self.input['scoring_software'] == 'PLANTS':
                # Protocol for PLANTS
                for kw in [
                'CenterX','CenterY','CenterZ',
                'Radius','ScoringFunction',
                ]:
                    self.input[kw] = self.scoring_protocol[kw]
                # Protocol with Water
                try:
                    self.scoring_protocol['WaterFile']
                except KeyError:
                    pass
                else:
                    for kw in ['WaterCenterX','WaterCenterY','WaterCenterZ','WaterRadius','WaterFile']:
                        self.input[kw] = self.scoring_protocol[kw]
            elif self.input['scoring_software'] == 'MM/GBSA':
                # Protocol for MM/GBSA
                for kw in [
                'Charges','ExplicitSolvent','MaxCyc','MD',
                'ScoringFunction',
                ]:
                    self.input[kw] = self.scoring_protocol[kw]

    def configure_workflow_execution(self):
        '''Configure how the workflow is going to run on the local machine'''
        # get the selected execution mode
        if self.tabWidget.currentIndex() == 0: # LigFlow
            self.input['JobQueue'] = self.comboBox_ligflow_job_queue.currentText()
        elif self.tabWidget.currentIndex() == 1: # DockFlow
            self.input['JobQueue'] = self.comboBox_docking_job_queue.currentText()
        elif self.tabWidget.currentIndex() == 2: # ScoreFlow
            self.input['JobQueue'] = self.comboBox_scoring_job_queue.currentText()

        # launch appropriate dialog
        if self.input['JobQueue'] == 'None':
            run_dialog = DialogRunLocal()
        elif self.input['JobQueue'] == 'PBS':
            run_dialog = DialogRunPbs()
        elif self.input['JobQueue'] == 'SLURM':
            run_dialog = DialogRunSlurm()
        run_dialog.exec_()

        # save parameters
        try:
            workflow_execution = run_dialog.values
        except AttributeError:
            workflow_execution = None
        if workflow_execution:
            if self.input['JobQueue'] == 'None':
                self.input['NumCores'] = workflow_execution['NumCores']
            elif self.input['JobQueue'] in ['PBS', 'SLURM']:
                for kw in ['NumCores','HeaderFile']:
                    self.input[kw] = workflow_execution[kw]
            if self.tabWidget.currentIndex() == 0: # LigFlow
                self.ligflow_execution = True
            elif self.tabWidget.currentIndex() == 1: # DockFlow
                self.docking_execution = True
            elif self.tabWidget.currentIndex() == 2: # ScoreFlow
                self.scoring_execution = True

    def check_ligflow_required_args(self):
        """Check values of mandatory arguments for LigFlow"""
        missing = []
        # Get project
        try:
            self.WORKDIR
        except AttributeError:
            missing.append('- ChemFlow project folder')
        # Get rec and lig
        self.input['Ligand'] = self.lineEdit_ligflow_lig.text()
        if self.input['Ligand'] in EMPTY_VALUES:
            missing.append('- Ligand')
        return missing

    def check_docking_required_args(self):
        """Check values of mandatory arguments for DockFlow"""
        missing = []
        # Get project
        try:
            self.WORKDIR
        except AttributeError:
            missing.append('- ChemFlow project folder')
        # Get rec and lig
        self.input['Receptor'] = self.lineEdit_docking_rec.text()
        self.input['Ligand'] = self.lineEdit_docking_lig.text()
        for kw in ['Receptor', 'Ligand']:
            if self.input[kw] in EMPTY_VALUES:
                missing.append('- {}'.format(kw))
        # Get docking protocol
        self.input['Protocol'] = self.lineEdit_docking_protocol.text()
        if self.input['Protocol'] in EMPTY_VALUES:
            missing.append('- Protocol name')
        self.input['NumDockingPoses'] = self.spinBox_docking_nposes.value()
        return missing

    def check_scoring_required_args(self):
        """Check values of mandatory arguments for ScoreFlow"""
        missing = []
        # Get project
        try:
            self.WORKDIR
        except AttributeError:
            missing.append('- ChemFlow project folder')
        # Get rec and lig
        self.input['Receptor'] = self.lineEdit_scoring_rec.text()
        self.input['Ligand'] = self.lineEdit_scoring_lig.text()
        for kw in ['Receptor', 'Ligand']:
            if self.input[kw] in EMPTY_VALUES:
                missing.append('- {}'.format(kw))
        # Get docking protocol
        self.input['Protocol'] = self.lineEdit_scoring_protocol.text()
        if self.input['Protocol'] in EMPTY_VALUES:
            missing.append('- Protocol name')
        return missing

    def run_ligflow(self):
        '''Run ligand preparation with LigFlow'''
        # search for missing configuration
        missing = []
        missing.extend(self.check_ligflow_required_args())
        # Get charges
        self.input['Charges'] = self.comboBox_charges.currentText()
        # Get execution protocol
        try:
            if not self.ligflow_execution:
                missing.append('- LigFlow execution configuration')
        except AttributeError:
            missing.append('- LigFlow execution configuration')
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_ligflow_command())

    def run_docking(self):
        '''Run a docking experiment with DockFlow'''
        self.input['PostProcess'] = False
        self.input['Archive'] = False
        # search for missing configuration
        missing = []
        missing.extend(self.check_docking_required_args())
        try:
            if not self.docking_protocol:
                missing.append('- Docking protocol configuration')
        except AttributeError:
            missing.append('- Docking protocol configuration')
        # Get execution protocol
        try:
            if not self.docking_execution:
                missing.append('- Docking execution configuration')
        except AttributeError:
            missing.append('- Docking execution configuration')
        if self.checkBox_overwrite_docking.isChecked():
            self.input['Overwrite'] = True
        else:
            self.input['Overwrite'] = False
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_docking_command())

    def run_scoring(self):
        '''Run a rescoring experiment with ScoreFlow'''
        self.input['PostProcess'] = False
        self.input['Archive'] = False
        # search for missing configuration
        missing = []
        missing.extend(self.check_scoring_required_args())
        try:
            if not self.scoring_protocol:
                missing.append('- Rescoring protocol configuration')
        except AttributeError:
            missing.append('- Rescoring protocol configuration')
        # Get execution protocol
        try:
            if not self.scoring_execution:
                missing.append('- Rescoring execution configuration')
        except AttributeError:
            missing.append('- Rescoring execution configuration')
        if self.checkBox_overwrite_scoring.isChecked():
            self.input['Overwrite'] = True
        else:
            self.input['Overwrite'] = False
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_scoring_command())

    def run_docking_postprocess(self):
        '''Postprocess docking results'''
        self.input['PostProcess'] = True
        self.input['Archive'] = False
        missing = []
        missing.extend(self.check_docking_required_args())
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_docking_command())

    def run_scoring_postprocess(self):
        '''Postprocess rescoring results'''
        self.input['PostProcess'] = True
        self.input['Archive'] = False
        missing = []
        missing.extend(self.check_scoring_required_args())
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_scoring_command())

    def run_docking_archive(self):
        '''Archive docking results'''
        self.input['Archive'] = True
        self.input['PostProcess'] = False
        missing = []
        missing.extend(self.check_docking_required_args())
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_docking_command())

    def run_scoring_archive(self):
        '''Archive rescoring results'''
        self.input['Archive'] = True
        self.input['PostProcess'] = False
        missing = []
        missing.extend(self.check_scoring_required_args())
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_scoring_command())

    def run_tools(self):
        pass

    def build_ligflow_command(self):
        command = ['LigFlow']
        # Project
        command.extend(['--project', self.input['Project']])
        # Ligand
        command.extend(['--ligand', self.input['Ligand']])
        # Charges
        if self.input['Charges'] == 'Gasteiger':
            pass
        elif self.input['Charges'] == 'AM1-BCC':
            command.append('--bcc')
        elif self.input['Charges'] == 'RESP':
            command.append('--resp')
        # Execution
        command.extend(['--cores', self.input['NumCores']])
        if self.input['JobQueue'] in ['PBS', 'SLURM']:
            if self.input['HeaderFile'] not in EMPTY_VALUES:
                command.extend(['--header', self.input['HeaderFile']])
            if self.input['JobQueue'] == 'PBS':
                command.append('--pbs')
            elif self.input['JobQueue'] == 'SLURM':
                command.append('--slurm')
        return command

    def build_docking_command(self):
        '''Generate a command for DockFlow.
        RETURNS: LIST'''
        command = ['DockFlow']
        # Project
        command.extend(['--project', self.input['Project']])
        # Receptor and ligand
        command.extend(['--receptor', self.input['Receptor']])
        command.extend(['--ligand', self.input['Ligand']])
        # Protocol
        command.extend(['--protocol', self.input['Protocol']])
        # Archive
        if self.input['Archive']:
            command.append('--archive')
            return command
        # Number of docking poses
        command.extend(['-n', self.input['NumDockingPoses']])
        # Scoring functions
        command.extend(['-sf', self.input['ScoringFunction']])
        # Overwrite
        if self.input['Overwrite']:
            command.append('--overwrite')
        # Postprocess
        if self.input['PostProcess']:
            command.append('--postprocess')
            return command
        # Docking protocol
        command.extend(['--center',
            self.input['CenterX'],
            self.input['CenterY'],
            self.input['CenterZ']])
        # Execution
        command.extend(['--cores', self.input['NumCores']])
        if self.input['JobQueue'] in ['PBS', 'SLURM']:
            if self.input['HeaderFile'] not in EMPTY_VALUES:
                command.extend(['--header', self.input['HeaderFile']])
            if self.input['JobQueue'] == 'PBS':
                command.append('--pbs')
            elif self.input['JobQueue'] == 'SLURM':
                command.append('--slurm')
        # PLANTS
        if self.input['docking_software'] == 'PLANTS':
            command.extend(['--speed', self.input['SearchSpeed']])
            command.extend(['--cluster_rmsd', self.input['ClusterRMSD']])
            command.extend(['--ants', self.input['Ants']])
            command.extend(['--evap_rate', self.input['EvaporationRate']])
            command.extend(['--iter_scaling', self.input['IterationScaling']])
            command.extend(['--radius', self.input['Radius']])
            try: # Docking with Water
                command.extend(['--water', self.input['WaterFile']])
                command.extend(['--water_xyzr',
                    self.input['WaterCenterX'],
                    self.input['WaterCenterY'],
                    self.input['WaterCenterZ'],
                    self.input['WaterRadius']])
            except KeyError:
                pass
        # Vina
        elif self.input['docking_software'] == 'AutoDock Vina':
            command.extend(['--size',
                self.input['SizeX'],
                self.input['SizeY'],
                self.input['SizeZ']])
            command.extend(['--exhaustiveness', self.input['Exhaustiveness']])
            command.extend(['--energy_range', self.input['EnergyRange']])
        return command

    def build_scoring_command(self):
        command = ['ScoreFlow']
        # Project
        command.extend(['--project', self.input['Project']])
        # Receptor and ligand
        command.extend(['--receptor', self.input['Receptor']])
        command.extend(['--ligand', self.input['Ligand']])
        # Protocol
        command.extend(['--protocol', self.input['Protocol']])
        # Archive
        if self.input['Archive']:
            command.append('--archive')
            return command
        # Scoring functions
        command.extend(['-sf', self.input['ScoringFunction']])
        # Overwrite
        if self.input['Overwrite']:
            command.append('--overwrite')
        # Postprocess
        if self.input['PostProcess']:
            command.append('--postprocess')
            return command
        # Center of binding site for plants and vina
        if self.input['scoring_software'] in ['PLANTS', 'AutoDock Vina']:
            command.extend(['--center',
                self.input['CenterX'],
                self.input['CenterY'],
                self.input['CenterZ']])
        # PLANTS
        if self.input['scoring_software'] == 'PLANTS':
            command.extend(['--radius', self.input['Radius']])
            try: # Docking with Water
                command.extend(['--water', self.input['WaterFile']])
                command.extend(['--water_xyzr',
                    self.input['WaterCenterX'],
                    self.input['WaterCenterY'],
                    self.input['WaterCenterZ'],
                    self.input['WaterRadius']])
            except KeyError:
                pass
        # Vina
        elif self.input['scoring_software'] == 'AutoDock Vina':
            command.extend(['--size',
                self.input['SizeX'],
                self.input['SizeY'],
                self.input['SizeZ']])
            command.extend(['--vina-mode', self.input['RescoringMode']])
        # MM/GBSA
        elif self.input['scoring_software'] == 'MM/GBSA':
            # Charges
            if self.input['Charges'] == 'Gasteiger':
                command.append('--gas')
            elif self.input['Charges'] == 'AM1-BCC':
                command.append('--bcc')
            elif self.input['Charges'] == 'RESP':
                command.append('--resp')
            # Solvent
            if self.input['ExplicitSolvent']:
                command.append('--water')
            else:
                command.extend(['--maxcyc', self.input['MaxCyc']])
            # MD
            if self.input['MD']:
                command.append('--md')
            # Execution - only available for mmgbsa for now
            command.extend(['--cores', self.input['NumCores']])
            if self.input['JobQueue'] in ['PBS', 'SLURM']:
                if self.input['HeaderFile'] not in EMPTY_VALUES:
                    command.extend(['--header', self.input['HeaderFile']])
                if self.input['JobQueue'] == 'PBS':
                    command.append('--pbs')
                elif self.input['JobQueue'] == 'SLURM':
                    command.append('--slurm')
        return command


    def execute_command(self, command):
        """Run a command through a QProcess. The command can ask for user input at any point, as long as the '?' character
        is shown before the prompt (i.e avoid `read -p "Continue? [y/n] " opt` and use `echo -n "Continue? [y/n] "; read opt` instead)
        command: LIST"""
        CMD = ' '.join([str(i) for i in command])
        if self.DEBUG:
            self.display(CMD)
            self.lineEdit_command.setText(CMD)
        else:
            # create process
            self.process = QProcess()
            self.pushButton_kill.setEnabled(True)
            self.process.setWorkingDirectory(self.WORKDIR)
            # Merge STDOUT and STDERR
            self.process.setProcessChannelMode(QProcess.MergedChannels)
            # Capture STDIN
            self.process.setInputChannelMode(QProcess.ManagedInputChannel)
            # Display STDOUT as it arrives and take action
            self.process.readyReadStandardOutput.connect(self.capture_stdin_stdout)
            # Connect signals from the process
            self.process.stateChanged.connect(lambda state: self.lineEdit_status.setText(PROCESS_STATE[state]))
            self.process.started.connect(self.process_started)
            self.process.finished.connect(lambda status: self.process_finished(status))
            self.process.errorOccurred.connect(lambda error: self.process_error(error))
            # Execute
            self.process.start(CMD)

    def process_started(self):
        """Routine launched at the start of a QProcess"""
        command = ' '.join([arg for arg in [self.process.program()] + self.process.arguments()])
        self.lineEdit_command.setText(command)
        self.display(command)
        self.summary_text = ''
        self.display('[ ChemFlow ] {} was spawned with PID {}'.format(self.process.program(), self.process.processId()))
        # Prevent user from launching other commands
        for button in self.action_buttons:
            button.setEnabled(False)

    def process_finished(self, status):
        """Routine launched when a QProcess is finished"""
        self.display('[ ChemFlow ] {} process ended with exit status {}'.format(self.process.program(), status))
        self.pushButton_kill.setEnabled(False)
        # Allow user to send new commands
        for button in self.action_buttons:
            button.setEnabled(True)
        self.process.close()

    def process_error(self, error):
        """Routine launched when a QProcess signals an error"""
        self.display('[ ChemFlow ] ERROR while running {} process - {}'.format(self.process.program(), PROCESS_ERROR[error]))

    def kill_process(self):
        """Kill a QProcess"""
        self.display('[ ChemFlow ] Killing {} with PID {}'.format(self.process.program(), self.process.processId()))
        self.process.kill()

    def capture_stdin_stdout(self):
        """Display STDOUT while searching for STDIN events"""
        text = str(self.process.readAllStandardOutput().data().decode('utf-8'))
        if text:
            self.display(text)
            # Process text line by line
            text = text.split('\n')
            for line in text:
                # Add content to summary if necessary
                if len(self.summary_text):
                    self.summary_text += line + '\n'
                # Detect summary start
                if 'Flow summary:' in line:
                    self.summary_text = line + '\n'
                # Capture questions
                elif '?' in line:
                    # switch to the Output tab
                    self.tabWidget.setCurrentIndex(self.tabWidget.indexOf(self.tab_Output))
                    self.remove_notification(self.tabWidget.indexOf(self.tab_Output))
                    # Yes No question
                    if '[y/n]' in line:
                        if len(self.summary_text):
                            answer = yesNoDialog(
                                title='{} summary'.format(self.process.program()),
                                message='Please check carefully the protocol details below',
                                info='Continue ?',
                                details='\n'.join(self.summary_text.split('\n')[2:-2]),
                            )
                            self.summary_text = ''
                        else:
                            answer = yesNoDialog(message=line)
                        self.display(answer)
                        self.process.write('{}\n'.format(answer).encode('utf-8'))
                    # Other question
                    else:
                        qdialog = DialogQuestion(question=line)
                        qdialog.exec_()
                        answer = qdialog.answer
                        self.display(answer)
                        self.process.write('{}\n'.format(answer).encode('utf-8'))

    def display(self, text):
        """Print text on the Output tab and to the logfile"""
        self.output_display.insertPlainText(text + '\n')
        self.output_display.moveCursor(QtGui.QTextCursor.End)
        logging.info(text)
        self.output_nlines += 1
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab_Output), 'Output ({})'.format(self.output_nlines))

    def remove_notification(self, index):
        """Remove the notification of the output tab when the user switches to it"""
        if index == self.tabWidget.indexOf(self.tab_Output):
            self.tabWidget.setTabText(index, 'Output')
            self.output_nlines = 0

    def closeEvent(self, event):
        """Routine launched when quitting the ChemFlow app"""
        cleanParameters(CWDIR)
        self.display("[ ChemFlow ] Closing...")
        QMainWindow.closeEvent(self, event)


if __name__ == '__main__':
    # create widget
    app = QtWidgets.QApplication(sys.argv)
    # Use custom fonts and stylesheet
    for filename in os.listdir(os.path.realpath(os.path.join(WORKDIR, "fonts"))):
        font = os.path.realpath(os.path.join(WORKDIR, "fonts", filename))
        QtGui.QFontDatabase.addApplicationFont(font)
    stylesheet_path = os.path.realpath(os.path.join(WORKDIR, "qss", "chemflow.css"))
    with open(stylesheet_path, 'r') as f:
        STYLESHEET = f.read()
    app.setStyleSheet(STYLESHEET)
    # show app
    main = Main()
    main.show()
    # exit
    sys.exit(app.exec_())
