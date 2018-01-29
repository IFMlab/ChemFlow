# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/Dropbox/work/ChemFlow/UI/ChemFlow/MD/mddialog.ui'
#
# Created by: PyQt5 UI code generator 5.9.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_MDDialog(object):
    def setupUi(self, MDDialog):
        MDDialog.setObjectName("MDDialog")
        MDDialog.resize(328, 185)
        self.pushButton_cancel = QtWidgets.QPushButton(MDDialog)
        self.pushButton_cancel.setGeometry(QtCore.QRect(184, 150, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.line_2 = QtWidgets.QFrame(MDDialog)
        self.line_2.setGeometry(QtCore.QRect(0, 30, 20, 111))
        self.line_2.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_2.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_2.setObjectName("line_2")
        self.label = QtWidgets.QLabel(MDDialog)
        self.label.setGeometry(QtCore.QRect(10, 10, 91, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.line_3 = QtWidgets.QFrame(MDDialog)
        self.line_3.setGeometry(QtCore.QRect(10, 130, 311, 21))
        self.line_3.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_3.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_3.setObjectName("line_3")
        self.pushButton_ok = QtWidgets.QPushButton(MDDialog)
        self.pushButton_ok.setGeometry(QtCore.QRect(54, 150, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.line = QtWidgets.QFrame(MDDialog)
        self.line.setGeometry(QtCore.QRect(110, 10, 211, 20))
        self.line.setFrameShape(QtWidgets.QFrame.HLine)
        self.line.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line.setObjectName("line")
        self.label_2 = QtWidgets.QLabel(MDDialog)
        self.label_2.setGeometry(QtCore.QRect(33, 70, 111, 17))
        self.label_2.setObjectName("label_2")
        self.spinBox_time = QtWidgets.QSpinBox(MDDialog)
        self.spinBox_time.setGeometry(QtCore.QRect(140, 65, 91, 27))
        self.spinBox_time.setMinimum(100)
        self.spinBox_time.setMaximum(50000)
        self.spinBox_time.setSingleStep(50)
        self.spinBox_time.setProperty("value", 250)
        self.spinBox_time.setObjectName("spinBox_time")
        self.label_3 = QtWidgets.QLabel(MDDialog)
        self.label_3.setGeometry(QtCore.QRect(240, 70, 31, 17))
        self.label_3.setObjectName("label_3")
        self.label_4 = QtWidgets.QLabel(MDDialog)
        self.label_4.setGeometry(QtCore.QRect(105, 30, 31, 20))
        self.label_4.setObjectName("label_4")
        self.comboBox_run = QtWidgets.QComboBox(MDDialog)
        self.comboBox_run.setGeometry(QtCore.QRect(140, 30, 121, 25))
        self.comboBox_run.setObjectName("comboBox_run")
        self.comboBox_run.addItem("")
        self.comboBox_run.addItem("")
        self.comboBox_run.addItem("")
        self.comboBox_gb = QtWidgets.QComboBox(MDDialog)
        self.comboBox_gb.setGeometry(QtCore.QRect(140, 104, 69, 25))
        self.comboBox_gb.setObjectName("comboBox_gb")
        self.comboBox_gb.addItem("")
        self.comboBox_gb.addItem("")
        self.comboBox_gb.addItem("")
        self.label_7 = QtWidgets.QLabel(MDDialog)
        self.label_7.setGeometry(QtCore.QRect(70, 107, 56, 17))
        self.label_7.setObjectName("label_7")

        self.retranslateUi(MDDialog)
        QtCore.QMetaObject.connectSlotsByName(MDDialog)

    def retranslateUi(self, MDDialog):
        _translate = QtCore.QCoreApplication.translate
        MDDialog.setWindowTitle(_translate("MDDialog", "MD Parameters"))
        self.pushButton_cancel.setText(_translate("MDDialog", "Cancel"))
        self.label.setText(_translate("MDDialog", "MD simulation"))
        self.pushButton_ok.setText(_translate("MDDialog", "Ok"))
        self.label_2.setText(_translate("MDDialog", "Production length"))
        self.label_3.setText(_translate("MDDialog", "ps"))
        self.label_4.setText(_translate("MDDialog", "Run"))
        self.comboBox_run.setItemText(0, _translate("MDDialog", "Sander"))
        self.comboBox_run.setItemText(1, _translate("MDDialog", "PMEMD.cuda"))
        self.comboBox_run.setItemText(2, _translate("MDDialog", "PMEMD.mpi"))
        self.comboBox_gb.setItemText(0, _translate("MDDialog", "1"))
        self.comboBox_gb.setItemText(1, _translate("MDDialog", "5"))
        self.comboBox_gb.setItemText(2, _translate("MDDialog", "8"))
        self.label_7.setText(_translate("MDDialog", "GB model"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    MDDialog = QtWidgets.QDialog()
    ui = Ui_MDDialog()
    ui.setupUi(MDDialog)
    MDDialog.show()
    sys.exit(app.exec_())

