#ifndef WEBVIEW_APP_INTERFACE_H
#define WEBVIEW_APP_INTERFACE_H

#include <QObject>
#include <QString>
#include "interface.h"

class WebViewAppInterface : public PluginInterface
{
public:
    virtual ~WebViewAppInterface() = default;
};

#define WebViewAppInterface_iid "org.logos.WebViewAppInterface"
Q_DECLARE_INTERFACE(WebViewAppInterface, WebViewAppInterface_iid)

#endif
