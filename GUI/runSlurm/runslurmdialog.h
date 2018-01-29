#ifndef RUNSLURMDIALOG_H
#define RUNSLURMDIALOG_H

#include <QDialog>

namespace Ui {
class RunSlurmDialog;
}

class RunSlurmDialog : public QDialog
{
    Q_OBJECT

public:
    explicit RunSlurmDialog(QWidget *parent = 0);
    ~RunSlurmDialog();

private:
    Ui::RunSlurmDialog *ui;
};

#endif // RUNSLURMDIALOG_H
