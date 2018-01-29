#include "mddialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MDDialog w;
    w.show();

    return a.exec();
}
