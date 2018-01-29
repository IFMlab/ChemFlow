#ifndef MDDIALOG_H
#define MDDIALOG_H

#include <QDialog>

namespace Ui {
class MDDialog;
}

class MDDialog : public QDialog
{
    Q_OBJECT

public:
    explicit MDDialog(QWidget *parent = 0);
    ~MDDialog();

private:
    Ui::MDDialog *ui;
};

#endif // MDDIALOG_H
