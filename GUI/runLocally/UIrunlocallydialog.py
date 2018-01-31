# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/Dropbox/work/ChemFlow/GUI/runLocally/runlocallydialog.ui'
#
# Created by: PyQt5 UI code generator 5.10
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_RunLocallyDialog(object):
    def setupUi(self, RunLocallyDialog):
        RunLocallyDialog.setObjectName("RunLocallyDialog")
        RunLocallyDialog.resize(291, 139)
        self.pushButton_ok = QtWidgets.QPushButton(RunLocallyDialog)
        self.pushButton_ok.setGeometry(QtCore.QRect(40, 100, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.pushButton_cancel = QtWidgets.QPushButton(RunLocallyDialog)
        self.pushButton_cancel.setGeometry(QtCore.QRect(160, 100, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.label = QtWidgets.QLabel(RunLocallyDialog)
        self.label.setGeometry(QtCore.QRect(10, 10, 81, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.line = QtWidgets.QFrame(RunLocallyDialog)
        self.line.setGeometry(QtCore.QRect(90, 10, 191, 20))
        self.line.setFrameShape(QtWidgets.QFrame.HLine)
        self.line.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line.setObjectName("line")
        self.line_2 = QtWidgets.QFrame(RunLocallyDialog)
        self.line_2.setGeometry(QtCore.QRect(0, 30, 20, 61))
        self.line_2.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_2.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_2.setObjectName("line_2")
        self.label_2 = QtWidgets.QLabel(RunLocallyDialog)
        self.label_2.setGeometry(QtCore.QRect(40, 46, 121, 21))
        self.label_2.setObjectName("label_2")
        self.spinBox = QtWidgets.QSpinBox(RunLocallyDialog)
        self.spinBox.setGeometry(QtCore.QRect(156, 43, 71, 27))
        self.spinBox.setMinimum(1)
        self.spinBox.setMaximum(1024)
        self.spinBox.setObjectName("spinBox")
        self.line_3 = QtWidgets.QFrame(RunLocallyDialog)
        self.line_3.setGeometry(QtCore.QRect(10, 80, 271, 21))
        self.line_3.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_3.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_3.setObjectName("line_3")

        self.retranslateUi(RunLocallyDialog)
        QtCore.QMetaObject.connectSlotsByName(RunLocallyDialog)

    def retranslateUi(self, RunLocallyDialog):
        _translate = QtCore.QCoreApplication.translate
        RunLocallyDialog.setWindowTitle(_translate("RunLocallyDialog", "Local Run Parameters"))
        self.pushButton_ok.setText(_translate("RunLocallyDialog", "Ok"))
        self.pushButton_cancel.setText(_translate("RunLocallyDialog", "Cancel"))
        self.label.setText(_translate("RunLocallyDialog", "Run locally"))
        self.label_2.setText(_translate("RunLocallyDialog", "Number of cores"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    RunLocallyDialog = QtWidgets.QDialog()
    ui = Ui_RunLocallyDialog()
    ui.setupUi(RunLocallyDialog)
    RunLocallyDialog.show()
    sys.exit(app.exec_())

