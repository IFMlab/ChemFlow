#include "rescorevinadialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    rescoreVinaDialog w;
    w.show();

    return a.exec();
}
