#ifndef RUNPBSDIALOG_H
#define RUNPBSDIALOG_H

#include <QDialog>

namespace Ui {
class RunPBSDialog;
}

class RunPBSDialog : public QDialog
{
    Q_OBJECT

public:
    explicit RunPBSDialog(QWidget *parent = 0);
    ~RunPBSDialog();

private:
    Ui::RunPBSDialog *ui;
};

#endif // RUNPBSDIALOG_H
