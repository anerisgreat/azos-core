{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.encryption;
  in {
    options.azos.encryption = {
      enable = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = ''
          Base GPG agent setup: programs.gpg, gpg-agent with pinentry-emacs
          and ssh support, and the EXWM-aware INSIDE_EMACS wiring pinentry
          needs. YubiKey tooling, browserpass, and GPG-as-SSH-key are each
          independently toggleable on top of this. The password store
          itself lives in azos.password-manager.
        '';
      };

      sshSupport = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = ''
          Run gpg-agent as the SSH agent (sets SSH_AUTH_SOCK). Turn off when
          another agent should own SSH_AUTH_SOCK, e.g. 1Password's SSH agent
          or the desktop's keyring.
        '';
      };

      yubikey.enable = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = "Install yubikey-personalization for hardware-key workflows.";
      };

      browserpass = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
        browsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["chromium"];
        };
      };

      gpgSsh = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = "Expose a GPG subkey as an SSH key via gpg-agent's ssh support.";
        };
        keygrip = lib.mkOption {
          type = lib.types.str;
          description = "Keygrip of the GPG subkey to expose, written to ~/.gnupg/sshcontrol.";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "Corresponding SSH public key, written to ~/.ssh/gpg-as-ssh.pub for convenience.";
        };
        extraSshConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Extra lines appended to ~/.ssh/config, after the IdentityAgent line this module manages.";
        };
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        programs.gpg.enable = true;
        services.gpg-agent = {
          enable = true;
          enableSshSupport = cfg.sshSupport;
          grabKeyboardAndMouse = false;
          pinentry.package = pkgs.pinentry-emacs;
          extraConfig = ''
            allow-emacs-pinentry
            allow-loopback-pinentry
          '';
        };

        # pinentry-emacs needs INSIDE_EMACS set, but NOT on gpg-agent itself:
        # gpg-agent calls gnupg_unsetenv("INSIDE_EMACS") on its own process at
        # startup (agent/gpg-agent.c, both supervised and daemon mode) -- by
        # design, it expects this to arrive per-connection from the CLIENT,
        # not statically from its own daemon environment. Each gpg/git
        # invocation reads INSIDE_EMACS from its own env and forwards it to
        # gpg-agent via "OPTION putenv=INSIDE_EMACS=..." (common/asshelp.c:
        # send_pinentry_environment); gpg-agent stores that per-session and
        # copies it into the forked pinentry's actual env for that one
        # request (agent/call-pinentry.c:atfork_core). So the var has to be
        # set on whatever shell/process runs git or gpg -- a prior attempt
        # at this set it on gpg-agent.service's systemd Environment instead,
        # which gpg-agent silently discards before it can ever be read.
        #
        # Only safe to set globally when Emacs is structurally guaranteed to
        # be up and responsive -- i.e. under EXWM, where Emacs *is* the
        # window manager. Elsewhere Emacs may not be running (fine: the
        # loopback socket connect fails instantly, same fast fallback as
        # today) or may be running but transiently busy (not fine: pinentry
        # then blocks on the Assuan handshake for up to its 60s timeout
        # before falling back, which is strictly worse than today's instant
        # failure).
        home.sessionVariables = lib.mkIf config.azos.suites.exwm.enable {
          INSIDE_EMACS = "t";
        };

        # home-manager creates ~/.gnupg (via the files above) with the default
        # umask, which can leave it group/other-readable. gpg refuses to trust
        # a homedir like that and prints an "unsafe permissions" warning on
        # every invocation, which pollutes anything that captures gpg/pass
        # output (e.g. shell-command-to-string). Enforce 700 on every switch.
        home.activation.gnupgPerms = lib.hm.dag.entryAfter ["writeBoundary"] ''
          $DRY_RUN_CMD chmod 700 "$HOME/.gnupg"
        '';
      }

      (lib.mkIf cfg.yubikey.enable {
        home.packages = [pkgs.yubikey-personalization];
      })

      (lib.mkIf cfg.browserpass.enable {
        programs.browserpass = {
          enable = true;
          browsers = cfg.browserpass.browsers;
        };
      })

      (lib.mkIf cfg.gpgSsh.enable {
        assertions = [
          {
            assertion = cfg.sshSupport;
            message = "azos.encryption.gpgSsh needs azos.encryption.sshSupport (gpg-agent serves the SSH socket).";
          }
        ];
        home.file.".ssh/config".text =
          ''
            IdentityAgent ''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh
          ''
          + cfg.gpgSsh.extraSshConfig;
        home.file.".ssh/gpg-as-ssh.pub".text = cfg.gpgSsh.publicKey;
        home.file.".gnupg/sshcontrol".text = cfg.gpgSsh.keygrip;
      })
    ]);
  };
}
