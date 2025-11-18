self: super:
{
  emacsPackages = super.emacsPackages // {
    org = super.org.override {
        elpaBuild = args: super.elpaBuild (args // {
          version = "9.27.37";
          src = super.fetchurl {
            url = "https://elpa.gnu.org/packages/org-9.7.37.tar";
            sha256 = "HXugakRVPZ9gWvFHVDlgbrhGrcf1DQT5iJ28wHnIedk";
          };
        });
    };
    exwm = super.org.override {
        elpaBuild = args: super.elpaBuild (args // {
          version = "0.34";
          src = super.fetchurl {
            url = "https://elpa.gnu.org/packages/exwm-0.34.tar";
            sha256 = "33R9rEiis2HbZefibaLdVUcGv7Fn9HLEEcYuw1K04sI";
          };
        });
    };
  };
}
