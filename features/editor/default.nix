{...}: {
  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.suites.editor.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.suites.editor.enable {
      home.packages = with pkgs; [opencode azos-tex pandoc graphviz harper];
    };
  };
}
