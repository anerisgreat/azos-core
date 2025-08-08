{pkgs}: let
  a = 2;
in
  pkgs.writeShellScriptBin "my-script" ''
    ATE="$(${pkgs.ddate}/bin/ddate +'the %e of %B%, %Y')"
    ${pkgs.cowsay}/bin/cowsay Hello, world! Today is $DATE.
  ''
