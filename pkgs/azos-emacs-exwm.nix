{
  orgTrivialBuild,
  epkgs,
  pkgs
}:
orgTrivialBuild {
    pname = "azos-emacs-exwm";
    version = "0.1.6";
    src = ./elisp/azos-emacs-exwm.org;
    packageRequires = with epkgs; [
        pkgs.azos-emacs-base
        pkgs.azos-emacs-station

        exwm
        desktop-environment
        bluetooth
        pulseaudio-control
    ];
}
