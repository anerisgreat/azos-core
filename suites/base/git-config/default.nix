{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.git-config;
  in {
    options.azos.git-config = {
      enable = lib.mkOption {
        default = true;
        type = lib.types.bool;
      };
      userName = lib.mkOption {
        type = lib.types.str;
        description = "Value for git's user.name.";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        description = "Value for git's user.email.";
      };
      signing = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
        key = lib.mkOption {
          type = lib.types.str;
          description = "GPG key id git signs commits with.";
        };
      };
      passCredentialHelper = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = "Use pass-git-helper (via `pass`) as git's credential helper.";
        };
        mapping = lib.mkOption {
          type = lib.types.lines;
          description = ''
            Contents of ~/.config/pass-git-helper/git-pass-mapping.ini -- maps
            git host patterns to pass entries. See pass-git-helper's docs for
            the [section]/target format.
          '';
        };
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        home.packages = [pkgs.unzip];
        programs.git = {
          enable = true;
          settings.user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
        };
      }

      (lib.mkIf cfg.signing.enable {
        programs.git.signing = {
          key = cfg.signing.key;
          signByDefault = true;
        };
      })

      (lib.mkIf cfg.passCredentialHelper.enable {
        home.packages = [pkgs.pass-git-helper];
        programs.git.settings.credential.helper = "!pass-git-helper $@";
        home.file.".config/pass-git-helper/git-pass-mapping.ini".text = cfg.passCredentialHelper.mapping;
      })
    ]);
  };
}
