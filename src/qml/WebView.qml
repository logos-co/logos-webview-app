import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebView

Item {
    id: root

    implicitWidth: 800
    implicitHeight: 600
    Layout.fillWidth: true
    Layout.fillHeight: true

    QtObject {
        id: d
        readonly property var backend: typeof logos !== "undefined" && logos ? logos.module(mod) : null
        readonly property string mod: "webview_app"
        property bool pageLoaded: false
        property bool requestDrainInFlight: false
    }

    // The logos bridge script injected into every loaded page.
    // Sets up window.logos proxy, outbox drain, and message listener.
    readonly property string bridgeScript: [
        "(function() {",
        "if (typeof window.logos !== 'undefined') return;",
        "var requestIdCounter = 0;",
        "var pendingRequests = new Map();",
        "var eventListeners = new Map();",
        "var pluginCache = new Map();",
        "var qtOutbox = Array.isArray(window.qtOutbox) ? window.qtOutbox : [];",
        "window.qtOutbox = qtOutbox;",
        "var drainOutbox = function() { if (!qtOutbox.length) return []; var batch = qtOutbox.slice(); qtOutbox.length = 0; return batch; };",
        "function sendRequest(moduleName, methodName, args) {",
        "  return new Promise(function(resolve, reject) {",
        "    var requestId = ++requestIdCounter;",
        "    pendingRequests.set(requestId, { resolve: resolve, reject: reject });",
        "    qtOutbox.push({ type: 'logos_request', requestId: requestId, module: moduleName, method: methodName, args: Array.isArray(args) ? args : [] });",
        "    setTimeout(function() { if (pendingRequests.has(requestId)) { pendingRequests.delete(requestId); reject(new Error('Request timeout')); } }, 30000);",
        "  });",
        "}",
        "window.addEventListener('message', function(event) {",
        "  var data = event.data;",
        "  if (!data) return;",
        "  if (data.type === 'logos_response') {",
        "    var promise = pendingRequests.get(data.requestId);",
        "    if (promise) { pendingRequests.delete(data.requestId); if (data.error) { promise.reject(new Error(data.error)); } else { promise.resolve(data.result); } }",
        "  } else if (data.type === 'logos_event') {",
        "    var listeners = eventListeners.get(data.eventName);",
        "    if (listeners) { listeners.forEach(function(cb) { try { cb(data.data); } catch(e) { console.error(e); } }); }",
        "  }",
        "});",
        "function getPluginProxy(name) {",
        "  if (pluginCache.has(name)) return pluginCache.get(name);",
        "  var proxy = new Proxy({}, { get: function(_target, prop) { if (prop === 'then') return undefined; if (typeof prop !== 'string') return undefined; return function() { return sendRequest(name, prop, Array.from(arguments)); }; } });",
        "  pluginCache.set(name, proxy);",
        "  return proxy;",
        "}",
        "var logosRoot = {",
        "  on: function(eventName, callback) { if (!eventListeners.has(eventName)) { eventListeners.set(eventName, []); } eventListeners.get(eventName).push(callback); },",
        "  removeListener: function(eventName, callback) { var listeners = eventListeners.get(eventName); if (listeners) { var idx = listeners.indexOf(callback); if (idx > -1) listeners.splice(idx, 1); } }",
        "};",
        "window.logos = new Proxy(logosRoot, { get: function(target, prop) { if (prop in target) return target[prop]; if (typeof prop !== 'string') return undefined; return getPluginProxy(prop); } });",
        "window.__logosBridge = { drain: drainOutbox };",
        "window._qtDrain = drainOutbox;",
        "window.dispatchEvent(new Event('logos#initialized'));",
        "})();"
    ].join("\n")

    // Demo HTML page for the bridge
    readonly property string localHtml: '<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>Logos Bridge Demo</title>'
        + '<style>*{box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;max-width:800px;margin:40px auto;padding:20px;background:linear-gradient(135deg,#667eea,#764ba2);min-height:100vh}'
        + '.container{background:#fff;padding:30px;border-radius:16px;box-shadow:0 10px 40px rgba(0,0,0,.2)}h1{color:#333;text-align:center}button{background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;border:none;padding:14px 28px;font-size:16px;border-radius:8px;cursor:pointer;display:block;margin:12px auto;min-width:280px}button:disabled{background:#ccc;cursor:not-allowed}'
        + 'input[type=text]{width:100%;padding:12px;border:1px solid #ddd;border-radius:8px;font-size:15px}.section{margin:25px 0;padding:20px;background:#f8f9fa;border-radius:12px}.section h3{margin-top:0;color:#495057;font-size:14px;text-transform:uppercase;letter-spacing:1px}'
        + '#eventLog{background:#1a1a2e;color:#eee;padding:15px;border-radius:8px;max-height:200px;overflow-y:auto;font-family:Monaco,Menlo,monospace;font-size:12px}.log-entry{padding:6px 10px;margin:4px 0;border-radius:4px;background:rgba(255,255,255,.1)}.log-entry.success{border-left:3px solid #28a745}.log-entry.event{border-left:3px solid #17a2b8}.log-entry.error{border-left:3px solid #dc3545}'
        + '.status-bar{text-align:center;padding:12px;border-radius:8px;margin-bottom:20px}.status-waiting{background:#fff3cd;color:#856404;border:1px solid #ffc107}.status-ready{background:#d4edda;color:#155724;border:1px solid #28a745}'
        + '.field-row{display:flex;gap:10px;flex-wrap:wrap;align-items:center}.field-row button{margin:0;min-width:180px}.response-text{text-align:center;color:#333;margin-top:10px}</style></head>'
        + '<body><div class="container"><h1>Logos Bridge Demo</h1>'
        + '<div id="status" class="status-bar status-waiting">Waiting for logos bridge...</div>'
        + '<div class="section"><h3>WebApp to Qt Communication</h3><button id="changeQtLabelButton" onclick="changeQtLabel()" disabled>Change Qt Label</button></div>'
        + '<div class="section"><h3>WebApp to Chat Module</h3><button id="joinChatButton" onclick="joinChat()" disabled>Join chat channel</button></div>'
        + '<div class="section"><h3>Send Message</h3><div class="field-row"><input id="chatMessageInput" type="text" placeholder="Type a message"><button id="sendChatButton" onclick="sendChatMessage()" disabled>Send</button></div><p id="chatSendStatus" class="response-text">No message sent yet.</p></div>'
        + '<div class="section"><h3>Package Manager testPluginCall</h3><div class="field-row"><input id="pluginInput" type="text" placeholder="Enter value"><button id="pluginCallButton" onclick="callTestPlugin()" disabled>Call testPluginCall</button></div><p id="pluginResponse" class="response-text">Waiting for input...</p></div>'
        + '<div class="section"><h3>Event Log (Qt to WebApp)</h3><div id="eventLog"><div class="log-entry">Waiting for events...</div></div></div>'
        + '</div><script>'
        + 'var logosReady=false;'
        + 'function log(m,t){t=t||"success";var l=document.getElementById("eventLog");var e=document.createElement("div");e.className="log-entry "+t;e.innerHTML="<span style=\\"color:#888;font-size:10px\\">"+new Date().toLocaleTimeString()+"</span> "+m;l.appendChild(e);l.scrollTop=l.scrollHeight;while(l.children.length>15)l.removeChild(l.firstChild)}'
        + 'function checkLogosBridge(){if(typeof window.logos!=="undefined"){logosReady=true;var s=document.getElementById("status");s.textContent="Logos bridge ready!";s.className="status-bar status-ready";document.getElementById("changeQtLabelButton").disabled=false;document.getElementById("joinChatButton").disabled=false;document.getElementById("pluginCallButton").disabled=false;document.getElementById("sendChatButton").disabled=false;window.logos.on("qtButtonClicked",function(data){log("Received from Qt: "+JSON.stringify(data),"event")});log("Bridge initialized","success")}else{setTimeout(checkLogosBridge,100)}}'
        + 'window.addEventListener("logos#initialized",checkLogosBridge);checkLogosBridge();'
        + 'async function changeQtLabel(){if(!logosReady)return;var btn=document.getElementById("changeQtLabelButton");btn.disabled=true;btn.textContent="Sending...";try{var r=await window.logos.host.changeStatus("Hello from WebApp! ("+new Date().toLocaleTimeString()+")");log("Label changed: "+JSON.stringify(r),"success")}catch(e){log("Error: "+e.message,"error")}finally{btn.disabled=false;btn.textContent="Change Qt Label"}}'
        + 'async function joinChat(){if(!logosReady)return;var btn=document.getElementById("joinChatButton");btn.disabled=true;try{var r=await window.logos.chat.joinChannel("baixa-chiado");log("Joined: "+JSON.stringify(r),"success")}catch(e){log("Failed: "+e.message,"error")}finally{btn.disabled=false;btn.textContent="Join chat channel"}}'
        + 'async function sendChatMessage(){if(!logosReady)return;var i=document.getElementById("chatMessageInput");var b=document.getElementById("sendChatButton");var s=document.getElementById("chatSendStatus");var m=i.value.trim();if(!m){s.textContent="Please enter a message.";return}b.disabled=true;try{await window.logos.chat.sendMessage("baixa-chiado","webview-user",m);s.textContent="Sent!";log("Sent: "+m,"success");i.value=""}catch(e){s.textContent="Error: "+e.message;log("Failed: "+e.message,"error")}finally{b.disabled=false;b.textContent="Send"}}'
        + 'async function callTestPlugin(){if(!logosReady)return;var i=document.getElementById("pluginInput");var b=document.getElementById("pluginCallButton");var r=document.getElementById("pluginResponse");var v=i.value.trim();if(!v){r.textContent="Enter a value first.";return}b.disabled=true;try{var res=await window.logos.package_manager.testPluginCall(v);var s=(typeof res==="object")?JSON.stringify(res):String(res);r.textContent="Response: "+s;log("testPluginCall: "+s,"success")}catch(e){r.textContent="Error: "+e.message;log("Failed: "+e.message,"error")}finally{b.disabled=false;b.textContent="Call testPluginCall"}}'
        + '</script></body></html>'

    Connections {
        target: d.backend
        ignoreUnknownSignals: true

        function onLogosResponse(requestId, result, error) {
            var responseObj = {
                "type": "logos_response",
                "requestId": requestId
            };
            if (error && error.length > 0) {
                responseObj["error"] = error;
            } else {
                responseObj["result"] = result;
            }
            var json = JSON.stringify(responseObj);
            webView.runJavaScript("window.postMessage(" + json + ", '*');");
        }

        function onLogosEvent(eventName, data) {
            var eventObj = {
                "type": "logos_event",
                "eventName": eventName,
                "data": data
            };
            var json = JSON.stringify(eventObj);
            webView.runJavaScript("window.postMessage(" + json + ", '*');");
        }

        function onCurrentUrlChanged() {
            if (d.backend && d.backend.currentUrl.toString() !== webView.url.toString())
                webView.url = d.backend.currentUrl;
        }

        function onStatusChanged(text) {
            statusLabel.text = "Status: " + text;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5

            Button {
                text: "Wikipedia"
                onClicked: {
                    if (d.backend)
                        d.backend.loadUrl("https://en.wikipedia.org/wiki/Main_Page");
                    webView.url = "https://en.wikipedia.org/wiki/Main_Page";
                }
            }

            Button {
                text: "Local File"
                onClicked: {
                    console.log("Loading local HTML, length:", root.localHtml.length);
                    webView.loadHtml(root.localHtml);
                }
            }

            Button {
                text: "Send Event to WebApp"
                onClicked: {
                    var data = {
                        "message": "Hello from Qt!",
                        "timestamp": new Date().toISOString()
                    };
                    var eventObj = {
                        "type": "logos_event",
                        "eventName": "qtButtonClicked",
                        "data": data
                    };
                    var json = JSON.stringify(eventObj);
                    console.log("Sending event to webview:", json);
                    webView.runJavaScript("window.postMessage(" + json + ", '*');");
                }
            }

            Item { Layout.fillWidth: true }
        }

        Label {
            id: statusLabel
            text: "Status: Ready"
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

            onLoadingChanged: function(loadRequest) {
                console.log("WebView loading status:", loadRequest.status);
                d.pageLoaded = (loadRequest.status === WebView.LoadSucceededStatus);
                d.requestDrainInFlight = false;

                if (loadRequest.status === WebView.LoadSucceededStatus) {
                    console.log("Injecting bridge script, length:", root.bridgeScript.length);
                    webView.runJavaScript(root.bridgeScript);
                }
            }
        }
    }

    Timer {
        id: logosRequestPump
        interval: 30
        running: true
        repeat: true
        onTriggered: {
            if (!d.pageLoaded || d.requestDrainInFlight || webView.loading)
                return;

            d.requestDrainInFlight = true;
            try {
                webView.runJavaScript(
                    "(function(){ var d = (typeof _qtDrain === 'function') ? _qtDrain : (window.__logosBridge && window.__logosBridge.drain); return d ? d() : []; })();",
                    function(result) {
                        d.requestDrainInFlight = false;
                        if (!result || !result.length)
                            return;
                        for (var i = 0; i < result.length; ++i) {
                            var payload = result[i];
                            var reqId = payload.requestId || payload.id || 0;
                            var moduleName = payload.module || payload.plugin || "";
                            var methodName = payload.method || "";
                            var args = payload.args || [];
                            if (d.backend)
                                d.backend.handleLogosRequest(moduleName, methodName, args, reqId);
                        }
                    }
                );
            } catch (err) {
                d.requestDrainInFlight = false;
                console.log("logosRequestPump failed:", err);
            }
        }
    }

    Component.onCompleted: {
        webView.url = "https://en.wikipedia.org/wiki/Main_Page";
    }
}
