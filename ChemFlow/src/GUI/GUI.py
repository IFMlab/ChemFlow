#!/usr/bin/env python

from PyQt5 import QtGui, QtWidgets
from PyQt5.QtWidgets import QFileDialog, QMainWindow
from PyQt5.QtCore import QProcess, QByteArray
from webbrowser import open as browser_open
from time import strftime, gmtime
import sys, os, logging
from utils import (
    WORKDIR, CWDIR, EMPTY_VALUES, PROCESS_ERROR, PROCESS_STATE,
    cleanParameters, missingParametersDialog, errorDialog, yesNoDialog,
)
from MainClasses import DialogAbout, DialogNewProject, DialogQuestion, LogfileDialog
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
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap(os.path.realpath(os.path.join(WORKDIR, "img", "run.png"))), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.commandLinkButton_docking_run.setIcon(icon)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap(os.path.realpath(os.path.join(WORKDIR, "img", "process.png"))), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.commandLinkButton_docking_postprocess.setIcon(icon)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap(os.path.realpath(os.path.join(WORKDIR, "img", "archive.png"))), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        self.commandLinkButton_docking_archive.setIcon(icon)
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
        self.pushButton_docking_rec.clicked.connect(self.browse_docking_receptor)
        self.pushButton_docking_lig.clicked.connect(self.browse_docking_ligand)
        ## Protocol
        self.pushButton_docking_configure_protocol.clicked.connect(self.configure_docking_protocol)
        ## Execution
        self.pushButton_docking_configure_job_queue.clicked.connect(self.configure_docking_execution)
        ## Actions
        self.commandLinkButton_docking_run.clicked.connect(self.run_docking)
        self.commandLinkButton_docking_postprocess.clicked.connect(self.run_docking_postprocess)
        self.commandLinkButton_docking_archive.clicked.connect(self.run_docking_archive)
        self.action_buttons = [
            self.commandLinkButton_docking_run,
            self.commandLinkButton_docking_postprocess,
            self.commandLinkButton_docking_archive,
        ]
        # Output tab
        self.pushButton_kill.clicked.connect(self.kill_process)
        # Validators
        validator = QtGui.QRegExpValidator(QRegExp('[\w\-\+\.]+')) # only accept letters/numbers and .+-_ as valid
        self.lineEdit_docking_protocol.setValidator(validator)
        # Create dictionary that stores all ChemFlow variables
        self.input = {
            'PostProcess': False,
            'Archive': False,
        }
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
                'DockRadius','ScoringFunction','ClusterRMSD',
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
        '''Configure how DockFlow is going to run on the local machine'''
        self.input['JobQueue'] = self.comboBox_docking_job_queue.currentText()
        if self.input['JobQueue'] == 'None':
            run_dialog = DialogRunLocal()
        elif self.input['JobQueue'] == 'PBS':
            run_dialog = DialogRunPbs()
        elif self.input['JobQueue'] == 'SLURM':
            run_dialog = DialogRunSlurm()
        run_dialog.exec_()
        # save parameters
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
        # Postprocess
        if self.input['PostProcess']:
            command.append('--postprocess')
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
            command.extend(['--cluster_rmsd', self.input['ClusterRMSD']])
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
        """Run a command through a QProcess. The command can ask for user input at any point, as long as the '?' character
        is shown before the prompt (i.e avoid `read -p "Continue? [y/n] " opt` and use `echo -n "Continue? [y/n] "; read opt` instead)
        command: LIST"""
        CMD = ' '.join([str(i) for i in command])
        if self.DEBUG:
            self.display(CMD)
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
                    self.tabWidget.setCurrentIndex(4)
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
    stylesheet = os.path.realpath(os.path.join(WORKDIR, "qss", "chemflow.css"))
    app.setStyleSheet(open(stylesheet).read())
    # show app
    main = Main()
    main.show()
    # exit
    sys.exit(app.exec_())
