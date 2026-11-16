# Jinja2 templates: jinja2-mode plus djlint as a flycheck checker
# (emacs/config.org shells out to djlint).
{...}: {
  config.flake.modules.homeManager.dev = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.jinja.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = "Jinja2 editing (jinja2-mode) and linting (djlint).";
    };

    config = lib.mkIf config.azos.jinja.enable {
      home.packages = [pkgs.djlint];
      azos.emacs.pkgs = [pkgs.azos-emacs-jinja];
      azos.emacs.enabledSuites = ["azos-emacs-jinja"];
    };
  };
}
