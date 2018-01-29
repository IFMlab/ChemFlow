#ifndef RUNLOCALLYDIALOG_H
#define RUNLOCALLYDIALOG_H

#include <QDialog>

namespace Ui {
class RunLocallyDialog;
}

class RunLocallyDialog : public QDialog
{
    Q_OBJECT

public:
    explicit RunLocallyDialog(QWidget *parent = 0);
    ~RunLocallyDialog();

private:
    Ui::RunLocallyDialog *ui;
};

#endif // RUNLOCALLYDIALOG_H
