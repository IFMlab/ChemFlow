#include "dockplantsdialog.h"
#include "ui_dockplantsdialog.h"

dockPlantsDialog::dockPlantsDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::dockPlantsDialog)
{
    ui->setupUi(this);
}

dockPlantsDialog::~dockPlantsDialog()
{
    delete ui;
}
