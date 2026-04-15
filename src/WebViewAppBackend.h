#pragma once

#include "rep_webview_app_source.h"
#include "logos_api.h"

#include <QObject>
#include <QString>
#include <QUrl>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>

class LogosAPIClient;

class WebViewAppBackend : public WebViewAppSimpleSource
{
    Q_OBJECT

public:
    explicit WebViewAppBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~WebViewAppBackend() override;

public slots:
    void loadUrl(QUrl url) override;
    void loadHtmlContent(QString html) override;
    void runJavaScript(QString script) override;
    void handleLogosRequest(QString moduleName, QString methodName,
                            QVariantList args, int requestId) override;

private:
    LogosAPI* m_logosAPI;
};
