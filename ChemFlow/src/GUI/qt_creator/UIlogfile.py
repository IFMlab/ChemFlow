# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/logfile.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Logfile(object):
    def setupUi(self, Logfile):
        Logfile.setObjectName("Logfile")
        Logfile.resize(661, 537)
        self.pushButton_close = QtWidgets.QPushButton(Logfile)
        self.pushButton_close.setGeometry(QtCore.QRect(336, 500, 99, 27))
        self.pushButton_close.setObjectName("pushButton_close")
        self.pushButton_remove = QtWidgets.QPushButton(Logfile)
        self.pushButton_remove.setGeometry(QtCore.QRect(226, 500, 99, 27))
        self.pushButton_remove.setObjectName("pushButton_remove")
        self.plainTextEdit_log = QtWidgets.QPlainTextEdit(Logfile)
        self.plainTextEdit_log.setGeometry(QtCore.QRect(9, 30, 644, 461))
        self.plainTextEdit_log.setReadOnly(True)
        self.plainTextEdit_log.setObjectName("plainTextEdit_log")
        self.label = QtWidgets.QLabel(Logfile)
        self.label.setGeometry(QtCore.QRect(11, 7, 67, 17))
        self.label.setObjectName("label")
        self.lineEdit = QtWidgets.QLineEdit(Logfile)
        self.lineEdit.setGeometry(QtCore.QRect(76, 5, 577, 21))
        font = QtGui.QFont()
        font.setPointSize(10)
        self.lineEdit.setFont(font)
        self.lineEdit.setReadOnly(True)
        self.lineEdit.setObjectName("lineEdit")

        self.retranslateUi(Logfile)
        QtCore.QMetaObject.connectSlotsByName(Logfile)

    def retranslateUi(self, Logfile):
        _translate = QtCore.QCoreApplication.translate
        Logfile.setWindowTitle(_translate("Logfile", "Logfile"))
        self.pushButton_close.setText(_translate("Logfile", "Close"))
        self.pushButton_remove.setText(_translate("Logfile", "Remove"))
        self.label.setText(_translate("Logfile", "Location"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    Logfile = QtWidgets.QWidget()
    ui = Ui_Logfile()
    ui.setupUi(Logfile)
    Logfile.show()
    sys.exit(app.exec_())

