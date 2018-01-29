#include "rescoremmpbsadialog.h"
#include "ui_rescoremmpbsadialog.h"

rescoreMmpbsaDialog::rescoreMmpbsaDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::rescoreMmpbsaDialog)
{
    ui->setupUi(this);
}

rescoreMmpbsaDialog::~rescoreMmpbsaDialog()
{
    delete ui;
}
