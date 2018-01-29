#include "dockvinadialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    dockVinaDialog w;
    w.show();

    return a.exec();
}
