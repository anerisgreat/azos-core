# overlays/org-9.7.37.nix
self: super:

let
  # Helper to fetch the exact source tarball that the upstream
  # maintainer uses for the 9.7.37 release.
  orgSrc = super.fetchFromGitHub {
    owner = "emacs-straight";
    repo  = "org-mode";
    rev   = "9.7.37";                     # tag / commit for 9.7.37
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    # ^‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑-
    # You can obtain the correct hash with:
    #   nix-prefetch-url --unpack https://github.com/emacs-straight/org-mode/archive/9.7.37.tar.gz
  };
in
{
  # The `emacsPackages` set is a function, so we have to override the
  # attribute *inside* the set returned by `self.emacsPackages`.
  emacsPackages = super.emacsPackages // {
    org = super.emacsPackages.org.overrideAttrs (oldAttrs: {
      version = "9.7.37";
      src     = orgSrc;

      # If the old package performed extra patches or extra build
      # steps, you may need to carry them over.  The simplest way is to
      # keep everything else from `oldAttrs`:
      inherit (oldAttrs) nativeBuildInputs buildInputs postPatch;
    });
  };
}
