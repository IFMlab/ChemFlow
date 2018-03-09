import sys, os, inspect
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

def saveUsefullPaths(ui, settings):
    usefullPathNames =  ['textBrowser_PlantsExec', 'textBrowser_SporesExec',
    'textBrowser_vinaExec', 'textBrowser_MGLFolder', 'textBrowser_amber']
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QTextBrowser):
            name = obj.objectName()
            if name in usefullPathNames:
                value = obj.toPlainText()
                settings.setValue(name, value)

def restoreUsefullPaths(ui, settings):
    usefullPathNames =  ['textBrowser_PlantsExec', 'textBrowser_SporesExec',
    'textBrowser_vinaExec', 'textBrowser_MGLFolder', 'textBrowser_amber']
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QTextBrowser):
            name = obj.objectName()
            if name in usefullPathNames:
                value = settings.value(name)
                obj.setPlainText(value)

def cleanParameters(dirName):
    iniFile = '{}/ini/parameters.ini'.format(dirName)
    if os.path.isfile(iniFile):
        os.remove(iniFile)
