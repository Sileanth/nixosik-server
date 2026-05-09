{ config, lib, pkgs, name, hosts, ... }:

let
  isMain = name == "main";
  
  # Scrape targets for Prometheus
  # Filter only servers (excluding clients like helios)
  serverHosts = lib.filterAttrs (_: h: !(h.isClient or false)) hosts;
  scrapeTargets = lib.mapAttrsToList (n: h: "${h.vpnIp}:9100") serverHosts;

  # Helper to create stat panels for a node
  mkNodeStats = nodeName: nodeInfo: yPos: let
    instance = "${nodeInfo.vpnIp}:9100";
  in [
    {
      title = "${nodeName} CPU (5m)";
      type = "stat";
      gridPos = { h = 4; w = 6; x = 0; y = yPos; };
      datasource = { type = "prometheus"; uid = "prometheus"; };
      targets = [{
        expr = "100 - (avg(rate(node_cpu_seconds_total{mode='idle', instance='${instance}'}[5m])) * 100)";
      }];
      fieldConfig.defaults = { 
        unit = "percent"; 
        min = 0; 
        max = 100;
        color = { mode = "thresholds"; };
        thresholds = {
          mode = "absolute";
          steps = [
            { color = "green"; value = null; }
            { color = "orange"; value = 70; }
            { color = "red"; value = 90; }
          ];
        };
      };
    }
    {
      title = "${nodeName} RAM (5m)";
      type = "stat";
      gridPos = { h = 4; w = 6; x = 6; y = yPos; };
      datasource = { type = "prometheus"; uid = "prometheus"; };
      targets = [{
        expr = "avg_over_time((100 - (node_memory_MemAvailable_bytes{instance='${instance}'} / node_memory_MemTotal_bytes{instance='${instance}'} * 100))[5m:1m])";
      }];
      fieldConfig.defaults = { 
        unit = "percent"; 
        min = 0; 
        max = 100;
        color = { mode = "thresholds"; };
        thresholds = {
          mode = "absolute";
          steps = [
            { color = "green"; value = null; }
            { color = "orange"; value = 80; }
            { color = "red"; value = 95; }
          ];
        };
      };
    }
    {
      title = "${nodeName} Disk (/)";
      type = "stat";
      gridPos = { h = 4; w = 6; x = 12; y = yPos; };
      datasource = { type = "prometheus"; uid = "prometheus"; };
      targets = [{
        expr = "100 - (node_filesystem_avail_bytes{instance='${instance}', mountpoint='/'} / node_filesystem_size_bytes{instance='${instance}', mountpoint='/'} * 100)";
      }];
      fieldConfig.defaults = { 
        unit = "percent"; 
        min = 0; 
        max = 100;
        color = { mode = "thresholds"; };
        thresholds = {
          mode = "absolute";
          steps = [
            { color = "green"; value = null; }
            { color = "orange"; value = 80; }
            { color = "red"; value = 90; }
          ];
        };
      };
    }
    {
      title = "${nodeName} Net (5m)";
      type = "stat";
      gridPos = { h = 4; w = 6; x = 18; y = yPos; };
      datasource = { type = "prometheus"; uid = "prometheus"; };
      targets = [{
        expr = "sum(rate(node_network_receive_bytes_total{instance='${instance}', device!='lo'}[5m]) + rate(node_network_transmit_bytes_total{instance='${instance}', device!='lo'}[5m]))";
      }];
      fieldConfig.defaults = { 
        unit = "Bps";
        color = { mode = "continuous-GrYlRd"; };
      };
    }
  ];

  # Helper to create upgrade status panels
  mkUpgradeStats = yPos: let
    instance = "${hosts.main.vpnIp}:9100";
    mkServicePanel = title: serviceName: xPos: {
      title = title;
      type = "stat";
      gridPos = { h = 4; w = 8; x = xPos; y = yPos; };
      datasource = { type = "prometheus"; uid = "prometheus"; };
      targets = [
        {
          expr = "node_systemd_unit_state{instance='${instance}', name='${serviceName}', state='failed'}";
          legendFormat = "Status";
        }
      ];
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = { color = "green"; text = "SUCCESS"; };
              "1" = { color = "red"; text = "FAILED"; };
            };
          }
        ];
      };
    };
  in [
    (mkServicePanel "Main Upgrade" "nixos-upgrade.service" 0)
    (mkServicePanel "Deploy Kotek" "deploy-kotek.service" 8)
    (mkServicePanel "Deploy Piesek" "deploy-piesek.service" 16)
  ];

  # Basic Dashboard JSON
  dashboard = {
    annotations.list = [ ];
    editable = true;
    fiscalYearStartMonth = 0;
    graphTooltip = 0;
    links = [ ];
    liveNow = false;
    panels = 
      (mkNodeStats "main" hosts.main 0) ++
      (mkNodeStats "kotek" hosts.kotek 4) ++
      (mkNodeStats "piesek" hosts.piesek 8) ++
      (mkUpgradeStats 12) ++
      [
        {
          title = "CPU Usage (Detailed)";
          type = "timeseries";
          gridPos = { h = 8; w = 12; x = 0; y = 16; };
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
          title = "Memory Usage (Detailed)";
          type = "timeseries";
          gridPos = { h = 8; w = 12; x = 12; y = 16; };
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
  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 9100 ] ++ lib.optionals isMain [ 3000 ];

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
