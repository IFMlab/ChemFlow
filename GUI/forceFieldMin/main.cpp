#include "mindialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    minDialog w;
    w.show();

    return a.exec();
}
