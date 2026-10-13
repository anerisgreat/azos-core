{...}: {
  config.flake.modules.homeManager.dev = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.kubectl.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.kubectl.enable {
      home.packages = with pkgs; [kubectl kubernetes-helm velero];
    };
  };
}
