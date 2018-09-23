# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/run_slurm.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_RunSlurm(object):
    def setupUi(self, RunSlurm):
        RunSlurm.setObjectName("RunSlurm")
        RunSlurm.resize(455, 157)
        self.label_4 = QtWidgets.QLabel(RunSlurm)
        self.label_4.setGeometry(QtCore.QRect(30, 82, 131, 20))
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName("label_4")
        self.pushButton_ok = QtWidgets.QPushButton(RunSlurm)
        self.pushButton_ok.setGeometry(QtCore.QRect(120, 120, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.label_2 = QtWidgets.QLabel(RunSlurm)
        self.label_2.setGeometry(QtCore.QRect(41, 40, 121, 20))
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")
        self.spinBox_cores = QtWidgets.QSpinBox(RunSlurm)
        self.spinBox_cores.setGeometry(QtCore.QRect(172, 37, 61, 27))
        self.spinBox_cores.setMinimum(1)
        self.spinBox_cores.setMaximum(10000)
        self.spinBox_cores.setObjectName("spinBox_cores")
        self.pushButton_header = QtWidgets.QPushButton(RunSlurm)
        self.pushButton_header.setGeometry(QtCore.QRect(360, 80, 86, 24))
        self.pushButton_header.setObjectName("pushButton_header")
        self.label = QtWidgets.QLabel(RunSlurm)
        self.label.setGeometry(QtCore.QRect(12, 7, 151, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.lineEdit_header = QtWidgets.QLineEdit(RunSlurm)
        self.lineEdit_header.setGeometry(QtCore.QRect(172, 79, 181, 25))
        self.lineEdit_header.setObjectName("lineEdit_header")
        self.pushButton_cancel = QtWidgets.QPushButton(RunSlurm)
        self.pushButton_cancel.setGeometry(QtCore.QRect(240, 120, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")

        self.retranslateUi(RunSlurm)
        QtCore.QMetaObject.connectSlotsByName(RunSlurm)
        RunSlurm.setTabOrder(self.spinBox_cores, self.lineEdit_header)
        RunSlurm.setTabOrder(self.lineEdit_header, self.pushButton_header)
        RunSlurm.setTabOrder(self.pushButton_header, self.pushButton_ok)
        RunSlurm.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, RunSlurm):
        _translate = QtCore.QCoreApplication.translate
        RunSlurm.setWindowTitle(_translate("RunSlurm", "Configure SLURM"))
        self.label_4.setText(_translate("RunSlurm", "Custom header file"))
        self.pushButton_ok.setText(_translate("RunSlurm", "Ok"))
        self.label_2.setText(_translate("RunSlurm", "Number of cores"))
        self.pushButton_header.setText(_translate("RunSlurm", "Browse"))
        self.label.setText(_translate("RunSlurm", "Run with SLURM"))
        self.pushButton_cancel.setText(_translate("RunSlurm", "Cancel"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    RunSlurm = QtWidgets.QWidget()
    ui = Ui_RunSlurm()
    ui.setupUi(RunSlurm)
    RunSlurm.show()
    sys.exit(app.exec_())

