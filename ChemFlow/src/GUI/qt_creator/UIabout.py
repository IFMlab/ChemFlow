# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/about.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_About(object):
    def setupUi(self, About):
        About.setObjectName("About")
        About.resize(489, 317)
        self.label_logo = QtWidgets.QLabel(About)
        self.label_logo.setGeometry(QtCore.QRect(100, 10, 61, 51))
        self.label_logo.setText("")
        self.label_logo.setPixmap(QtGui.QPixmap("../img/logo.png"))
        self.label_logo.setAlignment(QtCore.Qt.AlignCenter)
        self.label_logo.setObjectName("label_logo")
        self.label_logo_2 = QtWidgets.QLabel(About)
        self.label_logo_2.setGeometry(QtCore.QRect(180, 10, 231, 51))
        font = QtGui.QFont()
        font.setPointSize(28)
        font.setBold(True)
        font.setItalic(True)
        font.setWeight(75)
        self.label_logo_2.setFont(font)
        self.label_logo_2.setObjectName("label_logo_2")
        self.textBrowser = QtWidgets.QTextBrowser(About)
        self.textBrowser.setGeometry(QtCore.QRect(30, 71, 431, 201))
        self.textBrowser.setObjectName("textBrowser")
        self.pushButton = QtWidgets.QPushButton(About)
        self.pushButton.setGeometry(QtCore.QRect(200, 280, 86, 29))
        self.pushButton.setObjectName("pushButton")

        self.retranslateUi(About)
        QtCore.QMetaObject.connectSlotsByName(About)

    def retranslateUi(self, About):
        _translate = QtCore.QCoreApplication.translate
        About.setWindowTitle(_translate("About", "About"))
        self.label_logo_2.setText(_translate("About", "ChemFlow"))
        self.textBrowser.setHtml(_translate("About", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:\'Cantarell\'; font-size:10pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">ChemFlow was developped by Diego E. Barreto Gomes, Cedric Bouysset, and Donatienne de Francquen under the supervision of Marco Cecchini at the <a href=\"http://institut-chimie.unistra.fr/equipes-de-recherche/ifm-laboratoire-dingenierie-des-fonctions-moleculaires/\"><span style=\" text-decoration: underline; color:#0000ff;\">Universite de Strasbourg</span></a>.</p>\n"
"<p style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><br /></p>\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">Please cite us by using the following reference:</p>\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-style:italic;\">TODO:insert-ref-here</span></p></body></html>"))
        self.pushButton.setText(_translate("About", "Close"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    About = QtWidgets.QWidget()
    ui = Ui_About()
    ui.setupUi(About)
    About.show()
    sys.exit(app.exec_())

