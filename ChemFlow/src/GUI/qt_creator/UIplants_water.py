# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/Dropbox/work/ChemFlow/ChemFlow/src/GUI/qt_creator/plants_water.ui'
#
# Created by: PyQt5 UI code generator 5.10
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_PlantsWater(object):
    def setupUi(self, PlantsWater):
        PlantsWater.setObjectName("PlantsWater")
        PlantsWater.resize(452, 241)
        self.label = QtWidgets.QLabel(PlantsWater)
        self.label.setGeometry(QtCore.QRect(10, 5, 151, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.label_6 = QtWidgets.QLabel(PlantsWater)
        self.label_6.setGeometry(QtCore.QRect(100, 115, 36, 26))
        self.label_6.setObjectName("label_6")
        self.pushButton_water = QtWidgets.QPushButton(PlantsWater)
        self.pushButton_water.setGeometry(QtCore.QRect(350, 28, 86, 21))
        self.pushButton_water.setObjectName("pushButton_water")
        self.label_5 = QtWidgets.QLabel(PlantsWater)
        self.label_5.setGeometry(QtCore.QRect(100, 85, 36, 26))
        self.label_5.setObjectName("label_5")
        self.label_10 = QtWidgets.QLabel(PlantsWater)
        self.label_10.setGeometry(QtCore.QRect(47, 145, 61, 26))
        self.label_10.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_10.setObjectName("label_10")
        self.pushButton_ok = QtWidgets.QPushButton(PlantsWater)
        self.pushButton_ok.setGeometry(QtCore.QRect(120, 195, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.label_rec = QtWidgets.QLabel(PlantsWater)
        self.label_rec.setGeometry(QtCore.QRect(20, 28, 111, 20))
        self.label_rec.setObjectName("label_rec")
        self.pushButton_cancel = QtWidgets.QPushButton(PlantsWater)
        self.pushButton_cancel.setGeometry(QtCore.QRect(250, 195, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.doubleSpinBox_cy = QtWidgets.QDoubleSpinBox(PlantsWater)
        self.doubleSpinBox_cy.setGeometry(QtCore.QRect(134, 85, 131, 27))
        self.doubleSpinBox_cy.setDecimals(3)
        self.doubleSpinBox_cy.setMinimum(-10000.0)
        self.doubleSpinBox_cy.setMaximum(10000.0)
        self.doubleSpinBox_cy.setObjectName("doubleSpinBox_cy")
        self.label_2 = QtWidgets.QLabel(PlantsWater)
        self.label_2.setGeometry(QtCore.QRect(100, 55, 36, 26))
        self.label_2.setObjectName("label_2")
        self.doubleSpinBox_cx = QtWidgets.QDoubleSpinBox(PlantsWater)
        self.doubleSpinBox_cx.setGeometry(QtCore.QRect(134, 55, 131, 27))
        self.doubleSpinBox_cx.setDecimals(3)
        self.doubleSpinBox_cx.setMinimum(-10000.0)
        self.doubleSpinBox_cx.setMaximum(10000.0)
        self.doubleSpinBox_cx.setObjectName("doubleSpinBox_cx")
        self.doubleSpinBox_radius = QtWidgets.QDoubleSpinBox(PlantsWater)
        self.doubleSpinBox_radius.setGeometry(QtCore.QRect(134, 145, 131, 27))
        self.doubleSpinBox_radius.setDecimals(3)
        self.doubleSpinBox_radius.setMinimum(0.0)
        self.doubleSpinBox_radius.setMaximum(10000.0)
        self.doubleSpinBox_radius.setObjectName("doubleSpinBox_radius")
        self.doubleSpinBox_cz = QtWidgets.QDoubleSpinBox(PlantsWater)
        self.doubleSpinBox_cz.setGeometry(QtCore.QRect(134, 115, 131, 27))
        self.doubleSpinBox_cz.setDecimals(3)
        self.doubleSpinBox_cz.setMinimum(-10000.0)
        self.doubleSpinBox_cz.setMaximum(10000.0)
        self.doubleSpinBox_cz.setObjectName("doubleSpinBox_cz")
        self.lineEdit_water = QtWidgets.QLineEdit(PlantsWater)
        self.lineEdit_water.setGeometry(QtCore.QRect(134, 28, 212, 20))
        self.lineEdit_water.setObjectName("lineEdit_water")

        self.retranslateUi(PlantsWater)
        QtCore.QMetaObject.connectSlotsByName(PlantsWater)

    def retranslateUi(self, PlantsWater):
        _translate = QtCore.QCoreApplication.translate
        PlantsWater.setWindowTitle(_translate("PlantsWater", "PLANTS - water"))
        self.label.setText(_translate("PlantsWater", "PLANTS with water"))
        self.label_6.setText(_translate("PlantsWater", "Z"))
        self.pushButton_water.setToolTip(_translate("PlantsWater", "<html><head/><body><p>MOL2 file containing a single water molecule.</p><p>Position and orientation is arbitrary.</p></body></html>"))
        self.pushButton_water.setText(_translate("PlantsWater", "Browse"))
        self.label_5.setText(_translate("PlantsWater", "Y"))
        self.label_10.setText(_translate("PlantsWater", "Radius"))
        self.pushButton_ok.setText(_translate("PlantsWater", "Ok"))
        self.label_rec.setText(_translate("PlantsWater", "Water molecule"))
        self.pushButton_cancel.setText(_translate("PlantsWater", "Cancel"))
        self.doubleSpinBox_cy.setToolTip(_translate("PlantsWater", "<html><head/><body><p>Sphere inside which the water molecule is allowed to move. If the water molecule is displaced by a ligand and moved outside the sphere, the water molecule has no score contribution.</p></body></html>"))
        self.label_2.setText(_translate("PlantsWater", "X"))
        self.doubleSpinBox_cx.setToolTip(_translate("PlantsWater", "<html><head/><body><p>Sphere inside which the water molecule is allowed to move. If the water molecule is displaced by a ligand and moved outside the sphere, the water molecule has no score contribution.</p></body></html>"))
        self.doubleSpinBox_radius.setToolTip(_translate("PlantsWater", "<html><head/><body><p>Sphere inside which the water molecule is allowed to move. If the water molecule is displaced by a ligand and moved outside the sphere, the water molecule has no score contribution.</p></body></html>"))
        self.doubleSpinBox_cz.setToolTip(_translate("PlantsWater", "<html><head/><body><p>Sphere inside which the water molecule is allowed to move. If the water molecule is displaced by a ligand and moved outside the sphere, the water molecule has no score contribution.</p></body></html>"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    PlantsWater = QtWidgets.QWidget()
    ui = Ui_PlantsWater()
    ui.setupUi(PlantsWater)
    PlantsWater.show()
    sys.exit(app.exec_())
