Graphical User Interface created with Qt Creator 4.7.0

Based on Qt 5.11.1 (GCC 8.2.0, 64 bit), and PyQt 5.11.2

Converted UI style sheet to python code with pyuic5.
To do this step automatically from qtcreator: open Tools > External > Configure > Add > Add Tools, then name it accordingly and configure it as follow:
* Description: `Converts .ui to .py`
* Executable: `<your path to pyuic5>`
* Arguments: `-o UI%{CurrentDocument:FileBaseName}.py -x %{CurrentDocument:FilePath}`
* Working directory: `%{CurrentDocument:Path}`


Packaged as a single executable file with PyInstaller version 3.5.dev0+98fe28542

To modify elements from the GUI, open the project ./qt_creator/GUI.pro in Qt Creator. Modify the desired elements from the .ui files, then save and convert the .ui to .py with pyuic5, prepending the name of the output file with UI. Then import the necessary python classes from these UI*.py files and add your own methods/actions. Do not modify the .py files inside the qt_creator folder manually, as they will be overwritten later.
