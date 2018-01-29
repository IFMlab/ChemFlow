#ifndef RESCOREPLANTSDIALOG_H
#define RESCOREPLANTSDIALOG_H

#include <QDialog>

namespace Ui {
class rescorePlantsDialog;
}

class rescorePlantsDialog : public QDialog
{
    Q_OBJECT

public:
    explicit rescorePlantsDialog(QWidget *parent = 0);
    ~rescorePlantsDialog();

private:
    Ui::rescorePlantsDialog *ui;
};

#endif // RESCOREPLANTSDIALOG_H
