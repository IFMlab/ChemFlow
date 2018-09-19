# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/docking_plants.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_DockingPlants(object):
    def setupUi(self, DockingPlants):
        DockingPlants.setObjectName("DockingPlants")
        DockingPlants.resize(521, 337)
        self.spinBox_ants = QtWidgets.QSpinBox(DockingPlants)
        self.spinBox_ants.setGeometry(QtCore.QRect(400, 126, 70, 27))
        self.spinBox_ants.setMinimum(1)
        self.spinBox_ants.setMaximum(1000)
        self.spinBox_ants.setProperty("value", 20)
        self.spinBox_ants.setObjectName("spinBox_ants")
        self.label_8 = QtWidgets.QLabel(DockingPlants)
        self.label_8.setGeometry(QtCore.QRect(291, 102, 91, 20))
        self.label_8.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_8.setObjectName("label_8")
        self.label_9 = QtWidgets.QLabel(DockingPlants)
        self.label_9.setGeometry(QtCore.QRect(261, 130, 121, 20))
        self.label_9.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_9.setObjectName("label_9")
        self.doubleSpinBox_evaporationRate = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_evaporationRate.setGeometry(QtCore.QRect(400, 158, 70, 27))
        self.doubleSpinBox_evaporationRate.setMaximum(1.0)
        self.doubleSpinBox_evaporationRate.setProperty("value", 0.15)
        self.doubleSpinBox_evaporationRate.setObjectName("doubleSpinBox_evaporationRate")
        self.comboBox_scoringFunction = QtWidgets.QComboBox(DockingPlants)
        self.comboBox_scoringFunction.setGeometry(QtCore.QRect(400, 71, 106, 24))
        self.comboBox_scoringFunction.setObjectName("comboBox_scoringFunction")
        self.comboBox_scoringFunction.addItem("")
        self.comboBox_scoringFunction.addItem("")
        self.comboBox_scoringFunction.addItem("")
        self.label_11 = QtWidgets.QLabel(DockingPlants)
        self.label_11.setGeometry(QtCore.QRect(261, 162, 121, 20))
        self.label_11.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_11.setObjectName("label_11")
        self.label_5 = QtWidgets.QLabel(DockingPlants)
        self.label_5.setGeometry(QtCore.QRect(30, 100, 41, 26))
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName("label_5")
        self.line_4 = QtWidgets.QFrame(DockingPlants)
        self.line_4.setGeometry(QtCore.QRect(210, 40, 20, 200))
        self.line_4.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_4.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_4.setObjectName("line_4")
        self.doubleSpinBox_cx = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_cx.setGeometry(QtCore.QRect(80, 70, 131, 27))
        self.doubleSpinBox_cx.setDecimals(3)
        self.doubleSpinBox_cx.setMinimum(-10000.0)
        self.doubleSpinBox_cx.setMaximum(10000.0)
        self.doubleSpinBox_cx.setObjectName("doubleSpinBox_cx")
        self.pushButton_water = QtWidgets.QPushButton(DockingPlants)
        self.pushButton_water.setEnabled(False)
        self.pushButton_water.setGeometry(QtCore.QRect(288, 264, 86, 23))
        self.pushButton_water.setObjectName("pushButton_water")
        self.label_4 = QtWidgets.QLabel(DockingPlants)
        self.label_4.setGeometry(QtCore.QRect(261, 72, 121, 21))
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName("label_4")
        self.doubleSpinBox_cy = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_cy.setGeometry(QtCore.QRect(80, 100, 131, 27))
        self.doubleSpinBox_cy.setDecimals(3)
        self.doubleSpinBox_cy.setMinimum(-10000.0)
        self.doubleSpinBox_cy.setMaximum(10000.0)
        self.doubleSpinBox_cy.setObjectName("doubleSpinBox_cy")
        self.label_12 = QtWidgets.QLabel(DockingPlants)
        self.label_12.setGeometry(QtCore.QRect(221, 194, 161, 20))
        self.label_12.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_12.setObjectName("label_12")
        self.checkBox_water = QtWidgets.QCheckBox(DockingPlants)
        self.checkBox_water.setGeometry(QtCore.QRect(30, 260, 261, 31))
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.checkBox_water.sizePolicy().hasHeightForWidth())
        self.checkBox_water.setSizePolicy(sizePolicy)
        self.checkBox_water.setObjectName("checkBox_water")
        self.label_2 = QtWidgets.QLabel(DockingPlants)
        self.label_2.setGeometry(QtCore.QRect(30, 70, 41, 26))
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")
        self.doubleSpinBox_radius = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_radius.setGeometry(QtCore.QRect(80, 160, 131, 27))
        self.doubleSpinBox_radius.setDecimals(3)
        self.doubleSpinBox_radius.setMinimum(1.0)
        self.doubleSpinBox_radius.setMaximum(10000.0)
        self.doubleSpinBox_radius.setProperty("value", 15.0)
        self.doubleSpinBox_radius.setObjectName("doubleSpinBox_radius")
        self.pushButton_cancel = QtWidgets.QPushButton(DockingPlants)
        self.pushButton_cancel.setGeometry(QtCore.QRect(280, 300, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.doubleSpinBox_cz = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_cz.setGeometry(QtCore.QRect(80, 130, 131, 27))
        self.doubleSpinBox_cz.setDecimals(3)
        self.doubleSpinBox_cz.setMinimum(-10000.0)
        self.doubleSpinBox_cz.setMaximum(10000.0)
        self.doubleSpinBox_cz.setObjectName("doubleSpinBox_cz")
        self.label_6 = QtWidgets.QLabel(DockingPlants)
        self.label_6.setGeometry(QtCore.QRect(30, 130, 41, 26))
        self.label_6.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_6.setObjectName("label_6")
        self.label_3 = QtWidgets.QLabel(DockingPlants)
        self.label_3.setGeometry(QtCore.QRect(40, 40, 121, 20))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_3.setFont(font)
        self.label_3.setAlignment(QtCore.Qt.AlignCenter)
        self.label_3.setObjectName("label_3")
        self.pushButton_ok = QtWidgets.QPushButton(DockingPlants)
        self.pushButton_ok.setGeometry(QtCore.QRect(150, 300, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.label = QtWidgets.QLabel(DockingPlants)
        self.label.setGeometry(QtCore.QRect(10, 10, 161, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.label_10 = QtWidgets.QLabel(DockingPlants)
        self.label_10.setGeometry(QtCore.QRect(20, 160, 51, 26))
        self.label_10.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_10.setObjectName("label_10")
        self.comboBox_searchSpeed = QtWidgets.QComboBox(DockingPlants)
        self.comboBox_searchSpeed.setGeometry(QtCore.QRect(400, 99, 106, 24))
        self.comboBox_searchSpeed.setObjectName("comboBox_searchSpeed")
        self.comboBox_searchSpeed.addItem("")
        self.comboBox_searchSpeed.addItem("")
        self.comboBox_searchSpeed.addItem("")
        self.doubleSpinBox_iterationScaling = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_iterationScaling.setGeometry(QtCore.QRect(400, 190, 70, 27))
        self.doubleSpinBox_iterationScaling.setMaximum(1000.0)
        self.doubleSpinBox_iterationScaling.setSingleStep(0.5)
        self.doubleSpinBox_iterationScaling.setProperty("value", 1.0)
        self.doubleSpinBox_iterationScaling.setObjectName("doubleSpinBox_iterationScaling")
        self.label_7 = QtWidgets.QLabel(DockingPlants)
        self.label_7.setGeometry(QtCore.QRect(320, 40, 101, 20))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_7.setFont(font)
        self.label_7.setAlignment(QtCore.Qt.AlignCenter)
        self.label_7.setObjectName("label_7")
        self.label_13 = QtWidgets.QLabel(DockingPlants)
        self.label_13.setGeometry(QtCore.QRect(280, 225, 101, 20))
        self.label_13.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_13.setObjectName("label_13")
        self.doubleSpinBox_clusterRMSD = QtWidgets.QDoubleSpinBox(DockingPlants)
        self.doubleSpinBox_clusterRMSD.setGeometry(QtCore.QRect(400, 222, 70, 27))
        self.doubleSpinBox_clusterRMSD.setMaximum(1000.0)
        self.doubleSpinBox_clusterRMSD.setSingleStep(0.5)
        self.doubleSpinBox_clusterRMSD.setProperty("value", 2.0)
        self.doubleSpinBox_clusterRMSD.setObjectName("doubleSpinBox_clusterRMSD")

        self.retranslateUi(DockingPlants)
        QtCore.QMetaObject.connectSlotsByName(DockingPlants)

    def retranslateUi(self, DockingPlants):
        _translate = QtCore.QCoreApplication.translate
        DockingPlants.setWindowTitle(_translate("DockingPlants", "Docking - PLANTS"))
        self.spinBox_ants.setToolTip(_translate("DockingPlants", "<html><head/><body><p>Default: 20</p></body></html>"))
        self.label_8.setText(_translate("DockingPlants", "Search speed"))
        self.label_9.setText(_translate("DockingPlants", "Number of ants"))
        self.doubleSpinBox_evaporationRate.setToolTip(_translate("DockingPlants", "<html><head/><body><p>Pheromone evaporation rate. Higher rate usually leads to faster convergency.</p><p>Default: 0,15</p></body></html>"))
        self.comboBox_scoringFunction.setToolTip(_translate("DockingPlants", "<html><head/><body><p>- plp95: Piecewise Linear Potential from Gehlhaar DK et al</p><p>- plp: PLANTS version of the Piecewise Linear Potential</p><p>- chemplp: PLANTS version of the Piecewise Linear Potential implementing GOLD\'s terms</p></body></html>"))
        self.comboBox_scoringFunction.setItemText(0, _translate("DockingPlants", "chemplp"))
        self.comboBox_scoringFunction.setItemText(1, _translate("DockingPlants", "plp"))
        self.comboBox_scoringFunction.setItemText(2, _translate("DockingPlants", "plp95"))
        self.label_11.setText(_translate("DockingPlants", "Evaporation rate"))
        self.label_5.setText(_translate("DockingPlants", "Y"))
        self.pushButton_water.setText(_translate("DockingPlants", "Configure"))
        self.label_4.setText(_translate("DockingPlants", "Scoring Function"))
        self.label_12.setText(_translate("DockingPlants", "Iteration scaling factor"))
        self.checkBox_water.setText(_translate("DockingPlants", "Include structural water molecule"))
        self.label_2.setText(_translate("DockingPlants", "X"))
        self.pushButton_cancel.setText(_translate("DockingPlants", "Cancel"))
        self.label_6.setText(_translate("DockingPlants", "Z"))
        self.label_3.setText(_translate("DockingPlants", "Binding Site"))
        self.pushButton_ok.setText(_translate("DockingPlants", "Ok"))
        self.label.setText(_translate("DockingPlants", "Docking with PLANTS"))
        self.label_10.setText(_translate("DockingPlants", "Radius"))
        self.comboBox_searchSpeed.setToolTip(_translate("DockingPlants", "<html><head/><body><p><span style=\" font-style:italic;\">- speed1</span>: highest reliability but slowest setting</p><p><span style=\" font-style:italic;\">- speed4</span>: 4 times faster than speed1 but modest reliability</p></body></html>"))
        self.comboBox_searchSpeed.setItemText(0, _translate("DockingPlants", "1"))
        self.comboBox_searchSpeed.setItemText(1, _translate("DockingPlants", "2"))
        self.comboBox_searchSpeed.setItemText(2, _translate("DockingPlants", "4"))
        self.doubleSpinBox_iterationScaling.setToolTip(_translate("DockingPlants", "<html><head/><body><p>Multiplies the number of iterations done by the ACO algorithm. Used to tune the tradeoff between computation time and solution quality.</p><p>Default: 1,0</p></body></html>"))
        self.label_7.setText(_translate("DockingPlants", "Parameters"))
        self.label_13.setText(_translate("DockingPlants", "Cluster RMSD"))
        self.doubleSpinBox_clusterRMSD.setToolTip(_translate("DockingPlants", "<html><head/><body><p>Multiplies the number of iterations done by the ACO algorithm. Used to tune the tradeoff between computation time and solution quality.</p><p>Default: 1,0</p></body></html>"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    DockingPlants = QtWidgets.QWidget()
    ui = Ui_DockingPlants()
    ui.setupUi(DockingPlants)
    DockingPlants.show()
    sys.exit(app.exec_())

