#include "runlocallydialog.h"
#include "ui_runlocallydialog.h"

RunLocallyDialog::RunLocallyDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::RunLocallyDialog)
{
    ui->setupUi(this);
}

RunLocallyDialog::~RunLocallyDialog()
{
    delete ui;
}
