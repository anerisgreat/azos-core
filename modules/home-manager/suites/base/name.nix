#https://xeiaso.net/talks/asg-2023-nixos/ example
{ lib, config, pkgs, ... }:{
  home.file."name.txt".text = ''${config.azos.name}'';
}
