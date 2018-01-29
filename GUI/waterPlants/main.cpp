#include "waterplantsdialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    waterPlantsDialog w;
    w.show();

    return a.exec();
}
