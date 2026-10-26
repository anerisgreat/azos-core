{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.genericLinux.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = ''
        Standalone home-manager on a non-NixOS distro (e.g. Fedora with a
        user-level Nix install). Turns on home-manager's genericLinux target
        (XDG data dirs, nix.sh in the session, GPU driver integration for Nix
        GUI apps -- run the `sudo .../non-nixos-gpu-setup` command
        home-manager prints on first switch), keeps the distro's /etc/bashrc
        in interactive shells, and manages ~/.config/nix/nix.conf so flakes
        work without extra flags.
      '';
    };

    config = lib.mkIf config.azos.genericLinux.enable {
      targets.genericLinux.enable = true;

      # home-manager's ~/.bashrc replaces the distro's, which on Fedora is
      # what sources /etc/bashrc (prompt, /etc/profile.d bits, completion).
      programs.bash.bashrcExtra = ''
        if [ -f /etc/bashrc ]; then
          . /etc/bashrc
        fi
      '';

      nix = {
        package = lib.mkDefault pkgs.nix;
        settings.experimental-features = ["nix-command" "flakes"];
      };
    };
  };
}
