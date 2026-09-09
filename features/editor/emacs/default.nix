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

      azos.claude.globalMdSections.agent-shell-math = ''
        # Inline LaTeX Math Notation

        When writing inline LaTeX math (as opposed to display/block equations),
        use `\(...\)` delimiters, not `$...$`. The agent-shell-math-renderer
        Emacs package used in this environment only recognizes `\(...\)` for
        inline math — a lone `$` is intentionally not treated as a math
        delimiter, since it is too common in prose, currency, and shell
        snippets to match safely.

        Display/block math may use either `\[...\]` or `$$...$$`; both are
        recognized.
      '';
    };
  };
}
