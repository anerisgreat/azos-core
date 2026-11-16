# Mermaid diagrams in markdown: mermaid-cli (mmdc) renders ```mermaid blocks
# to SVG, which emacs/config.org overlays onto the buffer (M-x azos/mermaid-toggle).
{...}: {
  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.mermaid.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = "Inline Mermaid diagram previews in markdown (mermaid-cli pulls in Chromium).";
    };

    config = lib.mkIf config.azos.mermaid.enable {
      home.packages = [pkgs.mermaid-cli];
      azos.emacs.pkgs = [pkgs.azos-emacs-mermaid];
      azos.emacs.enabledSuites = ["azos-emacs-mermaid"];
    };
  };
}
