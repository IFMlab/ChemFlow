#include "rescoremmpbsadialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    rescoreMmpbsaDialog w;
    w.show();

    return a.exec();
}
