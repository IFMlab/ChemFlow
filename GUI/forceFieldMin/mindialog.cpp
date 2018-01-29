#include "mindialog.h"
#include "ui_mindialog.h"

minDialog::minDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::minDialog)
{
    ui->setupUi(this);
}

minDialog::~minDialog()
{
    delete ui;
}
