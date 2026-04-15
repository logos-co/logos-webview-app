#ifndef WEBVIEW_APP_PLUGIN_H
#define WEBVIEW_APP_PLUGIN_H

#include <QObject>
#include <QString>
#include "webview_app_interface.h"
#include "LogosViewPluginBase.h"

class LogosAPI;
class WebViewAppBackend;

class WebViewAppPlugin : public QObject,
                         public WebViewAppInterface,
                         public WebViewAppViewPluginBase
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID WebViewAppInterface_iid FILE "metadata.json")
    Q_INTERFACES(WebViewAppInterface)

public:
    explicit WebViewAppPlugin(QObject* parent = nullptr);
    ~WebViewAppPlugin() override;

    QString name()    const override { return "webview_app"; }
    QString version() const override { return "1.0.0"; }

    Q_INVOKABLE void initLogos(LogosAPI* api);

private:
    WebViewAppBackend* m_backend = nullptr;
};

#endif
