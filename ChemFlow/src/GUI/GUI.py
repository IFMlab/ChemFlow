#!/usr/bin/env python

from PyQt5 import QtGui, QtWidgets
from PyQt5.QtWidgets import QFileDialog, QMainWindow
import pexpect
import sys, os, webbrowser
from utils import (
    WORKDIR, CWDIR, EMPTY_VALUES,
    cleanParameters,
    missingParametersDialog, errorDialog, yesNoDialog,
)
from MainClasses import DialogAbout, DialogNewProject, DialogQuestion
from DockingClasses import DialogDockVina, DialogDockPlants
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
        run_logo_path = os.path.realpath(os.path.join(WORKDIR, "img", "run.png"))
        self.label_dock_logo.setPixmap(QtGui.QPixmap(run_logo_path))
        postprocess_logo_path = os.path.realpath(os.path.join(WORKDIR, "img", "process.png"))
        self.label_postdock_logo.setPixmap(QtGui.QPixmap(postprocess_logo_path))
        archive_logo_path = os.path.realpath(os.path.join(WORKDIR, "img", "archive.png"))
        self.label_archivedock_logo.setPixmap(QtGui.QPixmap(archive_logo_path))
        # connect buttons with actions
        ## Menu
        self.actionAbout.triggered.connect(self.about)
        self.actionGitHub.triggered.connect(self.github)
        self.actionReport_issue.triggered.connect(self.report_issue)
        self.actionTutorial.triggered.connect(self.tutorial)
        self.actionDebug_mode.triggered.connect(self.debug_mode)
        self.actionNew_project.triggered.connect(self.create_project)
        self.actionLoad_project.triggered.connect(self.load_project)
        ## Input
        self.pushButton_docking_rec.clicked.connect(self.browse_docking_receptor)
        self.pushButton_docking_lig.clicked.connect(self.browse_docking_ligand)
        ## Protocol
        self.pushButton_docking_configure_protocol.clicked.connect(self.configure_docking_protocol)
        ## Execution
        self.pushButton_docking_configure_job_queue.clicked.connect(self.configure_docking_execution)
        ## Actions
        self.pushButton_docking_run.clicked.connect(self.run_docking)
        self.pushButton_docking_postprocess.clicked.connect(self.run_docking_postprocess)
        self.pushButton_docking_archive.clicked.connect(self.run_docking_archive)
        # Create dictionary that stores all ChemFlow variables
        self.input = {
            'PostProcess': False,
            'Archive': False,
        }
        self.DEBUG = False

    def about(self):
        """Show the About section"""
        dialog_about = DialogAbout()
        dialog_about.exec_()

    def github(self):
        """Open the GitHub page in a web browser"""
        webbrowser.open('https://github.com/IFMlab/ChemFlow')

    def report_issue(self):
        """Open the Issue page from the GitHub in a web browser"""
        webbrowser.open('https://github.com/IFMlab/ChemFlow/issues')

    def tutorial(self):
        """Open the tutorial section in a web browser"""
        # TODO update link when commit to master branch
        webbrowser.open('https://github.com/IFMlab/ChemFlow/blob/devel/tutorial/TUTORIAL.rst')

    def debug_mode(self):
        """Activate the debug mode. Prints commands instead of running them"""
        if self.DEBUG:
            self.DEBUG = False
            self.statusBar.showMessage("Debug mode is off", 5000)
        else:
            self.DEBUG = True
            self.statusBar.showMessage("Debug mode is on", 5000)

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


    def browse_docking_receptor(self):
        filetypes = "Mol2 Files (*.mol2);;All Files (*)"
        self.input['Receptor'], _ = QFileDialog.getOpenFileName(None,"Select receptor MOL2 file", os.getcwd(), filetypes)
        if self.input['Receptor']:
            self.lineEdit_docking_rec.setText(self.input['Receptor'])

    def browse_docking_ligand(self):
        filetypes = "Mol2 Files (*.mol2);;All Files (*)"
        self.input['Ligand'], _ = QFileDialog.getOpenFileName(None,"Select ligands MOL2 file", os.getcwd(), filetypes)
        if self.input['Ligand']:
            self.lineEdit_docking_lig.setText(self.input['Ligand'])

    def configure_docking_protocol(self):
        self.input['docking_software'] = self.comboBox_docking_software.currentText()
        if self.input['docking_software'] == 'AutoDock Vina':
            docking_dialog = DialogDockVina()
        elif self.input['docking_software'] == 'PLANTS':
            docking_dialog = DialogDockPlants()
        docking_dialog.exec_()
        try:
            self.docking_protocol = docking_dialog.values
        except AttributeError:
            self.docking_protocol = None
        if self.docking_protocol:
            if self.input['docking_software'] == 'AutoDock Vina':
                # Protocol for Vina
                for kw in [
                'DockCenterX','DockCenterY','DockCenterZ',
                'DockSizeX','DockSizeY','DockSizeZ',
                'Exhaustiveness','EnergyRange'
                ]:
                    self.input[kw] = self.docking_protocol[kw]
                self.input['ScoringFunction'] = 'vina'
            elif self.input['docking_software'] == 'PLANTS':
                # Protocol for PLANTS
                for kw in [
                'DockCenterX','DockCenterY','DockCenterZ',
                'DockRadius','ScoringFunction',
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

    def configure_docking_execution(self):
        self.input['JobQueue'] = self.comboBox_docking_job_queue.currentText()
        if self.input['JobQueue'] == 'None':
            run_dialog = DialogRunLocal()
        elif self.input['JobQueue'] == 'PBS':
            run_dialog = DialogRunPbs()
        elif self.input['JobQueue'] == 'SLURM':
            run_dialog = DialogRunSlurm()
        run_dialog.exec_()
        try:
            self.docking_execution = run_dialog.values
        except AttributeError:
            self.docking_execution = None
        if self.docking_execution:
            if self.input['JobQueue'] == 'None':
                self.input['NumCores'] = self.docking_execution['NumCores']
            elif self.input['JobQueue'] in ['PBS', 'SLURM']:
                for kw in ['NumCores','NumNodes','HeaderFile']:
                    self.input[kw] = self.docking_execution[kw]

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

    def run_docking(self):
        self.input['PostProcess'] = False
        self.input['Archive'] = False
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
        if self.checkBox_overwrite.isChecked():
            self.input['Overwrite'] = True
        else:
            self.input['Overwrite'] = False
        # Show errors or execute
        if missing:
            missingParametersDialog(*missing)
        else:
            # Execute
            self.execute_command(self.build_docking_command())

    def run_docking_postprocess(self):
        self.input['PostProcess'] = True
        self.input['Archive'] = False
        missing = []
        missing.extend(self.check_docking_required_args())
        # Execute
        self.execute_command(self.build_docking_command())

    def run_docking_archive(self):
        self.input['Archive'] = True
        self.input['PostProcess'] = False
        missing = []
        missing.extend(self.check_docking_required_args())
        # Execute
        self.execute_command(self.build_docking_command())

    def build_docking_command(self):
        command = ['DockFlow']
        # Project
        command.extend(['--project', self.input['Project']])
        # Receptor and ligand
        command.extend(['--receptor', self.input['Receptor']])
        command.extend(['--ligand', self.input['Ligand']])
        # Protocol
        command.extend(['--protocol', self.input['Protocol']])
        command.extend(['-n', self.input['NumDockingPoses']])
        # Postprocess and archive
        if self.input['PostProcess']:
            command.append('--postprocess')
            return command
        if self.input['Archive']:
            command.append('--archive')
            return command
        # Docking protocol
        command.extend(['-sf', self.input['ScoringFunction']])
        command.extend(['--center',
            self.input['DockCenterX'],
            self.input['DockCenterY'],
            self.input['DockCenterZ']])
        # Execution
        command.extend(['--cores', self.input['NumCores']])
        if self.input['JobQueue'] in ['PBS', 'SLURM']:
            command.extend(['--nodes', self.input['NumNodes']])
            if self.input['HeaderFile'] not in EMPTY_VALUES:
                command.extend(['--header', self.input['HeaderFile']])
            if self.input['JobQueue'] == 'PBS':
                command.append('--pbs')
            elif self.input['JobQueue'] == 'SLURM':
                command.append('--slurm')
        if self.input['Overwrite']:
            command.append('--overwrite')
        # PLANTS
        if self.input['docking_software'] == 'PLANTS':
            command.extend(['--speed', self.input['SearchSpeed']])
            command.extend(['--ants', self.input['Ants']])
            command.extend(['--evap_rate', self.input['EvaporationRate']])
            command.extend(['--iteration_scaling', self.input['IterationScaling']])
            command.extend(['--radius', self.input['DockRadius']])
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
                self.input['DockSizeX'],
                self.input['DockSizeY'],
                self.input['DockSizeZ']])
            command.extend(['--exhaustiveness', self.input['Exhaustiveness']])
            command.extend(['--energy_range', self.input['EnergyRange']])
        return command

    def execute_command(self, command):
        CMD = ' '.join([str(i) for i in command])
        if self.DEBUG:
            print(CMD)
        else:
            child = pexpect.spawn(CMD, cwd=self.WORKDIR,
                timeout=None, encoding='utf-8')
            child.logfile_read = sys.stdout
            print('[ ChemFlow GUI ] {} was spawned with PID {}'.format(command[0], child.pid))
            _continue = True
            while _continue:
                # search for a question or the EOF signal
                index = child.expect(['\?', pexpect.EOF])
                if index == 0: # question
                    # Get the question from the buffer
                    split = child.before.split('\n')
                    if len(split) > 1:
                        msg = split[-1]
                    else:
                        msg = child.before
                    # Separate yes/no questions from others
                    if '[y/n]' in msg:
                        answer = yesNoDialog(message=msg)
                    else:
                        qdialog = DialogQuestion(question=msg)
                        qdialog.exec_()
                        answer = qdialog.answer
                    # Send answer to child
                    child.sendline(answer)
                elif index == 1: # EOF signal
                    _continue = False
                    print('[ ChemFlow GUI ] Normal termination of the child process')

    def closeEvent(self, event):
        cleanParameters(CWDIR)
        QMainWindow.closeEvent(self, event)


if __name__ == '__main__':
    OLDDIR = os.getcwd()
    # create widget and show
    app = QtWidgets.QApplication(sys.argv)
    main = Main()
    main.show()
    os.chdir(OLDDIR)
    sys.exit(app.exec_())
