# Spoken Claude Code replies with Kokoro, a local text-to-speech model.
# /speak turns them on for one session (/speak off turns them off). While
# on, a UserPromptSubmit hook adds speaking-style instructions to each
# prompt and silences the previous reply, and a Stop hook speaks the reply
# through the azos-speak user service, which keeps the model loaded and
# exits after half an hour idle.
{...}: {
  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.claude.speak;
    hf = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/f3ff3571791e39611d31c381e3a41a3af07b4987";
    model = pkgs.linkFarm "kokoro-82m" {
      "config.json" = pkgs.fetchurl {
        url = "${hf}/config.json";
        hash = "sha256-WrsB4kA7ByvwPQT94WBEPiCdeg2tSaQjvhUZa5tDwX8=";
      };
      "kokoro-v1_0.pth" = pkgs.fetchurl {
        url = "${hf}/kokoro-v1_0.pth";
        hash = "sha256-SW26EY0aWPXz2y78iNvcIW4Eg/yJ/m5H7h8sU/GK0eQ=";
      };
      "af_heart.pt" = pkgs.fetchurl {
        url = "${hf}/voices/af_heart.pt";
        hash = "sha256-CrVwm4/6sZv9hJzRHZj3W2CvdzMlOtDWexI4KhAstP8=";
      };
    };
    python = pkgs.python3.withPackages (ps: [
      ps.kokoro
      ps.soundfile
      # misaki's English G2P loads this; it would otherwise try pip.
      ps.spacy-models.en_core_web_sm
    ]);
    style = pkgs.writeText "azos-speak-style.md" ''
      Spoken replies are on: your reply to this prompt will be read aloud by
      text-to-speech. Write it for listening:
      - Lead with the answer or the outcome. Keep it short, usually two to
        five plain sentences.
      - Use quick, conversational language and simple sentences.
      - Leave out detail, caveats and background unless the user asks;
        offer a follow-up instead.
      - No tables, code blocks, long lists, file paths, URLs or symbols that
        don't read well aloud. Code blocks are skipped when read.
      - Do the work as thoroughly as usual; only the reply is condensed.
      - Interim replies, status updates in the middle of doing work, should
        be shorter still, only up to about 10 seconds of speech.
    '';
    client = pkgs.writers.writePython3Bin "azos-speak" {flakeIgnore = ["E501"];} (
      builtins.replaceStrings ["@styleFile@" "@systemctl@"] ["${style}" "${pkgs.systemd}/bin/systemctl"]
      (builtins.readFile ./client.py)
    );
    skill = pkgs.writeText "speak.md" ''
      Turn spoken replies (Kokoro text-to-speech) on or off for this Claude Code session.

      Arguments: $ARGUMENTS

      ## Steps
      1. If the arguments are `off`, run `azos-speak off`; otherwise run `azos-speak on`.
      2. Confirm the new state in one short sentence.

      While spoken replies are on, a hook adds these instructions to every
      prompt. Follow them from your confirmation on:

      ${builtins.readFile style}
    '';
  in {
    options.azos.claude.speak.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = ''
        The /speak skill: spoken Claude Code replies through Kokoro, run
        locally on the CPU. Pulls in PyTorch and the ~330 MB model.
      '';
    };

    config = lib.mkIf config.azos.claude.enable (lib.mkMerge [
      (lib.mkIf cfg.enable {
        home.packages = [client];
        azos.claude.globalSkills.speak = skill;

        systemd.user.services.azos-speak = {
          Unit.Description = "Kokoro text-to-speech for spoken Claude Code replies";
          Service = {
            ExecStart = "${python}/bin/python3 -I ${./server.py} ${model} %t/azos-speak/server.sock ${pkgs.pipewire}/bin/pw-play";
            Environment = ["HF_HUB_OFFLINE=1"];
            Restart = "on-failure";
          };
        };
      })

      {
        # Always runs with Claude enabled, so turning speak off removes them.
        home.activation.configureSpeakHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
          SETTINGS_JSON="$HOME/.claude/settings.json"
          [ -f "$SETTINGS_JSON" ] || echo '{}' > "$SETTINGS_JSON"
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq \
            --arg cmd "${client}/bin/azos-speak hook" \
            --argjson enable ${lib.boolToString cfg.enable} \
            '
            def ours: any(.hooks[]?; (.command // "") | contains("azos-speak"));
            reduce ("Stop", "UserPromptSubmit", "SessionEnd") as $event (.;
              .hooks[$event] = (((.hooks[$event] // []) | map(select(ours | not)))
                + (if $enable then [{hooks: [{type: "command", command: $cmd}]}] else [] end))
              | if .hooks[$event] == [] then del(.hooks[$event]) else . end)
            | .permissions.allow = (((.permissions.allow // [])
                - ["Bash(azos-speak on)", "Bash(azos-speak off)"])
                + (if $enable then ["Bash(azos-speak on)", "Bash(azos-speak off)"] else [] end))
            ' "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
        '';
      }
    ]);
  };
}
