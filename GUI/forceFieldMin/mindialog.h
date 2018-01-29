#ifndef MINDIALOG_H
#define MINDIALOG_H

#include <QDialog>

namespace Ui {
class minDialog;
}

class minDialog : public QDialog
{
    Q_OBJECT

public:
    explicit minDialog(QWidget *parent = 0);
    ~minDialog();

private:
    Ui::minDialog *ui;
};

#endif // MINDIALOG_H
