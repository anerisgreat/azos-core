{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-exwm";
  version = "0.1.8";
  src = ./config.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base
    pkgs.azos-emacs-station

    exwm
    exwm-edit
    desktop-environment
    bluetooth
    pulseaudio-control
  ];
}
