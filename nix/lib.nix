# Builds the webview_app library
{ pkgs, common, src }:

let
  cmakeFlags = common.cmakeFlags ++ [ "-DCMAKE_BUILD_TYPE=Release" ];
in
pkgs.stdenv.mkDerivation {
  pname = common.pname;
  version = common.version;
  
  inherit src cmakeFlags;
  nativeBuildInputs = common.nativeBuildInputs;
  
  buildInputs = common.buildInputs;

  inherit (common) env meta;
    
  configurePhase = ''
    runHook preConfigure
    
    echo "Configuring logos-webview-app..."
    cmake -S . -B build \
      ${pkgs.lib.concatStringsSep " " cmakeFlags}
    
    runHook postConfigure
  '';
  
  buildPhase = ''
    runHook preBuild
    
    cmake --build build
    echo "Logos webview app plugin built successfully!"
    
    runHook postBuild
  '';
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib
    
    if [ -f "build/webview_app.dylib" ]; then
      cp build/webview_app.dylib $out/lib/
    elif [ -f "build/webview_app.so" ]; then
      cp build/webview_app.so $out/lib/
    else
      echo "Error: No webview_app library file found"
      exit 1
    fi
    
    runHook postInstall
  '';
}
