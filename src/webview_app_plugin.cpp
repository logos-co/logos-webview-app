#include "webview_app_plugin.h"
#include "WebViewAppBackend.h"

#include <QDebug>

WebViewAppPlugin::WebViewAppPlugin(QObject* parent)
    : QObject(parent)
{
}

WebViewAppPlugin::~WebViewAppPlugin() = default;

void WebViewAppPlugin::initLogos(LogosAPI* api)
{
    if (m_backend) return;
    m_backend = new WebViewAppBackend(api, this);
    setBackend(m_backend);
    qDebug() << "WebViewAppPlugin: backend initialized";
}
