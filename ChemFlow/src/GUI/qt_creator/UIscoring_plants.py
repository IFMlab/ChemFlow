# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/scoring_plants.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_ScoringPlants(object):
    def setupUi(self, ScoringPlants):
        ScoringPlants.setObjectName("ScoringPlants")
        ScoringPlants.resize(521, 279)
        self.comboBox_scoringFunction = QtWidgets.QComboBox(ScoringPlants)
        self.comboBox_scoringFunction.setGeometry(QtCore.QRect(400, 68, 106, 26))
        self.comboBox_scoringFunction.setObjectName("comboBox_scoringFunction")
        self.comboBox_scoringFunction.addItem("")
        self.comboBox_scoringFunction.addItem("")
        self.comboBox_scoringFunction.addItem("")
        self.label_10 = QtWidgets.QLabel(ScoringPlants)
        self.label_10.setGeometry(QtCore.QRect(20, 160, 51, 26))
        self.label_10.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_10.setObjectName("label_10")
        self.pushButton_ok = QtWidgets.QPushButton(ScoringPlants)
        self.pushButton_ok.setGeometry(QtCore.QRect(150, 240, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.label_2 = QtWidgets.QLabel(ScoringPlants)
        self.label_2.setGeometry(QtCore.QRect(30, 70, 41, 26))
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")
        self.checkBox_water = QtWidgets.QCheckBox(ScoringPlants)
        self.checkBox_water.setGeometry(QtCore.QRect(30, 200, 261, 31))
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.checkBox_water.sizePolicy().hasHeightForWidth())
        self.checkBox_water.setSizePolicy(sizePolicy)
        self.checkBox_water.setObjectName("checkBox_water")
        self.label = QtWidgets.QLabel(ScoringPlants)
        self.label.setGeometry(QtCore.QRect(10, 10, 191, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.doubleSpinBox_cx = QtWidgets.QDoubleSpinBox(ScoringPlants)
        self.doubleSpinBox_cx.setGeometry(QtCore.QRect(80, 70, 131, 27))
        self.doubleSpinBox_cx.setDecimals(3)
        self.doubleSpinBox_cx.setMinimum(-10000.0)
        self.doubleSpinBox_cx.setMaximum(10000.0)
        self.doubleSpinBox_cx.setObjectName("doubleSpinBox_cx")
        self.pushButton_water = QtWidgets.QPushButton(ScoringPlants)
        self.pushButton_water.setEnabled(False)
        self.pushButton_water.setGeometry(QtCore.QRect(288, 204, 86, 23))
        self.pushButton_water.setObjectName("pushButton_water")
        self.pushButton_cancel = QtWidgets.QPushButton(ScoringPlants)
        self.pushButton_cancel.setGeometry(QtCore.QRect(280, 240, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.label_4 = QtWidgets.QLabel(ScoringPlants)
        self.label_4.setGeometry(QtCore.QRect(261, 72, 121, 21))
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName("label_4")
        self.doubleSpinBox_cy = QtWidgets.QDoubleSpinBox(ScoringPlants)
        self.doubleSpinBox_cy.setGeometry(QtCore.QRect(80, 100, 131, 27))
        self.doubleSpinBox_cy.setDecimals(3)
        self.doubleSpinBox_cy.setMinimum(-10000.0)
        self.doubleSpinBox_cy.setMaximum(10000.0)
        self.doubleSpinBox_cy.setObjectName("doubleSpinBox_cy")
        self.label_3 = QtWidgets.QLabel(ScoringPlants)
        self.label_3.setGeometry(QtCore.QRect(40, 40, 121, 20))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_3.setFont(font)
        self.label_3.setAlignment(QtCore.Qt.AlignCenter)
        self.label_3.setObjectName("label_3")
        self.doubleSpinBox_cz = QtWidgets.QDoubleSpinBox(ScoringPlants)
        self.doubleSpinBox_cz.setGeometry(QtCore.QRect(80, 130, 131, 27))
        self.doubleSpinBox_cz.setDecimals(3)
        self.doubleSpinBox_cz.setMinimum(-10000.0)
        self.doubleSpinBox_cz.setMaximum(10000.0)
        self.doubleSpinBox_cz.setObjectName("doubleSpinBox_cz")
        self.label_6 = QtWidgets.QLabel(ScoringPlants)
        self.label_6.setGeometry(QtCore.QRect(30, 130, 41, 26))
        self.label_6.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_6.setObjectName("label_6")
        self.label_5 = QtWidgets.QLabel(ScoringPlants)
        self.label_5.setGeometry(QtCore.QRect(30, 100, 41, 26))
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName("label_5")
        self.line_4 = QtWidgets.QFrame(ScoringPlants)
        self.line_4.setGeometry(QtCore.QRect(230, 40, 20, 151))
        self.line_4.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_4.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_4.setObjectName("line_4")
        self.doubleSpinBox_radius = QtWidgets.QDoubleSpinBox(ScoringPlants)
        self.doubleSpinBox_radius.setGeometry(QtCore.QRect(80, 160, 131, 27))
        self.doubleSpinBox_radius.setDecimals(3)
        self.doubleSpinBox_radius.setMinimum(1.0)
        self.doubleSpinBox_radius.setMaximum(10000.0)
        self.doubleSpinBox_radius.setProperty("value", 15.0)
        self.doubleSpinBox_radius.setObjectName("doubleSpinBox_radius")
        self.label_7 = QtWidgets.QLabel(ScoringPlants)
        self.label_7.setGeometry(QtCore.QRect(320, 40, 101, 20))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_7.setFont(font)
        self.label_7.setAlignment(QtCore.Qt.AlignCenter)
        self.label_7.setObjectName("label_7")

        self.retranslateUi(ScoringPlants)
        QtCore.QMetaObject.connectSlotsByName(ScoringPlants)
        ScoringPlants.setTabOrder(self.doubleSpinBox_cx, self.doubleSpinBox_cy)
        ScoringPlants.setTabOrder(self.doubleSpinBox_cy, self.doubleSpinBox_cz)
        ScoringPlants.setTabOrder(self.doubleSpinBox_cz, self.doubleSpinBox_radius)
        ScoringPlants.setTabOrder(self.doubleSpinBox_radius, self.comboBox_scoringFunction)
        ScoringPlants.setTabOrder(self.comboBox_scoringFunction, self.checkBox_water)
        ScoringPlants.setTabOrder(self.checkBox_water, self.pushButton_water)
        ScoringPlants.setTabOrder(self.pushButton_water, self.pushButton_ok)
        ScoringPlants.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, ScoringPlants):
        _translate = QtCore.QCoreApplication.translate
        ScoringPlants.setWindowTitle(_translate("ScoringPlants", "Rescoring - PLANTS"))
        self.comboBox_scoringFunction.setToolTip(_translate("ScoringPlants", "<html><head/><body><p>- plp95: Piecewise Linear Potential from Gehlhaar DK et al</p><p>- plp: PLANTS version of the Piecewise Linear Potential</p><p>- chemplp: PLANTS version of the Piecewise Linear Potential implementing GOLD\'s terms</p></body></html>"))
        self.comboBox_scoringFunction.setItemText(0, _translate("ScoringPlants", "chemplp"))
        self.comboBox_scoringFunction.setItemText(1, _translate("ScoringPlants", "plp"))
        self.comboBox_scoringFunction.setItemText(2, _translate("ScoringPlants", "plp95"))
        self.label_10.setText(_translate("ScoringPlants", "Radius"))
        self.pushButton_ok.setText(_translate("ScoringPlants", "Ok"))
        self.label_2.setText(_translate("ScoringPlants", "X"))
        self.checkBox_water.setText(_translate("ScoringPlants", "Include structural water molecule"))
        self.label.setText(_translate("ScoringPlants", "Rescoring with PLANTS"))
        self.pushButton_water.setText(_translate("ScoringPlants", "Configure"))
        self.pushButton_cancel.setText(_translate("ScoringPlants", "Cancel"))
        self.label_4.setText(_translate("ScoringPlants", "Scoring Function"))
        self.label_3.setText(_translate("ScoringPlants", "Binding Site"))
        self.label_6.setText(_translate("ScoringPlants", "Z"))
        self.label_5.setText(_translate("ScoringPlants", "Y"))
        self.label_7.setText(_translate("ScoringPlants", "Parameters"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    ScoringPlants = QtWidgets.QWidget()
    ui = Ui_ScoringPlants()
    ui.setupUi(ScoringPlants)
    ScoringPlants.show()
    sys.exit(app.exec_())

