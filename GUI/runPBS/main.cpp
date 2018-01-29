#include "runpbsdialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    RunPBSDialog w;
    w.show();

    return a.exec();
}
