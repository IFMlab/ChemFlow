#include "rescoreplantsdialog.h"
#include "ui_rescoreplantsdialog.h"

rescorePlantsDialog::rescorePlantsDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::rescorePlantsDialog)
{
    ui->setupUi(this);
}

rescorePlantsDialog::~rescorePlantsDialog()
{
    delete ui;
}
