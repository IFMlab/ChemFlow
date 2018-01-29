#include "runslurmdialog.h"
#include "ui_runslurmdialog.h"

RunSlurmDialog::RunSlurmDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::RunSlurmDialog)
{
    ui->setupUi(this);
}

RunSlurmDialog::~RunSlurmDialog()
{
    delete ui;
}
