# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/Dropbox/work/ChemFlow/ChemFlow/src/GUI/qt_creator/create_project.ui'
#
# Created by: PyQt5 UI code generator 5.10
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_CreateProject(object):
    def setupUi(self, CreateProject):
        CreateProject.setObjectName("CreateProject")
        CreateProject.resize(462, 152)
        self.label = QtWidgets.QLabel(CreateProject)
        self.label.setGeometry(QtCore.QRect(10, 10, 201, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.label_2 = QtWidgets.QLabel(CreateProject)
        self.label_2.setGeometry(QtCore.QRect(20, 43, 111, 17))
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")
        self.pushButton_browse = QtWidgets.QPushButton(CreateProject)
        self.pushButton_browse.setGeometry(QtCore.QRect(360, 40, 86, 21))
        self.pushButton_browse.setObjectName("pushButton_browse")
        self.label_3 = QtWidgets.QLabel(CreateProject)
        self.label_3.setGeometry(QtCore.QRect(30, 70, 101, 20))
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName("label_3")
        self.lineEdit_name = QtWidgets.QLineEdit(CreateProject)
        self.lineEdit_name.setGeometry(QtCore.QRect(142, 70, 210, 21))
        self.lineEdit_name.setObjectName("lineEdit_name")
        self.pushButton_cancel = QtWidgets.QPushButton(CreateProject)
        self.pushButton_cancel.setGeometry(QtCore.QRect(256, 110, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.pushButton_ok = QtWidgets.QPushButton(CreateProject)
        self.pushButton_ok.setGeometry(QtCore.QRect(126, 110, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.lineEdit_path = QtWidgets.QLineEdit(CreateProject)
        self.lineEdit_path.setGeometry(QtCore.QRect(142, 40, 210, 21))
        self.lineEdit_path.setObjectName("lineEdit_path")

        self.retranslateUi(CreateProject)
        QtCore.QMetaObject.connectSlotsByName(CreateProject)

    def retranslateUi(self, CreateProject):
        _translate = QtCore.QCoreApplication.translate
        CreateProject.setWindowTitle(_translate("CreateProject", "Create project"))
        self.label.setText(_translate("CreateProject", "Create a new ChemFlow project"))
        self.label_2.setText(_translate("CreateProject", "Project location"))
        self.pushButton_browse.setText(_translate("CreateProject", "Browse"))
        self.label_3.setText(_translate("CreateProject", "Project name"))
        self.pushButton_cancel.setText(_translate("CreateProject", "Cancel"))
        self.pushButton_ok.setText(_translate("CreateProject", "Ok"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    CreateProject = QtWidgets.QWidget()
    ui = Ui_CreateProject()
    ui.setupUi(CreateProject)
    CreateProject.show()
    sys.exit(app.exec_())

