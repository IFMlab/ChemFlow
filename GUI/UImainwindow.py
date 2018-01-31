# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/Dropbox/work/ChemFlow/GUI/mainwindow.ui'
#
# Created by: PyQt5 UI code generator 5.10
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(592, 601)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap("logo.png"), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        MainWindow.setWindowIcon(icon)
        self.centralWidget = QtWidgets.QWidget(MainWindow)
        self.centralWidget.setObjectName("centralWidget")
        self.label_logo_2 = QtWidgets.QLabel(self.centralWidget)
        self.label_logo_2.setGeometry(QtCore.QRect(240, 10, 231, 51))
        font = QtGui.QFont()
        font.setPointSize(28)
        font.setBold(True)
        font.setItalic(True)
        font.setWeight(75)
        self.label_logo_2.setFont(font)
        self.label_logo_2.setObjectName("label_logo_2")
        self.label_logo = QtWidgets.QLabel(self.centralWidget)
        self.label_logo.setGeometry(QtCore.QRect(160, 10, 61, 51))
        self.label_logo.setText("")
        self.label_logo.setPixmap(QtGui.QPixmap("logo.png"))
        self.label_logo.setAlignment(QtCore.Qt.AlignCenter)
        self.label_logo.setObjectName("label_logo")
        self.tabWidget = QtWidgets.QTabWidget(self.centralWidget)
        self.tabWidget.setGeometry(QtCore.QRect(0, 70, 591, 531))
        self.tabWidget.setObjectName("tabWidget")
        self.tab_experiment = QtWidgets.QWidget()
        self.tab_experiment.setObjectName("tab_experiment")
        self.label_protocol = QtWidgets.QLabel(self.tab_experiment)
        self.label_protocol.setGeometry(QtCore.QRect(20, 10, 81, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_protocol.setFont(font)
        self.label_protocol.setObjectName("label_protocol")
        self.textBrowser_lig = QtWidgets.QTextBrowser(self.tab_experiment)
        self.textBrowser_lig.setGeometry(QtCore.QRect(100, 140, 301, 21))
        font = QtGui.QFont()
        font.setPointSize(8)
        self.textBrowser_lig.setFont(font)
        self.textBrowser_lig.setObjectName("textBrowser_lig")
        self.comboBox_dockingSoftware = QtWidgets.QComboBox(self.tab_experiment)
        self.comboBox_dockingSoftware.setGeometry(QtCore.QRect(100, 240, 221, 24))
        self.comboBox_dockingSoftware.setObjectName("comboBox_dockingSoftware")
        self.comboBox_dockingSoftware.addItem("")
        self.comboBox_dockingSoftware.addItem("")
        self.checkBox_lig = QtWidgets.QCheckBox(self.tab_experiment)
        self.checkBox_lig.setGeometry(QtCore.QRect(410, 140, 71, 22))
        self.checkBox_lig.setObjectName("checkBox_lig")
        self.label_inputFiles = QtWidgets.QLabel(self.tab_experiment)
        self.label_inputFiles.setGeometry(QtCore.QRect(20, 90, 71, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_inputFiles.setFont(font)
        self.label_inputFiles.setObjectName("label_inputFiles")
        self.label_rescoring = QtWidgets.QLabel(self.tab_experiment)
        self.label_rescoring.setGeometry(QtCore.QRect(20, 359, 81, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_rescoring.setFont(font)
        self.label_rescoring.setObjectName("label_rescoring")
        self.line_7 = QtWidgets.QFrame(self.tab_experiment)
        self.line_7.setGeometry(QtCore.QRect(190, 309, 381, 20))
        self.line_7.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_7.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_7.setObjectName("line_7")
        self.label_forceFieldMin = QtWidgets.QLabel(self.tab_experiment)
        self.label_forceFieldMin.setGeometry(QtCore.QRect(20, 309, 171, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_forceFieldMin.setFont(font)
        self.label_forceFieldMin.setObjectName("label_forceFieldMin")
        self.line_5 = QtWidgets.QFrame(self.tab_experiment)
        self.line_5.setGeometry(QtCore.QRect(100, 220, 471, 20))
        self.line_5.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_5.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_5.setObjectName("line_5")
        self.pushButton_minConfigure = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_minConfigure.setGeometry(QtCore.QRect(241, 329, 80, 24))
        self.pushButton_minConfigure.setObjectName("pushButton_minConfigure")
        self.pushButton_readConfig = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_readConfig.setGeometry(QtCore.QRect(221, 458, 121, 29))
        self.pushButton_readConfig.setObjectName("pushButton_readConfig")
        self.line_9 = QtWidgets.QFrame(self.tab_experiment)
        self.line_9.setGeometry(QtCore.QRect(100, 359, 471, 20))
        self.line_9.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_9.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_9.setObjectName("line_9")
        self.line_8 = QtWidgets.QFrame(self.tab_experiment)
        self.line_8.setGeometry(QtCore.QRect(10, 329, 20, 31))
        self.line_8.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_8.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_8.setObjectName("line_8")
        self.line_4 = QtWidgets.QFrame(self.tab_experiment)
        self.line_4.setGeometry(QtCore.QRect(10, 190, 21, 31))
        self.line_4.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_4.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_4.setObjectName("line_4")
        self.pushButton_runConfigure = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_runConfigure.setGeometry(QtCore.QRect(330, 60, 86, 24))
        self.pushButton_runConfigure.setObjectName("pushButton_runConfigure")
        self.label_output = QtWidgets.QLabel(self.tab_experiment)
        self.label_output.setGeometry(QtCore.QRect(40, 190, 41, 20))
        self.label_output.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_output.setObjectName("label_output")
        self.pushButton_writeConfig = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_writeConfig.setGeometry(QtCore.QRect(103, 458, 121, 29))
        self.pushButton_writeConfig.setObjectName("pushButton_writeConfig")
        self.label_lig = QtWidgets.QLabel(self.tab_experiment)
        self.label_lig.setGeometry(QtCore.QRect(20, 140, 61, 20))
        self.label_lig.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_lig.setObjectName("label_lig")
        self.line_12 = QtWidgets.QFrame(self.tab_experiment)
        self.line_12.setGeometry(QtCore.QRect(99, 10, 471, 20))
        self.line_12.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_12.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_12.setObjectName("line_12")
        self.checkBox_min = QtWidgets.QCheckBox(self.tab_experiment)
        self.checkBox_min.setGeometry(QtCore.QRect(30, 330, 211, 22))
        self.checkBox_min.setLayoutDirection(QtCore.Qt.LeftToRight)
        self.checkBox_min.setObjectName("checkBox_min")
        self.label_dockingKeep_2 = QtWidgets.QLabel(self.tab_experiment)
        self.label_dockingKeep_2.setGeometry(QtCore.QRect(170, 269, 111, 31))
        self.label_dockingKeep_2.setObjectName("label_dockingKeep_2")
        self.line_6 = QtWidgets.QFrame(self.tab_experiment)
        self.line_6.setGeometry(QtCore.QRect(10, 239, 20, 71))
        self.line_6.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_6.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_6.setObjectName("line_6")
        self.comboBox_protocolPreset = QtWidgets.QComboBox(self.tab_experiment)
        self.comboBox_protocolPreset.setGeometry(QtCore.QRect(100, 30, 221, 25))
        self.comboBox_protocolPreset.setObjectName("comboBox_protocolPreset")
        self.comboBox_protocolPreset.addItem("")
        self.comboBox_protocolPreset.addItem("")
        self.comboBox_protocolPreset.addItem("")
        self.label_outputDir = QtWidgets.QLabel(self.tab_experiment)
        self.label_outputDir.setGeometry(QtCore.QRect(20, 170, 121, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_outputDir.setFont(font)
        self.label_outputDir.setObjectName("label_outputDir")
        self.line_10 = QtWidgets.QFrame(self.tab_experiment)
        self.line_10.setGeometry(QtCore.QRect(10, 379, 20, 68))
        self.line_10.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_10.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_10.setObjectName("line_10")
        self.label_protocolPreset = QtWidgets.QLabel(self.tab_experiment)
        self.label_protocolPreset.setGeometry(QtCore.QRect(30, 31, 51, 20))
        self.label_protocolPreset.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_protocolPreset.setObjectName("label_protocolPreset")
        self.textBrowser_rec = QtWidgets.QTextBrowser(self.tab_experiment)
        self.textBrowser_rec.setGeometry(QtCore.QRect(100, 110, 371, 21))
        font = QtGui.QFont()
        font.setPointSize(8)
        self.textBrowser_rec.setFont(font)
        self.textBrowser_rec.setObjectName("textBrowser_rec")
        self.label_rescoringKeep_2 = QtWidgets.QLabel(self.tab_experiment)
        self.label_rescoringKeep_2.setGeometry(QtCore.QRect(170, 408, 121, 31))
        self.label_rescoringKeep_2.setObjectName("label_rescoringKeep_2")
        self.comboBox_runOptions = QtWidgets.QComboBox(self.tab_experiment)
        self.comboBox_runOptions.setGeometry(QtCore.QRect(100, 60, 221, 24))
        self.comboBox_runOptions.setObjectName("comboBox_runOptions")
        self.comboBox_runOptions.addItem("")
        self.comboBox_runOptions.addItem("")
        self.comboBox_runOptions.addItem("")
        self.pushButton_dockingConfigure = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_dockingConfigure.setEnabled(True)
        self.pushButton_dockingConfigure.setGeometry(QtCore.QRect(330, 240, 86, 24))
        self.pushButton_dockingConfigure.setObjectName("pushButton_dockingConfigure")
        self.line_3 = QtWidgets.QFrame(self.tab_experiment)
        self.line_3.setGeometry(QtCore.QRect(140, 170, 431, 20))
        self.line_3.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_3.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_3.setObjectName("line_3")
        self.pushButton_lig = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_lig.setGeometry(QtCore.QRect(480, 140, 86, 21))
        self.pushButton_lig.setObjectName("pushButton_lig")
        self.label_dockingSoftware = QtWidgets.QLabel(self.tab_experiment)
        self.label_dockingSoftware.setGeometry(QtCore.QRect(30, 241, 61, 20))
        self.label_dockingSoftware.setObjectName("label_dockingSoftware")
        self.comboBox_rescoringSoftware = QtWidgets.QComboBox(self.tab_experiment)
        self.comboBox_rescoringSoftware.setGeometry(QtCore.QRect(100, 379, 221, 24))
        self.comboBox_rescoringSoftware.setObjectName("comboBox_rescoringSoftware")
        self.comboBox_rescoringSoftware.addItem("")
        self.comboBox_rescoringSoftware.addItem("")
        self.comboBox_rescoringSoftware.addItem("")
        self.label_dockingKeep = QtWidgets.QLabel(self.tab_experiment)
        self.label_dockingKeep.setGeometry(QtCore.QRect(40, 268, 41, 31))
        self.label_dockingKeep.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_dockingKeep.setObjectName("label_dockingKeep")
        self.pushButton_run = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_run.setGeometry(QtCore.QRect(20, 458, 86, 29))
        self.pushButton_run.setObjectName("pushButton_run")
        self.label_rescoringSoftware = QtWidgets.QLabel(self.tab_experiment)
        self.label_rescoringSoftware.setGeometry(QtCore.QRect(20, 380, 61, 20))
        self.label_rescoringSoftware.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_rescoringSoftware.setObjectName("label_rescoringSoftware")
        self.spinBox_rescoring = QtWidgets.QSpinBox(self.tab_experiment)
        self.spinBox_rescoring.setGeometry(QtCore.QRect(100, 408, 61, 31))
        self.spinBox_rescoring.setMinimum(1)
        self.spinBox_rescoring.setMaximum(1000)
        self.spinBox_rescoring.setObjectName("spinBox_rescoring")
        self.pushButton_cancel = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_cancel.setGeometry(QtCore.QRect(480, 458, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.label_docking = QtWidgets.QLabel(self.tab_experiment)
        self.label_docking.setGeometry(QtCore.QRect(20, 220, 81, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_docking.setFont(font)
        self.label_docking.setObjectName("label_docking")
        self.line_2 = QtWidgets.QFrame(self.tab_experiment)
        self.line_2.setGeometry(QtCore.QRect(10, 110, 20, 61))
        self.line_2.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_2.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_2.setObjectName("line_2")
        self.line_11 = QtWidgets.QFrame(self.tab_experiment)
        self.line_11.setGeometry(QtCore.QRect(20, 438, 551, 20))
        self.line_11.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_11.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_11.setObjectName("line_11")
        self.spinBox_docking = QtWidgets.QSpinBox(self.tab_experiment)
        self.spinBox_docking.setGeometry(QtCore.QRect(100, 269, 61, 31))
        self.spinBox_docking.setMinimum(1)
        self.spinBox_docking.setMaximum(1000)
        self.spinBox_docking.setObjectName("spinBox_docking")
        self.line_13 = QtWidgets.QFrame(self.tab_experiment)
        self.line_13.setGeometry(QtCore.QRect(10, 30, 20, 61))
        self.line_13.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_13.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_13.setObjectName("line_13")
        self.pushButton_output = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_output.setGeometry(QtCore.QRect(480, 190, 86, 21))
        self.pushButton_output.setObjectName("pushButton_output")
        self.line = QtWidgets.QFrame(self.tab_experiment)
        self.line.setGeometry(QtCore.QRect(100, 90, 471, 20))
        self.line.setFrameShape(QtWidgets.QFrame.HLine)
        self.line.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line.setObjectName("line")
        self.label_rec = QtWidgets.QLabel(self.tab_experiment)
        self.label_rec.setGeometry(QtCore.QRect(20, 110, 61, 20))
        self.label_rec.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_rec.setObjectName("label_rec")
        self.label_runOptions = QtWidgets.QLabel(self.tab_experiment)
        self.label_runOptions.setGeometry(QtCore.QRect(40, 61, 41, 20))
        self.label_runOptions.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_runOptions.setObjectName("label_runOptions")
        self.pushButton_rec = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_rec.setGeometry(QtCore.QRect(480, 110, 86, 21))
        self.pushButton_rec.setObjectName("pushButton_rec")
        self.textBrowser_output = QtWidgets.QTextBrowser(self.tab_experiment)
        self.textBrowser_output.setGeometry(QtCore.QRect(100, 190, 371, 21))
        font = QtGui.QFont()
        font.setPointSize(8)
        self.textBrowser_output.setFont(font)
        self.textBrowser_output.setObjectName("textBrowser_output")
        self.pushButton_rescoringConfigure = QtWidgets.QPushButton(self.tab_experiment)
        self.pushButton_rescoringConfigure.setGeometry(QtCore.QRect(330, 379, 86, 24))
        self.pushButton_rescoringConfigure.setObjectName("pushButton_rescoringConfigure")
        self.label_rescoringKeep = QtWidgets.QLabel(self.tab_experiment)
        self.label_rescoringKeep.setGeometry(QtCore.QRect(40, 407, 41, 31))
        self.label_rescoringKeep.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_rescoringKeep.setObjectName("label_rescoringKeep")
        self.tabWidget.addTab(self.tab_experiment, "")
        self.tab_report = QtWidgets.QWidget()
        self.tab_report.setObjectName("tab_report")
        self.label_analyse = QtWidgets.QLabel(self.tab_report)
        self.label_analyse.setGeometry(QtCore.QRect(10, 12, 61, 20))
        self.label_analyse.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_analyse.setObjectName("label_analyse")
        self.pushButton_configureExp = QtWidgets.QPushButton(self.tab_report)
        self.pushButton_configureExp.setEnabled(False)
        self.pushButton_configureExp.setGeometry(QtCore.QRect(334, 10, 86, 24))
        self.pushButton_configureExp.setObjectName("pushButton_configureExp")
        self.comboBox_analyse = QtWidgets.QComboBox(self.tab_report)
        self.comboBox_analyse.setGeometry(QtCore.QRect(90, 10, 231, 24))
        self.comboBox_analyse.setObjectName("comboBox_analyse")
        self.comboBox_analyse.addItem("")
        self.comboBox_analyse.addItem("")
        self.label_reportPreset = QtWidgets.QLabel(self.tab_report)
        self.label_reportPreset.setGeometry(QtCore.QRect(20, 41, 51, 20))
        self.label_reportPreset.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_reportPreset.setObjectName("label_reportPreset")
        self.comboBox_reportPreset = QtWidgets.QComboBox(self.tab_report)
        self.comboBox_reportPreset.setGeometry(QtCore.QRect(90, 40, 330, 25))
        self.comboBox_reportPreset.setObjectName("comboBox_reportPreset")
        self.comboBox_reportPreset.addItem("")
        self.comboBox_reportPreset.addItem("")
        self.comboBox_reportPreset.addItem("")
        self.tabWidget.addTab(self.tab_report, "")
        MainWindow.setCentralWidget(self.centralWidget)

        self.retranslateUi(MainWindow)
        self.tabWidget.setCurrentIndex(0)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "ChemFlow"))
        self.label_logo_2.setText(_translate("MainWindow", "ChemFlow"))
        self.label_protocol.setText(_translate("MainWindow", "Protocol"))
        self.comboBox_dockingSoftware.setItemText(0, _translate("MainWindow", "AutoDock Vina"))
        self.comboBox_dockingSoftware.setItemText(1, _translate("MainWindow", "PLANTS"))
        self.checkBox_lig.setText(_translate("MainWindow", "Folder"))
        self.label_inputFiles.setText(_translate("MainWindow", "Input files"))
        self.label_rescoring.setText(_translate("MainWindow", "Rescoring"))
        self.label_forceFieldMin.setText(_translate("MainWindow", "Force field minimisation"))
        self.pushButton_minConfigure.setText(_translate("MainWindow", "Configure"))
        self.pushButton_readConfig.setText(_translate("MainWindow", "Read config file"))
        self.pushButton_runConfigure.setText(_translate("MainWindow", "Configure"))
        self.label_output.setText(_translate("MainWindow", "Path"))
        self.pushButton_writeConfig.setText(_translate("MainWindow", "Write config file"))
        self.label_lig.setText(_translate("MainWindow", "Ligand(s)"))
        self.checkBox_min.setText(_translate("MainWindow", "Minimize the complex "))
        self.label_dockingKeep_2.setText(_translate("MainWindow", "pose(s) per ligand"))
        self.comboBox_protocolPreset.setItemText(0, _translate("MainWindow", "Docking"))
        self.comboBox_protocolPreset.setItemText(1, _translate("MainWindow", "Docking + Rescoring"))
        self.comboBox_protocolPreset.setItemText(2, _translate("MainWindow", "Rescoring"))
        self.label_outputDir.setText(_translate("MainWindow", "Output directory"))
        self.label_protocolPreset.setText(_translate("MainWindow", "Preset"))
        self.label_rescoringKeep_2.setText(_translate("MainWindow", "pose(s) per ligand"))
        self.comboBox_runOptions.setItemText(0, _translate("MainWindow", "Locally"))
        self.comboBox_runOptions.setItemText(1, _translate("MainWindow", "PBS"))
        self.comboBox_runOptions.setItemText(2, _translate("MainWindow", "Slurm"))
        self.pushButton_dockingConfigure.setText(_translate("MainWindow", "Configure"))
        self.pushButton_lig.setText(_translate("MainWindow", "Browse"))
        self.label_dockingSoftware.setText(_translate("MainWindow", "Software"))
        self.comboBox_rescoringSoftware.setItemText(0, _translate("MainWindow", "AutoDock Vina"))
        self.comboBox_rescoringSoftware.setItemText(1, _translate("MainWindow", "MM/PBSA"))
        self.comboBox_rescoringSoftware.setItemText(2, _translate("MainWindow", "PLANTS"))
        self.label_dockingKeep.setText(_translate("MainWindow", "Keep"))
        self.pushButton_run.setText(_translate("MainWindow", "Run"))
        self.label_rescoringSoftware.setText(_translate("MainWindow", "Software"))
        self.pushButton_cancel.setText(_translate("MainWindow", "Cancel"))
        self.label_docking.setText(_translate("MainWindow", "Docking"))
        self.pushButton_output.setText(_translate("MainWindow", "Browse"))
        self.label_rec.setText(_translate("MainWindow", "Receptor"))
        self.label_runOptions.setText(_translate("MainWindow", "Run"))
        self.pushButton_rec.setText(_translate("MainWindow", "Browse"))
        self.pushButton_rescoringConfigure.setText(_translate("MainWindow", "Configure"))
        self.label_rescoringKeep.setText(_translate("MainWindow", "Keep"))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab_experiment), _translate("MainWindow", "Experiment"))
        self.label_analyse.setText(_translate("MainWindow", "Analyse"))
        self.pushButton_configureExp.setText(_translate("MainWindow", "Configure"))
        self.comboBox_analyse.setItemText(0, _translate("MainWindow", "Current experiment"))
        self.comboBox_analyse.setItemText(1, _translate("MainWindow", "Another experiment"))
        self.label_reportPreset.setText(_translate("MainWindow", "Preset"))
        self.comboBox_reportPreset.setItemText(0, _translate("MainWindow", "Docking"))
        self.comboBox_reportPreset.setItemText(1, _translate("MainWindow", "Docking benchmark: RMSD"))
        self.comboBox_reportPreset.setItemText(2, _translate("MainWindow", "Docking + Rescoring benchmark: actives and decoys"))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab_report), _translate("MainWindow", "Report"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    MainWindow = QtWidgets.QMainWindow()
    ui = Ui_MainWindow()
    ui.setupUi(MainWindow)
    MainWindow.show()
    sys.exit(app.exec_())

