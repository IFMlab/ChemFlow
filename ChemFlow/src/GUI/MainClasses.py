import os, sys
from PyQt5 import QtGui
from PyQt5.QtWidgets import QDialog, QFileDialog, QMessageBox, QStyle, QTextEdit
from PyQt5.QtCore import QSettings, QSize, QRegExp
from qt_creator.UIabout import Ui_About
from qt_creator.UIcreate_project import Ui_CreateProject
from qt_creator.UIquestion import Ui_QuestionDialog
from qt_creator.UIlogfile import Ui_Logfile
from utils import (
    WORKDIR, INI_FILE, EMPTY_VALUES,
    guiSave, guiRestore,
    missingParametersDialog, errorDialog,
)

class DialogAbout(QDialog, Ui_About):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        logo_path = os.path.realpath(os.path.join(WORKDIR, "img", "logo.png"))
        self.label_logo.setPixmap(QtGui.QPixmap(logo_path))
        self.pushButton.clicked.connect(self.close)
        self.textBrowser.setOpenExternalLinks(True)


class LogfileDialog(QDialog, Ui_Logfile):
    def __init__(self, logfile, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        self.logfile = logfile
        self.pushButton_close.clicked.connect(self.close)
        self.pushButton_remove.clicked.connect(self.remove_log)
        self.plainTextEdit_log.insertPlainText(open(self.logfile).read())
        self.plainTextEdit_log.moveCursor(QtGui.QTextCursor.End)
        self.lineEdit.setText(self.logfile)

    def remove_log(self):
        if os.path.isfile(self.logfile):
            os.remove(self.logfile)
        self.pushButton_remove.setEnabled(False)


class DialogQuestion(QDialog, Ui_QuestionDialog):
    def __init__(self, parent=None, question=""):
        super().__init__(parent)
        self.setupUi(self)
        icon = self.style().standardIcon(getattr(QStyle, 'SP_MessageBoxQuestion'))
        pixmap = icon.pixmap(QSize(48,48))
        self.label_logo.setPixmap(pixmap)
        self.pushButton.clicked.connect(self.submit)
        textEdit = QTextEdit()
        self.scrollArea.setWidget(textEdit)
        textEdit.setText(question)

    def submit(self):
        answer = self.lineEdit.text()
        if answer in EMPTY_VALUES:
            errorDialog(message="You must submit a valid answer")
        else:
            self.answer = answer
            self.close()


class DialogNewProject(QDialog, Ui_CreateProject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setupUi(self)
        # Buttons
        self.pushButton_browse.clicked.connect(self.browse_project)
        self.pushButton_ok.clicked.connect(self.validate)
        self.pushButton_cancel.clicked.connect(self.close)
        # Validator
        validator = QtGui.QRegExpValidator(QRegExp('[\w\-\+\.]+'))
        self.lineEdit_name.setValidator(validator)
        # Settings
        self.settings = QSettings(INI_FILE, QSettings.IniFormat)
        guiRestore(self, self.settings)

    def closeEvent(self, event):
        guiSave(self, self.settings)
        QDialog.closeEvent(self, event)

    def browse_project(self):
        self.project_path = QFileDialog.getExistingDirectory(None, "Select ChemFlow project location", os.getcwd() )
        if self.project_path:
            self.lineEdit_path.setText(self.project_path)

    def validate(self):
        missing = []
        self.project_name = self.lineEdit_name.text()
        self.project_path = self.lineEdit_path.text()
        if self.project_name in EMPTY_VALUES:
            missing.append('- Project name')
        if self.project_path in EMPTY_VALUES:
            missing.append('- Project location')
        if len(missing):
            missingParametersDialog(*missing)
        else:
            if os.path.isdir(self.project_path):
                self.close()
            else:
                errorDialog(message="The directory {} does not exist.".format(self.project_path))
