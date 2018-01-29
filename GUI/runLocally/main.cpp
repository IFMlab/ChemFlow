#include "runlocallydialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    RunLocallyDialog w;
    w.show();

    return a.exec();
}
