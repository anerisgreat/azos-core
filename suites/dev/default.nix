{...}: {
  config.flake.modules.homeManager.dev = {
    lib,
    config,
    ...
  }: {
    options.azos.suites.dev.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.suites.dev.enable {
      azos.suites.base.enable = lib.mkDefault true;
      azos.suites.editor.enable = lib.mkDefault true;
    };
  };
}
