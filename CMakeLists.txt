cmake_minimum_required(VERSION 3.14)
project(WebViewAppPlugin LANGUAGES CXX)

if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found. Set LOGOS_MODULE_BUILDER_ROOT.")
endif()

logos_module(
    NAME webview_app
    REP_FILE src/webview_app.rep
    SOURCES
        src/webview_app_interface.h
        src/webview_app_plugin.h
        src/webview_app_plugin.cpp
        src/WebViewAppBackend.h
        src/WebViewAppBackend.cpp
    FIND_PACKAGES
        Qt6WebView
        Qt6Quick
    LINK_LIBRARIES
        Qt6::WebView
        Qt6::Quick
)
