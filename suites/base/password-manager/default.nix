{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.password-manager;

    # Backend-agnostic entry points. Everything else in azos (git
    # credentials, mail passwordCommands, send-alert remote commands, Emacs)
    # should call these rather than `pass`/`op` directly, so switching
    # password managers is a single toggle.
    passGet = pkgs.writeShellApplication {
      name = "azos-password-get";
      runtimeInputs = with pkgs; [gnugrep gnused coreutils];
      text = ''
        if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
          cat <<EOF
        Usage: azos-password-get ENTRY [FIELD]

        Print FIELD (default: password) of password-store entry ENTRY.
        The password is line 1; any other FIELD is read from a "FIELD: value"
        line. FIELD "username" also matches "login:" and "user:" lines.
        EOF
          exit 0
        fi
        entry=$1
        field=''${2:-password}
        content=$(pass show "$entry")
        if [ "$field" = "password" ]; then
          printf '%s\n' "$content" | head -n1
          exit 0
        fi
        pattern="$field"
        if [ "$field" = "username" ]; then
          pattern="username|login|user"
        fi
        line=$(printf '%s\n' "$content" | tail -n +2 | grep -m1 -E "^($pattern):" || true)
        if [ -z "$line" ]; then
          echo "azos-password-get: no field '$field' in '$entry'" >&2
          exit 1
        fi
        printf '%s\n' "$line" | sed -E 's/^[^:]+:[[:space:]]*//'
      '';
    };

    passList = pkgs.writeShellApplication {
      name = "azos-password-list";
      runtimeInputs = with pkgs; [findutils gnused coreutils];
      text = ''
        store=''${PASSWORD_STORE_DIR:-$HOME/.password-store}
        find -L "$store" -name '*.gpg' -printf '%P\n' | sed 's/\.gpg$//' | sort
      '';
    };

    opVaultArgs = lib.optionalString (cfg.onepassword.vault != null) "--vault ${lib.escapeShellArg cfg.onepassword.vault}";

    opGet = pkgs.writeShellApplication {
      name = "azos-password-get";
      runtimeInputs = with pkgs; [coreutils];
      text = ''
        if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
          cat <<EOF
        Usage: azos-password-get ENTRY [FIELD]

        Print FIELD (default: password) of 1Password item ENTRY (title or
        id)${lib.optionalString (cfg.onepassword.vault != null) " in vault \"${cfg.onepassword.vault}\""}.
        FIELD is a 1Password field label, e.g. password, username, or a
        custom field.
        EOF
          exit 0
        fi
        exec ${cfg.onepassword.opCommand} item get "$1" ${opVaultArgs} \
          --fields "label=''${2:-password}" --reveal
      '';
    };

    opList = pkgs.writeShellApplication {
      name = "azos-password-list";
      runtimeInputs = with pkgs; [jq coreutils];
      text = ''
        ${cfg.onepassword.opCommand} item list ${opVaultArgs} --format json \
          | jq -r '.[].title' | sort
      '';
    };
  in {
    imports = [
      (lib.mkRenamedOptionModule
        ["azos" "encryption" "passwordStore" "enable"]
        ["azos" "password-manager" "pass" "enable"])
      (lib.mkRenamedOptionModule
        ["azos" "encryption" "passwordStore" "gpgKeyId"]
        ["azos" "password-manager" "pass" "gpgKeyId"])
    ];

    options.azos.password-manager = {
      pass = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Use GNU pass (password-store, GPG-encrypted) as the password
            manager. Needs azos.encryption.enable for the gpg-agent setup.
          '';
        };
        gpgKeyId = lib.mkOption {
          type = lib.types.str;
          description = "GPG key id `pass` encrypts secrets with (PASSWORD_STORE_KEY).";
        };
      };

      onepassword = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Use 1Password (via its `op` CLI) as the password manager.

            On non-NixOS hosts, install the 1Password app and CLI from
            1Password's own distro repository rather than Nix: desktop-app
            integration (unlock `op` with the app, browser extension) needs
            setgid helpers that a user-level Nix install can't provide. In
            that case leave `installCli` off and `opCommand` as "op" so the
            host's binary is used. Enable "Integrate with 1Password CLI" in
            the app's Developer settings.
          '';
        };
        installCli = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Install `op` (_1password-cli) from nixpkgs. Without the desktop
            app's setgid integration this `op` can only sign in manually
            (`eval $(op signin)`), so prefer the host package where possible.
          '';
        };
        opCommand = lib.mkOption {
          default = "op";
          example = "/usr/bin/op";
          type = lib.types.str;
          description = "Command used to invoke the 1Password CLI.";
        };
        vault = lib.mkOption {
          default = null;
          example = "Private";
          type = lib.types.nullOr lib.types.str;
          description = ''
            Vault to look entries up in. null searches all vaults the
            account can see for azos-password-get/list; Emacs auth-source
            lookups need a concrete vault and fall back to "Private".
          '';
        };
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = !(cfg.pass.enable && cfg.onepassword.enable);
            message = ''
              azos.password-manager.pass.enable and
              azos.password-manager.onepassword.enable are mutually exclusive;
              disable one of them.
            '';
          }
        ];
      }

      (lib.mkIf cfg.pass.enable {
        programs.password-store = {
          enable = true;
          settings.PASSWORD_STORE_KEY = cfg.pass.gpgKeyId;
        };
        home.packages = [passGet passList];
        # pass.el (M-x pass) for browsing/editing the store; copying goes
        # through the backend-agnostic azos/password/copy (M-o p).
        azos.emacs.pkgs = [pkgs.emacs.pkgs.pass];
        home.file.".emacs.d/extra/azos-password-manager.el".text = ''
          ;;; -*- lexical-binding: t; -*-
          ;; Generated by azos password-manager (pass backend).
          (require 'auth-source-pass)
          (auth-source-pass-enable)
        '';
      })

      (lib.mkIf cfg.onepassword.enable {
        home.packages =
          [opGet opList]
          ++ lib.optional cfg.onepassword.installCli pkgs._1password-cli;
        azos.emacs.pkgs = [pkgs.emacs.pkgs.auth-source-1password];
        home.file.".emacs.d/extra/azos-password-manager.el".text = ''
          ;;; -*- lexical-binding: t; -*-
          ;; Generated by azos password-manager (1Password backend).
          (require 'auth-source-1password)
          (setq auth-source-1password-executable ${builtins.toJSON cfg.onepassword.opCommand}
                auth-source-1password-vault ${builtins.toJSON (
            if cfg.onepassword.vault != null
            then cfg.onepassword.vault
            else "Private"
          )})
          (auth-source-1password-enable)
        '';
      })
    ];
  };
}
