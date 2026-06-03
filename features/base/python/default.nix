{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.python.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    options.azos.python.pythonpkg = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3;
    };
    options.azos.python.pkgs = lib.mkOption {
      default = [];
      description = "List of packages for python.";
    };
    config = lib.mkIf (config.azos.python.enable && config.azos.suites.base.enable) {
      home.packages =
        [
          (config.azos.python.pythonpkg.withPackages (_python-pkgs: config.azos.python.pkgs))
        ]
        ++ lib.optionals config.azos.suites.dev.enable (with pkgs; [
          basedpyright
          ruff
        ]);
    };
  };
}
