#include "mddialog.h"
#include "ui_mddialog.h"

MDDialog::MDDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::MDDialog)
{
    ui->setupUi(this);
}

MDDialog::~MDDialog()
{
    delete ui;
}
