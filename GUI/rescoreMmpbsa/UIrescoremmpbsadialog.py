# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/Dropbox/work/ChemFlow/GUI/rescoreMmpbsa/rescoremmpbsadialog.ui'
#
# Created by: PyQt5 UI code generator 5.10
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_rescoreMmpbsaDialog(object):
    def setupUi(self, rescoreMmpbsaDialog):
        rescoreMmpbsaDialog.setObjectName("rescoreMmpbsaDialog")
        rescoreMmpbsaDialog.resize(587, 302)
        self.label = QtWidgets.QLabel(rescoreMmpbsaDialog)
        self.label.setGeometry(QtCore.QRect(13, 10, 191, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.pushButton_amber = QtWidgets.QPushButton(rescoreMmpbsaDialog)
        self.pushButton_amber.setGeometry(QtCore.QRect(486, 40, 86, 21))
        self.pushButton_amber.setObjectName("pushButton_amber")
        self.line_3 = QtWidgets.QFrame(rescoreMmpbsaDialog)
        self.line_3.setGeometry(QtCore.QRect(13, 240, 561, 21))
        self.line_3.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_3.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_3.setObjectName("line_3")
        self.pushButton_ok = QtWidgets.QPushButton(rescoreMmpbsaDialog)
        self.pushButton_ok.setGeometry(QtCore.QRect(180, 260, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.comboBox_model = QtWidgets.QComboBox(rescoreMmpbsaDialog)
        self.comboBox_model.setGeometry(QtCore.QRect(80, 217, 86, 24))
        self.comboBox_model.setObjectName("comboBox_model")
        self.comboBox_model.addItem("")
        self.comboBox_model.addItem("")
        self.comboBox_model.addItem("")
        self.label_4 = QtWidgets.QLabel(rescoreMmpbsaDialog)
        self.label_4.setGeometry(QtCore.QRect(30, 218, 41, 21))
        self.label_4.setObjectName("label_4")
        self.pushButton_cancel = QtWidgets.QPushButton(rescoreMmpbsaDialog)
        self.pushButton_cancel.setGeometry(QtCore.QRect(310, 260, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.textBrowser_amber = QtWidgets.QTextBrowser(rescoreMmpbsaDialog)
        self.textBrowser_amber.setGeometry(QtCore.QRect(125, 40, 351, 21))
        font = QtGui.QFont()
        font.setPointSize(8)
        self.textBrowser_amber.setFont(font)
        self.textBrowser_amber.setObjectName("textBrowser_amber")
        self.label_exec = QtWidgets.QLabel(rescoreMmpbsaDialog)
        self.label_exec.setGeometry(QtCore.QRect(27, 40, 101, 20))
        self.label_exec.setObjectName("label_exec")
        self.line_2 = QtWidgets.QFrame(rescoreMmpbsaDialog)
        self.line_2.setGeometry(QtCore.QRect(3, 30, 20, 221))
        self.line_2.setFrameShape(QtWidgets.QFrame.VLine)
        self.line_2.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_2.setObjectName("line_2")
        self.line = QtWidgets.QFrame(rescoreMmpbsaDialog)
        self.line.setGeometry(QtCore.QRect(203, 10, 371, 20))
        self.line.setFrameShape(QtWidgets.QFrame.HLine)
        self.line.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line.setObjectName("line")
        self.pushButton_MD = QtWidgets.QPushButton(rescoreMmpbsaDialog)
        self.pushButton_MD.setGeometry(QtCore.QRect(486, 216, 86, 24))
        self.pushButton_MD.setObjectName("pushButton_MD")
        self.checkBox_MD = QtWidgets.QCheckBox(rescoreMmpbsaDialog)
        self.checkBox_MD.setGeometry(QtCore.QRect(325, 217, 161, 22))
        self.checkBox_MD.setObjectName("checkBox_MD")
        self.tableWidget = QtWidgets.QTableWidget(rescoreMmpbsaDialog)
        self.tableWidget.setGeometry(QtCore.QRect(30, 70, 541, 137))
        self.tableWidget.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)
        self.tableWidget.setAlternatingRowColors(True)
        self.tableWidget.setWordWrap(False)
        self.tableWidget.setObjectName("tableWidget")
        self.tableWidget.setColumnCount(5)
        self.tableWidget.setRowCount(3)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setVerticalHeaderItem(0, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setVerticalHeaderItem(1, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setVerticalHeaderItem(2, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setHorizontalHeaderItem(0, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setHorizontalHeaderItem(1, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setHorizontalHeaderItem(2, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setHorizontalHeaderItem(3, item)
        item = QtWidgets.QTableWidgetItem()
        self.tableWidget.setHorizontalHeaderItem(4, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(0, 0, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(0, 1, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(0, 2, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(0, 3, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(0, 4, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(1, 0, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(1, 1, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(1, 2, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(1, 3, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(1, 4, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(2, 0, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(2, 1, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(2, 2, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(2, 3, item)
        item = QtWidgets.QTableWidgetItem()
        item.setTextAlignment(QtCore.Qt.AlignCenter)
        self.tableWidget.setItem(2, 4, item)
        self.tableWidget.horizontalHeader().setVisible(True)
        self.tableWidget.horizontalHeader().setCascadingSectionResizes(True)
        self.tableWidget.horizontalHeader().setDefaultSectionSize(100)
        self.tableWidget.horizontalHeader().setMinimumSectionSize(1)
        self.tableWidget.horizontalHeader().setStretchLastSection(False)
        self.tableWidget.verticalHeader().setVisible(False)

        self.retranslateUi(rescoreMmpbsaDialog)
        QtCore.QMetaObject.connectSlotsByName(rescoreMmpbsaDialog)

    def retranslateUi(self, rescoreMmpbsaDialog):
        _translate = QtCore.QCoreApplication.translate
        rescoreMmpbsaDialog.setWindowTitle(_translate("rescoreMmpbsaDialog", "MM/PBSA Rescoring Parameters"))
        self.label.setText(_translate("rescoreMmpbsaDialog", "Rescoring with MM/PBSA"))
        self.pushButton_amber.setText(_translate("rescoreMmpbsaDialog", "Browse"))
        self.pushButton_ok.setText(_translate("rescoreMmpbsaDialog", "Ok"))
        self.comboBox_model.setToolTip(_translate("rescoreMmpbsaDialog", "<html><head/><body><p>- plp95: Piecewise Linear Potential from Gehlhaar DK et al</p><p>- plp: PLANTS version of the Piecewise Linear Potential</p><p>- chemplp: PLANTS version of the Piecewise Linear Potential implementing GOLD\'s terms</p></body></html>"))
        self.comboBox_model.setItemText(0, _translate("rescoreMmpbsaDialog", "PB3"))
        self.comboBox_model.setItemText(1, _translate("rescoreMmpbsaDialog", "GB5"))
        self.comboBox_model.setItemText(2, _translate("rescoreMmpbsaDialog", "GB8"))
        self.label_4.setText(_translate("rescoreMmpbsaDialog", "Model"))
        self.pushButton_cancel.setText(_translate("rescoreMmpbsaDialog", "Cancel"))
        self.label_exec.setText(_translate("rescoreMmpbsaDialog", "amber.sh File"))
        self.pushButton_MD.setText(_translate("rescoreMmpbsaDialog", "Configure"))
        self.checkBox_MD.setToolTip(_translate("rescoreMmpbsaDialog", "<html><head/><body><p>Run a short implicit solvent (GB) MD</p></body></html>"))
        self.checkBox_MD.setText(_translate("rescoreMmpbsaDialog", "Short MD simulation"))
        item = self.tableWidget.verticalHeaderItem(0)
        item.setText(_translate("rescoreMmpbsaDialog", "PB3"))
        item = self.tableWidget.verticalHeaderItem(1)
        item.setText(_translate("rescoreMmpbsaDialog", "GB5"))
        item = self.tableWidget.verticalHeaderItem(2)
        item.setText(_translate("rescoreMmpbsaDialog", "GB8"))
        item = self.tableWidget.horizontalHeaderItem(0)
        item.setText(_translate("rescoreMmpbsaDialog", "Model"))
        item = self.tableWidget.horizontalHeaderItem(1)
        item.setText(_translate("rescoreMmpbsaDialog", "Radii for Gpol"))
        item = self.tableWidget.horizontalHeaderItem(2)
        item.setText(_translate("rescoreMmpbsaDialog", "SASA for Gnp"))
        item = self.tableWidget.horizontalHeaderItem(3)
        item.setText(_translate("rescoreMmpbsaDialog", "Surface Tension (γ)"))
        item = self.tableWidget.horizontalHeaderItem(4)
        item.setText(_translate("rescoreMmpbsaDialog", "Surface Offset (β)"))
        __sortingEnabled = self.tableWidget.isSortingEnabled()
        self.tableWidget.setSortingEnabled(False)
        item = self.tableWidget.item(0, 0)
        item.setText(_translate("rescoreMmpbsaDialog", "PB3"))
        item = self.tableWidget.item(0, 1)
        item.setText(_translate("rescoreMmpbsaDialog", "Parse"))
        item = self.tableWidget.item(0, 2)
        item.setText(_translate("rescoreMmpbsaDialog", "Molsurf"))
        item = self.tableWidget.item(0, 3)
        item.setText(_translate("rescoreMmpbsaDialog", "0.00542"))
        item = self.tableWidget.item(0, 4)
        item.setText(_translate("rescoreMmpbsaDialog", "0.92"))
        item = self.tableWidget.item(1, 0)
        item.setText(_translate("rescoreMmpbsaDialog", "GB5"))
        item = self.tableWidget.item(1, 1)
        item.setText(_translate("rescoreMmpbsaDialog", "mbondi2"))
        item = self.tableWidget.item(1, 2)
        item.setText(_translate("rescoreMmpbsaDialog", "LCPO"))
        item = self.tableWidget.item(1, 3)
        item.setText(_translate("rescoreMmpbsaDialog", "0.00500"))
        item = self.tableWidget.item(1, 4)
        item.setText(_translate("rescoreMmpbsaDialog", "0"))
        item = self.tableWidget.item(2, 0)
        item.setText(_translate("rescoreMmpbsaDialog", "GB8"))
        item = self.tableWidget.item(2, 1)
        item.setText(_translate("rescoreMmpbsaDialog", "mbondi3"))
        item = self.tableWidget.item(2, 2)
        item.setText(_translate("rescoreMmpbsaDialog", "LCPO"))
        item = self.tableWidget.item(2, 3)
        item.setText(_translate("rescoreMmpbsaDialog", "Atom dependant"))
        item = self.tableWidget.item(2, 4)
        item.setText(_translate("rescoreMmpbsaDialog", "0.195141"))
        self.tableWidget.setSortingEnabled(__sortingEnabled)


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    rescoreMmpbsaDialog = QtWidgets.QDialog()
    ui = Ui_rescoreMmpbsaDialog()
    ui.setupUi(rescoreMmpbsaDialog)
    rescoreMmpbsaDialog.show()
    sys.exit(app.exec_())

