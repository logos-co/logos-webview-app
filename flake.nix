{
  description = "Logos WebView App Plugin";

  inputs = {
    logos-nix.url = "github:logos-co/logos-nix";
    nixpkgs.follows = "logos-nix/nixpkgs";
    logos-cpp-sdk.url = "github:logos-co/logos-cpp-sdk";
  };

  outputs = { self, nixpkgs, logos-nix, logos-cpp-sdk }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
        logosSdk = logos-cpp-sdk.packages.${system}.default;
      });
    in
    {
      packages = forAllSystems ({ pkgs, logosSdk }:
        let
          common = import ./nix/default.nix {
            inherit pkgs logosSdk;
          };
          src = ./.;
          
          lib = import ./nix/lib.nix {
            inherit pkgs common src;
          };
        in
        {
          default = lib;
        }
      );
    };
}
