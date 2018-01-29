#include "runslurmdialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    RunSlurmDialog w;
    w.show();

    return a.exec();
}
