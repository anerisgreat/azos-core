{...}: {
  config.flake.modules.nixos.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    webpFilter = pkgs.writeShellScript "webptopdf" ''
      if [ $# -ge 6 ]; then
        INPUT="$6"
        TMPFILE=""
      else
        TMPFILE=$(mktemp /tmp/cups-webp-XXXXXX.webp)
        cat > "$TMPFILE"
        INPUT="$TMPFILE"
      fi
      TMPOUT=$(mktemp /tmp/cups-webp-XXXXXX.pdf)
      ${pkgs.imagemagick}/bin/magick "$INPUT" "$TMPOUT"
      cat "$TMPOUT"
      rm -f "$TMPOUT"
      [ -n "$TMPFILE" ] && rm -f "$TMPFILE"
    '';

    webpCupsMime = pkgs.runCommand "webp-cups-mime" {} ''
      mkdir -p $out/lib/cups/filter $out/share/cups/mime
      cp ${webpFilter} $out/lib/cups/filter/webptopdf
      chmod +x $out/lib/cups/filter/webptopdf
      echo 'image/webp webp string(0,"RIFF") string(8,"WEBP")' > $out/share/cups/mime/webp.types
      echo 'image/webp application/pdf 0 webptopdf' > $out/share/cups/mime/webp.convs
    '';
  in {
    options.azos.printing.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
    };

    options.azos.printing.username = lib.mkOption {
      type = lib.types.str;
      description = "User to add to the `lp` group so they can print.";
    };

    config = lib.mkIf config.azos.printing.enable {
      services.printing = {
        enable = true;
        drivers = [pkgs.hplip webpCupsMime];
      };

      environment.systemPackages = [pkgs.hplip];

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      users.users.${config.azos.printing.username}.extraGroups = ["lp"];
    };
  };
}
