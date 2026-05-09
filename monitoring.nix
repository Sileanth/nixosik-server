{ config, lib, pkgs, name, hosts, ... }:

let
  isMain = name == "main";
  
  # Scrape targets for Prometheus
  # Filter only servers (excluding clients like helios)
  serverHosts = lib.filterAttrs (_: h: !(h.isClient or false)) hosts;
  scrapeTargets = lib.mapAttrsToList (n: h: "${h.vpnIp}:9100") serverHosts;

  # Basic Dashboard JSON for CPU and RAM
  dashboard = {
    annotations.list = [ ];
    editable = true;
    fiscalYearStartMonth = 0;
    graphTooltip = 0;
    links = [ ];
    liveNow = false;
    panels = [
      {
        title = "CPU Usage";
        type = "timeseries";
        gridPos = { h = 8; w = 12; x = 0; y = 0; };
        datasource = { type = "prometheus"; uid = "prometheus"; };
        targets = [
          {
            expr = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)";
            legendFormat = "{{instance}}";
          }
        ];
        fieldConfig.defaults = {
          unit = "percent";
          min = 0;
          max = 100;
        };
      }
      {
        title = "Memory Usage";
        type = "timeseries";
        gridPos = { h = 8; w = 12; x = 12; y = 0; };
        datasource = { type = "prometheus"; uid = "prometheus"; };
        targets = [
          {
            expr = "100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)";
            legendFormat = "{{instance}}";
          }
        ];
        fieldConfig.defaults = {
          unit = "percent";
          min = 0;
          max = 100;
        };
      }
    ];
    schemaVersion = 36;
    style = "dark";
    tags = [ ];
    templating.list = [ ];
    time = { from = "now-6h"; to = "now"; };
    timepicker = { };
    timezone = "";
    title = "Node Overview";
    uid = "node-overview";
    version = 1;
    weekStart = "";
  };

in
{
  # Prometheus configuration
  services.prometheus = {
    # Node Exporter on all nodes
    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9100;
    };

    # Server settings only on main node
    enable = lib.mkIf isMain true;
    scrapeConfigs = lib.mkIf isMain [
      {
        job_name = "nodes";
        static_configs = [
          {
            targets = scrapeTargets;
          }
        ];
      }
    ];
  };

  # Open ports on the VPN interface only
  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 9100 ] ++ lib.optionals isMain [ 3000 9090 ];

  services.grafana = lib.mkIf isMain {
    enable = true;
    settings.server = {
      http_addr = "10.200.0.1";
      http_port = 3000;
    };
    settings.security.secret_key = "$__file{/secrets/grafana_secret_key}";
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          uid = "prometheus";
          isDefault = true;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "Default";
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };

  # Provision dashboard file
  environment.etc."grafana-dashboards/nodes.json" = lib.mkIf isMain {
    text = builtins.toJSON dashboard;
  };
}
