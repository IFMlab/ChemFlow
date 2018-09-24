# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/run_local.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_RunLocal(object):
    def setupUi(self, RunLocal):
        RunLocal.setObjectName("RunLocal")
        RunLocal.resize(297, 142)
        self.label_2 = QtWidgets.QLabel(RunLocal)
        self.label_2.setGeometry(QtCore.QRect(44, 46, 121, 21))
        self.label_2.setObjectName("label_2")
        self.spinBox_cores = QtWidgets.QSpinBox(RunLocal)
        self.spinBox_cores.setGeometry(QtCore.QRect(160, 43, 71, 27))
        self.spinBox_cores.setMinimum(1)
        self.spinBox_cores.setMaximum(1024)
        self.spinBox_cores.setObjectName("spinBox_cores")
        self.pushButton_ok = QtWidgets.QPushButton(RunLocal)
        self.pushButton_ok.setGeometry(QtCore.QRect(44, 100, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.label = QtWidgets.QLabel(RunLocal)
        self.label.setGeometry(QtCore.QRect(14, 10, 81, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.pushButton_cancel = QtWidgets.QPushButton(RunLocal)
        self.pushButton_cancel.setGeometry(QtCore.QRect(164, 100, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")

        self.retranslateUi(RunLocal)
        QtCore.QMetaObject.connectSlotsByName(RunLocal)
        RunLocal.setTabOrder(self.spinBox_cores, self.pushButton_ok)
        RunLocal.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, RunLocal):
        _translate = QtCore.QCoreApplication.translate
        RunLocal.setWindowTitle(_translate("RunLocal", "Configure local run"))
        self.label_2.setText(_translate("RunLocal", "Number of cores"))
        self.pushButton_ok.setText(_translate("RunLocal", "Ok"))
        self.label.setText(_translate("RunLocal", "Run locally"))
        self.pushButton_cancel.setText(_translate("RunLocal", "Cancel"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    RunLocal = QtWidgets.QWidget()
    ui = Ui_RunLocal()
    ui.setupUi(RunLocal)
    RunLocal.show()
    sys.exit(app.exec_())

