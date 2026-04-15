#include "WebViewAppBackend.h"
#include "logos_api_client.h"

#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QDateTime>
#include <QtWebView/QtWebView>

WebViewAppBackend::WebViewAppBackend(LogosAPI* logosAPI, QObject* parent)
    : WebViewAppSimpleSource(parent)
    , m_logosAPI(logosAPI)
{
    QtWebView::initialize();
    setStatusText(QStringLiteral("Ready"));
    setReady(false);
}

WebViewAppBackend::~WebViewAppBackend() = default;

void WebViewAppBackend::loadUrl(QUrl url)
{
    qDebug() << "WebViewAppBackend::loadUrl" << url;
    setCurrentUrl(url);
    setStatusText(QStringLiteral("Loading: ") + url.toString());
}

void WebViewAppBackend::loadHtmlContent(QString html)
{
    Q_UNUSED(html)
    qDebug() << "WebViewAppBackend::loadHtmlContent length:" << html.length();
    setStatusText(QStringLiteral("Loading local HTML"));
}

void WebViewAppBackend::runJavaScript(QString script)
{
    Q_UNUSED(script)
    qDebug() << "WebViewAppBackend::runJavaScript";
}

void WebViewAppBackend::handleLogosRequest(QString moduleName, QString methodName,
                                           QVariantList args, int requestId)
{
    qDebug() << "WebViewAppBackend: logos request:" << moduleName << methodName << args;

    // Special "host" module for local operations
    if (moduleName == QStringLiteral("host") && methodName == QStringLiteral("changeStatus")) {
        const QString text = args.value(0).toString();
        setStatusText(text);
        QVariantMap result;
        result[QStringLiteral("success")] = true;
        result[QStringLiteral("message")] = QStringLiteral("Status updated");
        emit logosResponse(requestId, QVariant(result), QString());
        return;
    }

    if (!m_logosAPI) {
        emit logosResponse(requestId, QVariant(),
                           QStringLiteral("LogosAPI not available"));
        return;
    }

    LogosAPIClient* client = m_logosAPI->getClient(moduleName);
    if (!client) {
        emit logosResponse(requestId, QVariant(),
                           QStringLiteral("Unknown module: ") + moduleName);
        return;
    }

    QVariant response = client->invokeRemoteMethod(moduleName, methodName, args);
    if (!response.isValid()) {
        emit logosResponse(requestId, QVariant(),
                           QStringLiteral("Empty response from ") + moduleName +
                           QStringLiteral(".") + methodName);
        return;
    }

    emit logosResponse(requestId, response, QString());
}
