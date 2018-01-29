import sys, os, inspect
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *

def guiSave(ui, settings):
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QComboBox):
            name = obj.objectName()
            index = obj.currentIndex()
            text = obj.itemText(index)
            settings.setValue(name, text)

        if isinstance(obj, QLineEdit):
            name = obj.objectName()
            value = obj.text()
            settings.setValue(name, value)

        if isinstance(obj, QLineEdit):
            name = obj.objectName()
            value = obj.text()
            settings.setValue(name, value)

        if isinstance(obj, QPlainTextEdit):
            name = obj.objectName()
            value = obj.toPlainText()
            settings.setValue(name, value)

        if isinstance(obj, QTextBrowser):
            name = obj.objectName()
            value = obj.toPlainText()
            settings.setValue(name, value)

        if isinstance(obj, QCheckBox):
            name = obj.objectName()
            state = obj.isChecked()
            settings.setValue(name, state)

        if isinstance(obj, QRadioButton):
            name = obj.objectName()
            value = obj.isChecked()
            settings.setValue(name, value)

        if isinstance(obj, QSpinBox):
            name = obj.objectName()
            value = obj.value()
            settings.setValue(name, value)

        if isinstance(obj, QDoubleSpinBox):
            name = obj.objectName()
            value = obj.value()
            settings.setValue(name, value)

        if isinstance(obj, QSlider):
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

        if isinstance(obj, QLineEdit):
            name = obj.objectName()
            value = settings.value(name)
            obj.setText(value)

        if isinstance(obj, QPlainTextEdit):
            name = obj.objectName()
            value = settings.value(name)
            obj.setPlainText(value)

        if isinstance(obj, QTextBrowser):
            name = obj.objectName()
            value = settings.value(name)
            obj.setPlainText(value)

        if isinstance(obj, QCheckBox):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setChecked(bool(value))

        if isinstance(obj, QRadioButton):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setChecked(bool(value))

        if isinstance(obj, QSlider):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setValue(int(value))

        if isinstance(obj, QSpinBox):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setValue(int(value))

        if isinstance(obj, QDoubleSpinBox):
            name = obj.objectName()
            value = settings.value(name)
            if value is not None:
                obj.setValue(float(value))

def saveUsefullPaths(ui, settings):
    usefullPathNames =  ['textBrowser_PlantsExec', 'textBrowser_SporesExec',
    'textBrowser_vinaExec', 'textBrowser_adtFolder', 'textBrowser_amber']
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QTextBrowser):
            name = obj.objectName()
            if name in usefullPathNames:
                value = obj.toPlainText()
                settings.setValue(name, value)

def restoreUsefullPaths(ui, settings):
    usefullPathNames =  ['textBrowser_PlantsExec', 'textBrowser_SporesExec',
    'textBrowser_vinaExec', 'textBrowser_adtFolder', 'textBrowser_amber']
    for name, obj in inspect.getmembers(ui):
        if isinstance(obj, QTextBrowser):
            name = obj.objectName()
            if name in usefullPathNames:
                value = settings.value(name)
                obj.setPlainText(value)

def cleanParameters():
    fileName = 'parameters'
    iniFile = 'ini/{}.ini'.format(fileName)
    if os.path.isfile(iniFile):
        os.remove(iniFile)
