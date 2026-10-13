{...}: {
  config.flake.modules.nixos.dev = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.virtualization.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.virtualization.enable {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
        };
      };
      environment.systemPackages = with pkgs; [
        qemu_kvm
        libvirt
        virt-manager
        virt-viewer
      ];
      services.spice-vdagentd.enable = true;
      networking.firewall.allowedTCPPorts = [5900 5901];
      networking.firewall.allowedUDPPorts = [5900 5901];
    };
  };
}
