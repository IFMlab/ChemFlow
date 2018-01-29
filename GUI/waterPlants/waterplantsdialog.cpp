#include "waterplantsdialog.h"
#include "ui_waterplantsdialog.h"

waterPlantsDialog::waterPlantsDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::waterPlantsDialog)
{
    ui->setupUi(this);
}

waterPlantsDialog::~waterPlantsDialog()
{
    delete ui;
}
