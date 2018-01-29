#ifndef RESCOREVINADIALOG_H
#define RESCOREVINADIALOG_H

#include <QDialog>

namespace Ui {
class rescoreVinaDialog;
}

class rescoreVinaDialog : public QDialog
{
    Q_OBJECT

public:
    explicit rescoreVinaDialog(QWidget *parent = 0);
    ~rescoreVinaDialog();

private:
    Ui::rescoreVinaDialog *ui;
};

#endif // RESCOREVINADIALOG_H
