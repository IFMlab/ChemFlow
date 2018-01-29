#ifndef DOCKVINADIALOG_H
#define DOCKVINADIALOG_H

#include <QDialog>

namespace Ui {
class dockVinaDialog;
}

class dockVinaDialog : public QDialog
{
    Q_OBJECT

public:
    explicit dockVinaDialog(QWidget *parent = 0);
    ~dockVinaDialog();

private:
    Ui::dockVinaDialog *ui;
};

#endif // DOCKVINADIALOG_H
