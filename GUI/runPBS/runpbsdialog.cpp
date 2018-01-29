#include "runpbsdialog.h"
#include "ui_runpbsdialog.h"

RunPBSDialog::RunPBSDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::RunPBSDialog)
{
    ui->setupUi(this);
}

RunPBSDialog::~RunPBSDialog()
{
    delete ui;
}
