#ifndef RESCOREMMPBSADIALOG_H
#define RESCOREMMPBSADIALOG_H

#include <QDialog>

namespace Ui {
class rescoreMmpbsaDialog;
}

class rescoreMmpbsaDialog : public QDialog
{
    Q_OBJECT

public:
    explicit rescoreMmpbsaDialog(QWidget *parent = 0);
    ~rescoreMmpbsaDialog();

private:
    Ui::rescoreMmpbsaDialog *ui;
};

#endif // RESCOREMMPBSADIALOG_H
