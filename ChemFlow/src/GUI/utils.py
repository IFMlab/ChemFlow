import os, sys, inspect
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *

def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.environ.get("_MEIPASS2", os.path.abspath("."))
    return os.path.join(base_path, relative_path)

def cleanParameters(dirName):
    iniFile = '{}/.parameters.ini'.format(dirName)
    if os.path.isfile(iniFile):
        os.remove(iniFile)

def guiSave(ui, settings):
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QComboBox):
            name = obj.objectName()
            index = obj.currentIndex()
            text = obj.itemText(index)
            settings.setValue(name, text)

        elif isinstance(obj, QLineEdit):
            name = obj.objectName()
            value = obj.text()
            settings.setValue(name, value)

        elif isinstance(obj, QLineEdit):
            name = obj.objectName()
            value = obj.text()
            settings.setValue(name, value)

        elif isinstance(obj, QPlainTextEdit):
            name = obj.objectName()
            value = obj.toPlainText()
            settings.setValue(name, value)

        elif isinstance(obj, QTextBrowser):
            name = obj.objectName()
            value = obj.toPlainText()
            settings.setValue(name, value)

        elif isinstance(obj, QCheckBox):
            name = obj.objectName()
            state = obj.isChecked()
            settings.setValue(name, state)

        elif isinstance(obj, QRadioButton):
            name = obj.objectName()
            value = obj.isChecked()
            settings.setValue(name, value)

        elif isinstance(obj, QSpinBox):
            name = obj.objectName()
            value = obj.value()
            settings.setValue(name, value)

        elif isinstance(obj, QDoubleSpinBox):
            name = obj.objectName()
            value = obj.value()
            settings.setValue(name, value)

        elif isinstance(obj, QSlider):
            name  = obj.objectName()
            value = obj.value()
            settings.setValue(name, value)

def guiRestore(ui, settings):
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QComboBox):
            name = obj.objectName()
            value = (settings.value(name))
            if (value == "") or (value is None):
                continue
            index = obj.findText(value)
            if index == -1:
                obj.insertItems(0, [value])
                index = obj.findText(value)
                obj.setCurrentIndex(index)
            else:
                obj.setCurrentIndex(index)

        elif isinstance(obj, QLineEdit):
            name = obj.objectName()
            value = settings.value(name)
            obj.setText(value)

        elif isinstance(obj, QPlainTextEdit):
            name = obj.objectName()
            value = settings.value(name)
            obj.setPlainText(value)

        elif isinstance(obj, QTextBrowser):
            name = obj.objectName()
            value = settings.value(name)
            obj.setPlainText(value)

        elif isinstance(obj, QCheckBox):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setChecked(bool(value))

        elif isinstance(obj, QRadioButton):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setChecked(bool(value))

        elif isinstance(obj, QSlider):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setValue(int(value))

        elif isinstance(obj, QSpinBox):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setValue(int(value))

        elif isinstance(obj, QDoubleSpinBox):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setValue(float(value))

def missingParametersDialog(*args):
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Critical)
    msg.setText("You must configure the following parameters:")
    msg.setInformativeText('\n'.join(args))
    msg.setWindowTitle("Error: Missing parameters")
    msg.setStandardButtons(QMessageBox.Ok)
    retval = msg.exec_()
    if retval == 1024: # Ok
        msg.close()

def errorDialog(title="Error", message="", info=""):
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Critical)
    msg.setText(message)
    msg.setInformativeText(info)
    msg.setWindowTitle(title)
    msg.setStandardButtons(QMessageBox.Ok)
    retval = msg.exec_()
    if retval == QMessageBox.Ok:
        msg.close()

def yesNoDialog(title="Question", message="", info="", details=""):
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Question)
    msg.setText(message)
    msg.setInformativeText(info)
    if details:
        msg.setDetailedText(details)
    msg.setWindowTitle(title)
    msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
    retval = msg.exec_()
    msg.close()
    if retval == QMessageBox.Yes:
        return 'y'
    else:
        return 'n'


EMPTY_VALUES = [None, '', ' ']
PROCESS_STATE = {
    QProcess.NotRunning: "Not Running",
    QProcess.Starting: "Starting",
    QProcess.Running: "Running"
}
PROCESS_ERROR = {
    QProcess.FailedToStart: "The process failed to start. Either the invoked program is missing, or you may have insufficient permissions to invoke the program.",
    QProcess.Crashed: "The process crashed some time after starting successfully.",
    QProcess.Timedout: "Timed out",
    QProcess.WriteError: "An error occurred when attempting to write to the process.",
    QProcess.ReadError: "An error occurred when attempting to read from the process.",
    QProcess.UnknownError: "An unknown error occurred."
}
# directory where the binary is being decompressed and executed, usually /tmp/_MEIxxxxxx
WORKDIR = os.path.dirname(resource_path(__file__))
# directory where the binary that was launched is
CWDIR = os.path.dirname(os.path.realpath(sys.argv[0]))
# Ini file containing all parameters and values
INI_FILE = os.path.realpath(os.path.join(CWDIR, ".parameters.ini"))
