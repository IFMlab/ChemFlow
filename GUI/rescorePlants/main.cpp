#include "rescoreplantsdialog.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    rescorePlantsDialog w;
    w.show();

    return a.exec();
}
