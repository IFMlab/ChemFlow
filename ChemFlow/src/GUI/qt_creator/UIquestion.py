# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/question.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_QuestionDialog(object):
    def setupUi(self, QuestionDialog):
        QuestionDialog.setObjectName("QuestionDialog")
        QuestionDialog.resize(400, 178)
        self.label_logo = QtWidgets.QLabel(QuestionDialog)
        self.label_logo.setGeometry(QtCore.QRect(10, 10, 48, 48))
        self.label_logo.setText("")
        self.label_logo.setScaledContents(True)
        self.label_logo.setObjectName("label_logo")
        self.scrollArea = QtWidgets.QScrollArea(QuestionDialog)
        self.scrollArea.setGeometry(QtCore.QRect(70, 8, 321, 81))
        self.scrollArea.setWidgetResizable(False)
        self.scrollArea.setObjectName("scrollArea")
        self.scrollAreaWidgetContents = QtWidgets.QWidget()
        self.scrollAreaWidgetContents.setGeometry(QtCore.QRect(0, 0, 319, 79))
        self.scrollAreaWidgetContents.setObjectName("scrollAreaWidgetContents")
        self.scrollArea.setWidget(self.scrollAreaWidgetContents)
        self.lineEdit = QtWidgets.QLineEdit(QuestionDialog)
        self.lineEdit.setGeometry(QtCore.QRect(70, 100, 321, 29))
        self.lineEdit.setObjectName("lineEdit")
        self.pushButton = QtWidgets.QPushButton(QuestionDialog)
        self.pushButton.setGeometry(QtCore.QRect(157, 140, 86, 29))
        self.pushButton.setObjectName("pushButton")
        self.label_2 = QtWidgets.QLabel(QuestionDialog)
        self.label_2.setGeometry(QtCore.QRect(0, 106, 61, 21))
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")

        self.retranslateUi(QuestionDialog)
        QtCore.QMetaObject.connectSlotsByName(QuestionDialog)
        QuestionDialog.setTabOrder(self.scrollArea, self.lineEdit)
        QuestionDialog.setTabOrder(self.lineEdit, self.pushButton)

    def retranslateUi(self, QuestionDialog):
        _translate = QtCore.QCoreApplication.translate
        QuestionDialog.setWindowTitle(_translate("QuestionDialog", "Question"))
        self.pushButton.setText(_translate("QuestionDialog", "Submit"))
        self.label_2.setText(_translate("QuestionDialog", "Answer"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    QuestionDialog = QtWidgets.QWidget()
    ui = Ui_QuestionDialog()
    ui.setupUi(QuestionDialog)
    QuestionDialog.show()
    sys.exit(app.exec_())

