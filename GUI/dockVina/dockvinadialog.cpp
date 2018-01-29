#include "dockvinadialog.h"
#include "ui_dockvinadialog.h"

dockVinaDialog::dockVinaDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::dockVinaDialog)
{
    ui->setupUi(this);
}

dockVinaDialog::~dockVinaDialog()
{
    delete ui;
}
