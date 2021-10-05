# Information

Graphical User Interface created with Qt Creator 4.7.0

Based on **PyQt 5.11.2**

Converted UI style sheet to python code with pyuic5.
To do this step automatically from qtcreator: open **Tools > External > Configure > Add > Add Tools**, then name it accordingly and configure it as follow:
* Description: `Converts .ui to .py`
* Executable: `<your path to pyuic5>`
* Arguments: `-o UI%{CurrentDocument:FileBaseName}.py -x %{CurrentDocument:FilePath}`
* Working directory: `%{CurrentDocument:Path}`


To modify elements from the GUI, open the project ./qt_creator/GUI.pro in Qt Creator. Modify the desired elements from the .ui files, then save and convert the .ui to .py with pyuic5 as described above. Then import the necessary python classes from these UI*.py files and add your own methods/actions. Do not modify the .py files inside the qt_creator folder manually, as they will be overwritten later.

# Packaging the GUI

The single executable file was produced by **PyInstaller 3.5.dev0+98fe28542**, which is supposed to fix some problems with freezing PyQt5 apps.

The GUI was packaged from a clean **LUbuntu 14.04.5** system, with pyqt5 installed from pip. This means that your Linux distro must have a **GLIBC version >= 2.19**, otherwise you might not be able to run the GUI from the executable. You can still run it by installing the necessary modules from pip:
`pip install pyqt5 pexpect` and finally running `python $CHEMFLOW_HOME/src/GUI/GUI.py`
