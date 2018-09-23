# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/run_pbs.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_RunPbs(object):
    def setupUi(self, RunPbs):
        RunPbs.setObjectName("RunPbs")
        RunPbs.resize(455, 157)
        self.label_2 = QtWidgets.QLabel(RunPbs)
        self.label_2.setGeometry(QtCore.QRect(41, 40, 121, 20))
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")
        self.pushButton_ok = QtWidgets.QPushButton(RunPbs)
        self.pushButton_ok.setGeometry(QtCore.QRect(120, 120, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.spinBox_cores = QtWidgets.QSpinBox(RunPbs)
        self.spinBox_cores.setGeometry(QtCore.QRect(172, 37, 61, 27))
        self.spinBox_cores.setMinimum(1)
        self.spinBox_cores.setMaximum(10000)
        self.spinBox_cores.setObjectName("spinBox_cores")
        self.label = QtWidgets.QLabel(RunPbs)
        self.label.setGeometry(QtCore.QRect(12, 7, 101, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.pushButton_cancel = QtWidgets.QPushButton(RunPbs)
        self.pushButton_cancel.setGeometry(QtCore.QRect(240, 120, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.lineEdit_header = QtWidgets.QLineEdit(RunPbs)
        self.lineEdit_header.setGeometry(QtCore.QRect(172, 79, 181, 25))
        self.lineEdit_header.setObjectName("lineEdit_header")
        self.pushButton_header = QtWidgets.QPushButton(RunPbs)
        self.pushButton_header.setGeometry(QtCore.QRect(360, 80, 86, 24))
        self.pushButton_header.setObjectName("pushButton_header")
        self.label_4 = QtWidgets.QLabel(RunPbs)
        self.label_4.setGeometry(QtCore.QRect(30, 82, 131, 20))
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName("label_4")

        self.retranslateUi(RunPbs)
        QtCore.QMetaObject.connectSlotsByName(RunPbs)
        RunPbs.setTabOrder(self.spinBox_cores, self.lineEdit_header)
        RunPbs.setTabOrder(self.lineEdit_header, self.pushButton_header)
        RunPbs.setTabOrder(self.pushButton_header, self.pushButton_ok)
        RunPbs.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, RunPbs):
        _translate = QtCore.QCoreApplication.translate
        RunPbs.setWindowTitle(_translate("RunPbs", "Configure PBS"))
        self.label_2.setText(_translate("RunPbs", "Number of cores"))
        self.pushButton_ok.setText(_translate("RunPbs", "Ok"))
        self.label.setText(_translate("RunPbs", "Run with PBS"))
        self.pushButton_cancel.setText(_translate("RunPbs", "Cancel"))
        self.pushButton_header.setText(_translate("RunPbs", "Browse"))
        self.label_4.setText(_translate("RunPbs", "Custom header file"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    RunPbs = QtWidgets.QWidget()
    ui = Ui_RunPbs()
    ui.setupUi(RunPbs)
    RunPbs.show()
    sys.exit(app.exec_())

