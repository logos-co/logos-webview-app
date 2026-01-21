# Common build configuration for logos-webview-app
{ pkgs, logosSdk, logosLiblogos }:

{
  pname = "logos-webview-app";
  version = "1.0.0";
  
  # Common native build inputs
  nativeBuildInputs = [ 
    pkgs.cmake 
    pkgs.ninja 
    pkgs.pkg-config
    pkgs.qt6.wrapQtAppsHook
  ];
  
  # Common runtime dependencies
  buildInputs = [ 
    pkgs.qt6.qtbase 
    pkgs.qt6.qtremoteobjects
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtwebview
    pkgs.zstd
    pkgs.krb5
    pkgs.abseil-cpp
    pkgs.zlib
    pkgs.icu
  ] ++ (
    if pkgs.stdenv.isLinux then
      # Linux also needs WebKitGTK as the backend for QtWebView
      [ (pkgs.webkitgtk_4_1 or pkgs.webkitgtk_4_0 or pkgs.webkitgtk) ]
    else
      []
  );
  
  # Common CMake flags
  cmakeFlags = [ 
    "-GNinja"
    "-DLOGOS_CPP_SDK_ROOT=${logosSdk}"
    "-DLOGOS_LIBLOGOS_ROOT=${logosLiblogos}"
  ];
  
  # Environment variables
  env = {
    LOGOS_CPP_SDK_ROOT = "${logosSdk}";
    LOGOS_LIBLOGOS_ROOT = "${logosLiblogos}";
  };
  
  # Metadata
  meta = with pkgs.lib; {
    description = "Logos WebView App Plugin";
    platforms = platforms.unix;
  };
}
