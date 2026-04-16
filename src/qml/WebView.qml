import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebView
import "Resources.js" as Res

Item {
    id: root

    implicitWidth: 800
    implicitHeight: 600
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ── State ─────────────────────────────────────────────────────────────
    readonly property bool tabActive: typeof isActiveTab !== "undefined" ? isActiveTab : true
    property string statusText: "Ready"
    // Bundled resources — see Resources.js for why we don't XHR sibling files.
    readonly property string bridgeScript: Res.bridgeScript
    readonly property string demoHtml: Res.localHtml
    property bool pageLoaded: false
    property bool requestDrainInFlight: false

    // ── Bridge dispatch (JS → any loaded backend module) ──────────────────
    function respondToJs(requestId, result, error) {
        var responseObj = { type: "logos_response", requestId: requestId };
        if (error) {
            responseObj.error = error;
        } else {
            responseObj.result = result;
        }
        webView.runJavaScript("window.postMessage(" + JSON.stringify(responseObj) + ", '*');");
    }

    function handleLogosRequest(moduleName, methodName, args, requestId) {
        // Host-local handlers first (no inter-module call needed)
        if (moduleName === "host" && methodName === "changeQtLabel") {
            root.statusText = String(args.length > 0 ? args[0] : "");
            respondToJs(requestId, { success: true, message: "Label updated successfully" }, null);
            return;
        }

        if (typeof logos === "undefined" || !logos) {
            respondToJs(requestId, null, "logos API not available");
            return;
        }

        // callModuleAsync delivers a JSON string to the callback.
        // On error the payload is {"error":"..."}; otherwise the bare result value.
        logos.callModuleAsync(moduleName, methodName, args, function(payload) {
            var parsed = null;
            if (typeof payload === "string" && payload.length > 0) {
                try {
                    parsed = JSON.parse(payload);
                } catch (e) {
                    respondToJs(requestId, null, "Failed to parse response: " + e);
                    return;
                }
            }
            if (parsed && typeof parsed === "object" && "error" in parsed && !("result" in parsed)) {
                respondToJs(requestId, null, String(parsed.error));
            } else {
                respondToJs(requestId, parsed, null);
            }
        });
    }

    // ── UI ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5

            Button {
                text: "Wikipedia"
                onClicked: webView.url = "https://en.wikipedia.org/wiki/Main_Page"
            }

            Button {
                text: "Local File"
                enabled: root.demoHtml.length > 0
                onClicked: webView.loadHtml(root.demoHtml)
            }

            Button {
                text: "Send Event to WebApp"
                onClicked: {
                    var eventObj = {
                        type: "logos_event",
                        eventName: "qtButtonClicked",
                        data: {
                            message: "Hello from Qt!",
                            timestamp: new Date().toISOString()
                        }
                    };
                    webView.runJavaScript("window.postMessage(" + JSON.stringify(eventObj) + ", '*');");
                }
            }

            Item { Layout.fillWidth: true }
        }

        Label {
            id: statusLabel
            text: "Status: " + root.statusText
            Layout.fillWidth: true
            padding: 5
            background: Rectangle {
                color: "#f0f0f0"
                border.color: "#ccc"
                border.width: 1
            }
        }

        WebView {
            id: webView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.tabActive
            url: "https://en.wikipedia.org/wiki/Main_Page"

            onLoadingChanged: function(loadRequest) {
                root.pageLoaded = (loadRequest.status === WebView.LoadSucceededStatus);
                root.requestDrainInFlight = false;
                if (loadRequest.status === WebView.LoadSucceededStatus
                        && root.bridgeScript.length > 0) {
                    webView.runJavaScript(root.bridgeScript);
                }
            }
        }
    }

    // ── Drain pump: JS outbox → handleLogosRequest ────────────────────────
    Timer {
        interval: 30
        running: root.tabActive && root.pageLoaded
        repeat: true
        onTriggered: {
            if (!root.pageLoaded || root.requestDrainInFlight || webView.loading)
                return;
            root.requestDrainInFlight = true;
            try {
                webView.runJavaScript(
                    "(function(){ var d = (typeof _qtDrain === 'function') ? _qtDrain : (window.__logosBridge && window.__logosBridge.drain); return d ? d() : []; })();",
                    function(result) {
                        root.requestDrainInFlight = false;
                        if (!result || !result.length) return;
                        for (var i = 0; i < result.length; ++i) {
                            var payload = result[i];
                            var reqId = payload.requestId || payload.id || 0;
                            var modName = payload.module || payload.plugin || "";
                            var methName = payload.method || "";
                            var args = payload.args || [];
                            root.handleLogosRequest(modName, methName, args, reqId);
                        }
                    }
                );
            } catch (err) {
                root.requestDrainInFlight = false;
                console.warn("WebView.qml: drain pump failed:", err);
            }
        }
    }
}
