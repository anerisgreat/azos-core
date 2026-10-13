{...}: {
  config.flake.overlayPkgs.azos-emacs-editor = pkgs: pkgs.localEmacsPkg ./_pkg.nix;

  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.dev.enable) {
      azos.emacs.pkgs = [pkgs.azos-emacs-base];
      azos.emacs.enabledSuites = ["azos-emacs-editor"];
      azos.python.pkgs = with config.azos.python.pythonpkg.pkgs; [graphviz pygments];

      # agent-shell is installed by this package (azos-emacs-editor, see
      # _pkg.nix) -- bundle its memory backend the same way azos.claude.enable
      # bundles the claude backend, so there's nothing extra to remember to
      # turn on.
      azos.agent-memory.backends.agent-shell.enable = lib.mkDefault true;

      azos.claude.globalMdSections.agent-shell-math = ''
        # Inline LaTeX Math Notation

        When writing inline LaTeX math, use `\(...\)` delimiters,
        not `$...$`. The agent-shell-math-renderer Emacs package used in this
        environment only recognizes `\(...\)` for inline math.

        Display/block math may use either `\[...\]` or `$$...$$`;
      '';
    };
  };
}
