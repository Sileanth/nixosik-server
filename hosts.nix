{
  kotek = {
    public = "134.98.151.178";
    private = "10.0.0.113";
    vpnIp = "10.200.0.3";
    wgPubKey = "qpDlhCbspVNSqHSchZllkj3qctJC63wabbXiMGi72zM=";
    interface = "ens3";
    arch = "x86_64-linux";
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkdcD9BVdA6VIWywEZLDyK7Xgv/NpYYFympd/qND2FT";
  };
  piesek = {
    public = "134.98.136.184";
    private = "10.0.0.36";
    vpnIp = "10.200.0.4";
    wgPubKey = "tuN0p+SvnNhb+paKh3eI616w1gga+4Hvm7uwY8z0ECc=";
    interface = "ens3";
    arch = "x86_64-linux";
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+N8Ad4KDgbSR7xrF4Tfm/eRMghRQuqXbRc7HIK3+dr";
  };
  main = {
    public = "84.235.172.161";
    private = "10.0.0.117";
    vpnIp = "10.200.0.1";
    wgPubKey = "M8rtUwJJ73SSFVBOk/Ev/UslxRNDpgqI+JCm9/kA60I=";
    interface = "enp0s6";
    arch = "aarch64-linux";
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNA+tizG0N4w5TLd0Fl5JJzo5ZlSlCXawzzut/2HZM2";
  };
  # Client metadata (not managed as a server in this flake)
  helios = {
    vpnIp = "10.200.0.2";
    wgPubKey = "zceMtaSB8qIMJaWgiSI9GPn1HgiXlzouL2Gf0A6pWGE=";
    isClient = true;
  };
}
