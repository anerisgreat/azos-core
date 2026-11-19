{
  orgTrivialBuild,
  epkgs,
  pkgs,
}: let
  # Plain SVG labels (librsvg skips mmdc's HTML ones); see config.org.
  config = pkgs.writeText "azos-mermaid.json" (builtins.toJSON {
    htmlLabels = false;
    flowchart = {
      htmlLabels = false;
      wrappingWidth = 400;
    };
    themeCSS = ".edgeLabel rect { opacity: 1; fill: white; }";
  });
in
  orgTrivialBuild {
    pname = "azos-emacs-mermaid";
    version = "0.1.0";
    src = ./config.org;
    postPatch = ''
      substituteInPlace config.org --replace-fail @mermaidConfig@ ${config}
    '';
    packageRequires = with epkgs; [
      pkgs.azos-emacs-base
    ];
  }
