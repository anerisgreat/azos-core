{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.tex.enable && config.azos.suites.editor.enable;
in
{
  options.azos.tex.enable = (azos-utils.mkFeatureEnableOption {});

  options.azos.tex.pkgs = lib.mkOption{
    default = [];
    description = "List of packages for tex.";
  };

  config = lib.mkIf isEnabled {
    azos.tex.pkgs = with pkgs.texlive; [
      combined.scheme-basic
      dvisvgm
      dvipng
      wrapfig
      amsmath
      ulem
      hyperref
      capt-of

      polyglossia
      xcolor
      amsmath
      amsfonts
      braket
      hebrew-fonts
    ];

    home.packages = with pkgs; [(texlive.combine azos.tex.pkgs)];
  };

  imports = [
  ];


}
