{
  description = "General-Flake-Environment";
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = inputs@{ self, nixpkgs }:
    let
      # GENERAL
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = system: nixpkgs.legacyPackages.${system};

      hls = rec {
        projectFor = system:
          let
            pkgs = nixpkgsFor system;
            haskell-pkgs = pkgs.haskellPackages;
            project = pkgs.stdenv.mkDerivation {
              name = "Haskell-Language-Server-865Binary";
              version = "1.6.1.0";
              src = pkgs.fetchurl {
                url =
                  "https://github.com/haskell/haskell-language-server/releases/download/1.6.1.0/haskell-language-server-Linux-8.6.5.gz";
                hash = "sha256-q2SWKYOqUkDL+MFS0bhu5yo74PzUZ8hcDJG1KZJ4i1I=";
              };
              nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.gzip ];
              buildInputs = [ ];
              sourceRoot = ".";
              unpackPhase = ''
                gunzip -c $src > haskell-language-server-Linux-8.6.5
              '';
              installPhase = ''
                runHook preInstall
                install -m755 -D haskell-language-server-Linux-8.6.5 $out/bin/haskell-language-server
                runHook postInstall
              '';
            };
          in project;
      };
      hls-shell = rec {
        shellFor = system:
          let
            pkgs = nixpkgsFor system;
            project = self.hls.${system};
            shell = pkgs.mkShell {
              buildInputs = [ project ];
              shellHook = ''
                export PATH=$PATH:${project}/bin
              '';
            };
          in shell;
      };
    in {
      hls = perSystem (system: (hls.projectFor system));
      hls-shell = perSystem (system: (hls-shell.shellFor system));
      devShells = perSystem (system: { default = self.hls-shell.${system}; });
      packages = perSystem (system: { default = self.hls.${system}; });
    };
}

