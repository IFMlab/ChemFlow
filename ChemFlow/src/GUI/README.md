Graphical User Interface created with Qt Creator 4.5.0

Based on Qt 5.10.0 (GCC 7.2.1 20171128, 64 bit)

Converted UI style sheet to python code with pyuic5

Packaged as a single executable file with PyInstaller

To modify elements from the GUI, open the project ./qt_creator/GUI.pro in Qt Creator. Modify the desired elements from the .ui files, then save and convert the .ui to .py with pyuic5, prepending the name of the output file with UI. Then import the necessary python classes from these UI*.py files and add your own methods/actions. Do not modify the .py files inside the qt_creator folder manually, as they will be overwritten later.
