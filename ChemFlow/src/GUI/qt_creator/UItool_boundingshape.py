# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '/home/cedric/software/ChemFlow/ChemFlow/src/GUI/qt_creator/tool_boundingshape.ui'
#
# Created by: PyQt5 UI code generator 5.11.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_ToolBoundingShape(object):
    def setupUi(self, ToolBoundingShape):
        ToolBoundingShape.setObjectName("ToolBoundingShape")
        ToolBoundingShape.resize(434, 230)
        self.pushButton_ok = QtWidgets.QPushButton(ToolBoundingShape)
        self.pushButton_ok.setGeometry(QtCore.QRect(110, 190, 86, 29))
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.pushButton_cancel = QtWidgets.QPushButton(ToolBoundingShape)
        self.pushButton_cancel.setGeometry(QtCore.QRect(240, 190, 86, 29))
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.label = QtWidgets.QLabel(ToolBoundingShape)
        self.label.setGeometry(QtCore.QRect(14, 10, 131, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label.setFont(font)
        self.label.setObjectName("label")
        self.doubleSpinBox_padding = QtWidgets.QDoubleSpinBox(ToolBoundingShape)
        self.doubleSpinBox_padding.setGeometry(QtCore.QRect(120, 107, 69, 27))
        self.doubleSpinBox_padding.setMaximum(9999.0)
        self.doubleSpinBox_padding.setSingleStep(0.1)
        self.doubleSpinBox_padding.setProperty("value", 0.5)
        self.doubleSpinBox_padding.setObjectName("doubleSpinBox_padding")
        self.radioButton_box = QtWidgets.QRadioButton(ToolBoundingShape)
        self.radioButton_box.setGeometry(QtCore.QRect(120, 70, 71, 22))
        self.radioButton_box.setChecked(False)
        self.radioButton_box.setObjectName("radioButton_box")
        self.radioButton_sphere = QtWidgets.QRadioButton(ToolBoundingShape)
        self.radioButton_sphere.setGeometry(QtCore.QRect(200, 70, 91, 22))
        self.radioButton_sphere.setChecked(True)
        self.radioButton_sphere.setObjectName("radioButton_sphere")
        self.checkBox_pymol = QtWidgets.QCheckBox(ToolBoundingShape)
        self.checkBox_pymol.setGeometry(QtCore.QRect(120, 150, 201, 22))
        self.checkBox_pymol.setObjectName("checkBox_pymol")
        self.label_2 = QtWidgets.QLabel(ToolBoundingShape)
        self.label_2.setGeometry(QtCore.QRect(30, 70, 61, 20))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_2.setFont(font)
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName("label_2")
        self.label_3 = QtWidgets.QLabel(ToolBoundingShape)
        self.label_3.setGeometry(QtCore.QRect(24, 110, 67, 17))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_3.setFont(font)
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName("label_3")
        self.label_rec = QtWidgets.QLabel(ToolBoundingShape)
        self.label_rec.setGeometry(QtCore.QRect(20, 37, 71, 20))
        font = QtGui.QFont()
        font.setBold(True)
        font.setWeight(75)
        self.label_rec.setFont(font)
        self.label_rec.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_rec.setObjectName("label_rec")
        self.lineEdit_path = QtWidgets.QLineEdit(ToolBoundingShape)
        self.lineEdit_path.setGeometry(QtCore.QRect(124, 38, 212, 20))
        self.lineEdit_path.setObjectName("lineEdit_path")
        self.pushButton_input = QtWidgets.QPushButton(ToolBoundingShape)
        self.pushButton_input.setGeometry(QtCore.QRect(340, 36, 86, 23))
        self.pushButton_input.setObjectName("pushButton_input")

        self.retranslateUi(ToolBoundingShape)
        QtCore.QMetaObject.connectSlotsByName(ToolBoundingShape)

    def retranslateUi(self, ToolBoundingShape):
        _translate = QtCore.QCoreApplication.translate
        ToolBoundingShape.setWindowTitle(_translate("ToolBoundingShape", "Bounding shape"))
        self.pushButton_ok.setText(_translate("ToolBoundingShape", "Ok"))
        self.pushButton_cancel.setText(_translate("ToolBoundingShape", "Cancel"))
        self.label.setText(_translate("ToolBoundingShape", "Bounding shape"))
        self.doubleSpinBox_padding.setToolTip(_translate("ToolBoundingShape", "<html><head/><body><p>Value systematically added to the radius/size. Avoids returning a shape that is too restrictive for the input molecule.</p></body></html>"))
        self.radioButton_box.setToolTip(_translate("ToolBoundingShape", "<html><head/><body><p>Outputs the center (XYZ) coordinates and size (XYZ) of the box containing all the atoms of the input molecule.</p></body></html>"))
        self.radioButton_box.setText(_translate("ToolBoundingShape", "Box"))
        self.radioButton_sphere.setToolTip(_translate("ToolBoundingShape", "<html><head/><body><p>Outputs the center (XYZ) coordinates and radius of the sphere containing all the atoms of the input molecule.</p></body></html>"))
        self.radioButton_sphere.setText(_translate("ToolBoundingShape", "Sphere"))
        self.checkBox_pymol.setToolTip(_translate("ToolBoundingShape", "<html><head/><body><p>Additional output of PyMOL commands to visualize the shape. Copy and paste them in the PyMOL console after loading your input molecule.</p></body></html>"))
        self.checkBox_pymol.setText(_translate("ToolBoundingShape", "Show PyMOL commands"))
        self.label_2.setToolTip(_translate("ToolBoundingShape", "<html><head/><body><p>Shape of the container object</p></body></html>"))
        self.label_2.setText(_translate("ToolBoundingShape", "Shape"))
        self.label_3.setToolTip(_translate("ToolBoundingShape", "Value systematically added to the radius/size. Avoids returning a shape that is too restrictive for the input molecule."))
        self.label_3.setText(_translate("ToolBoundingShape", "Padding"))
        self.label_rec.setText(_translate("ToolBoundingShape", "Ligand"))
        self.lineEdit_path.setPlaceholderText(_translate("ToolBoundingShape", "Path to a MOL2 file"))
        self.pushButton_input.setToolTip(_translate("ToolBoundingShape", "<html><head/><body><p>MOL2 file containing a single molecule</p></body></html>"))
        self.pushButton_input.setText(_translate("ToolBoundingShape", "Browse"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    ToolBoundingShape = QtWidgets.QWidget()
    ui = Ui_ToolBoundingShape()
    ui.setupUi(ToolBoundingShape)
    ToolBoundingShape.show()
    sys.exit(app.exec_())

