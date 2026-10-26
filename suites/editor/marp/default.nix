{...}: {
  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.marp.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
    };

    config = lib.mkIf config.azos.marp.enable {
      home.packages = with pkgs; [marp-cli];

      # The whole directory is linked, so any extra *.css theme dropped into
      # ./themes becomes available to `marp --theme-set` without further wiring.
      xdg.configFile."marp/themes".source = ./themes;
      xdg.configFile."marp/template.md".source = ./template.md;

      azos.emacs.pkgs = [pkgs.azos-emacs-marp];
      azos.emacs.enabledSuites = ["azos-emacs-marp"];
    };
  };
}
