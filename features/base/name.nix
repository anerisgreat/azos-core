{...}: {
  config.flake.modules.homeManager.base = {config, ...}: {
    home.file."name.txt".text = "${config.azos.name}";
  };
}
