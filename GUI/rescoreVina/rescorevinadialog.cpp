#include "rescorevinadialog.h"
#include "ui_rescorevinadialog.h"

rescoreVinaDialog::rescoreVinaDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::rescoreVinaDialog)
{
    ui->setupUi(this);
}

rescoreVinaDialog::~rescoreVinaDialog()
{
    delete ui;
}
