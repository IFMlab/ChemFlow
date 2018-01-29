#include "dockplantsdialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    dockPlantsDialog w;
    w.show();

    return a.exec();
}
