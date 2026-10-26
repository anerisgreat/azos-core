{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.git-config;

    # git credential helper protocol: on `get`, git writes key=value lines
    # (protocol, host, path, ...) to stdin and reads username/password back.
    # Only `get` is meaningful -- the password manager stays the source of
    # truth, so `store`/`erase` are no-ops.
    credentialHelper = pkgs.writeShellApplication {
      name = "azos-git-credential";
      text = ''
        [ "''${1:-}" = "get" ] || exit 0
        host=""
        while IFS='=' read -r key value; do
          [ -z "$key" ] && break
          [ "$key" = "host" ] && host=$value
        done
        case "$host" in
        ${lib.concatStrings (lib.mapAttrsToList (host: entry: ''
            ${lib.escapeShellArg host}) entry=${lib.escapeShellArg entry} ;;
          '')
          cfg.credentials)}
        *) exit 0 ;;
        esac
        if username=$(azos-password-get "$entry" username 2>/dev/null); then
          printf 'username=%s\n' "$username"
        fi
        printf 'password=%s\n' "$(azos-password-get "$entry")"
      '';
    };
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
      credentials = lib.mkOption {
        default = {};
        example = {"git.example.com" = "example.com";};
        type = lib.types.attrsOf lib.types.str;
        description = ''
          Map of git host -> password-manager entry. When non-empty, installs
          azos-git-credential as git's credential helper; it answers through
          azos-password-get, so it works with whichever
          azos.password-manager backend is enabled. The entry's "password"
          field is used, and its "username" field if present.
        '';
      };
      passCredentialHelper = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Use pass-git-helper (via `pass`) as git's credential helper.
            Prefer `credentials`, which works with any password manager.
          '';
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

      (lib.mkIf (cfg.credentials != {}) {
        assertions = [
          {
            assertion = !cfg.passCredentialHelper.enable;
            message = "azos.git-config: use either `credentials` or `passCredentialHelper`, not both.";
          }
        ];
        home.packages = [credentialHelper];
        programs.git.settings.credential.helper = "${credentialHelper}/bin/azos-git-credential";
      })

      (lib.mkIf cfg.passCredentialHelper.enable {
        home.packages = [pkgs.pass-git-helper];
        programs.git.settings.credential.helper = "!pass-git-helper $@";
        home.file.".config/pass-git-helper/git-pass-mapping.ini".text = cfg.passCredentialHelper.mapping;
      })
    ]);
  };
}
