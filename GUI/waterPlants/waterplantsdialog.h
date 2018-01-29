#ifndef WATERPLANTSDIALOG_H
#define WATERPLANTSDIALOG_H

#include <QDialog>

namespace Ui {
class waterPlantsDialog;
}

class waterPlantsDialog : public QDialog
{
    Q_OBJECT

public:
    explicit waterPlantsDialog(QWidget *parent = 0);
    ~waterPlantsDialog();

private:
    Ui::waterPlantsDialog *ui;
};

#endif // WATERPLANTSDIALOG_H
