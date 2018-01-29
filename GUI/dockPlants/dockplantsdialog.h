#ifndef DOCKPLANTSDIALOG_H
#define DOCKPLANTSDIALOG_H

#include <QDialog>

namespace Ui {
class dockPlantsDialog;
}

class dockPlantsDialog : public QDialog
{
    Q_OBJECT

public:
    explicit dockPlantsDialog(QWidget *parent = 0);
    ~dockPlantsDialog();

private:
    Ui::dockPlantsDialog *ui;
};

#endif // DOCKPLANTSDIALOG_H
