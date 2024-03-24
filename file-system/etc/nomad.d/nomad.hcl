#-------------------------------------------------------------------------------
# General Configuration
#-------------------------------------------------------------------------------
# Full configuration options can be found at:
#   https://developer.hashicorp.com/nomad/docs/configuration

datacenter = "home-2024-dc"
data_dir   = "/opt/nomad/data"
bind_addr  = "0.0.0.0"

# advertise {
#   http = "{{ GetInterfaceIP \"eth0\" }}"
#   rpc  = "{{ GetInterfaceIP \"eth0\" }}"
#   serf = "{{ GetInterfaceIP \"eth0\" }}"
# }

plugin "docker" {
  config {
    allow_privileged = true
    allow_caps       = ["ALL"]

    volumes {
      enabled = true
    }
  }
}


#-------------------------------------------------------------------------------
# Server Configuration
#-------------------------------------------------------------------------------

server {
  # license_path is required for Nomad Enterprise as of Nomad v1.1.1+
  #license_path = "/etc/nomad.d/license.hclic"
  enabled          = true
  bootstrap_expect = 1
}


#-------------------------------------------------------------------------------
# Client Configuration
#-------------------------------------------------------------------------------

client {
  enabled = true
  servers = ["127.0.0.1"]

  #-----------------------------------------------------------------------------
  # Client Volumes BEGIN
  #-----------------------------------------------------------------------------

  #------------------------------
  # Volumes, Data: General Files
  #------------------------------

  # Used by Plex.
  host_volume "files-temp" {
    path      = "/tmp"
    read_only = false
  }

  # Root directory for (most) media.
  #   - Media library is at "library/streaming/"
  host_volume "files-media" {
    path      = "/media/nfs/media"
    read_only = false
  }

  # #------------------------------
  # # Volumes, Config: pihole
  # #------------------------------
  #
  # host_volume "pihole-data" {
  #   path      = "/srv/nomad/pihole/etc/pihole"
  #   read_only = false
  # }
  #
  # host_volume "pihole-dnsmasq" {
  #   path      = "/srv/nomad/pihole/etc/dnsmasq.d"
  #   read_only = false
  # }
  #
  #  host_volume "pihole-backups" {
  #   path      = "/srv/nomad/pihole/backups"
  #   read_only = false
  # }
  #
  # #------------------------------
  # # Volumes, Config (Media Server): Plex Media Server
  # #------------------------------
  #
  # host_volume "plex-config" {
  #   path      = "/srv/nomad/plex/config"
  #   read_only = false
  # }

  #------------------------------
  # Volumes, Config (Torrent): Jackett
  #------------------------------

  host_volume "jackett-config" {
    path      = "/srv/nomad/jackett/config"
    read_only = false
  }

  # #------------------------------
  # # Volumes, Config (Torrent): Qbittorrent
  # #------------------------------
  #
  # host_volume "qbittorrent-config" {
  #   path      = "/srv/nomad/qbittorrent/config"
  #   read_only = false
  # }
  #
  # # #------------------------------
  # # # Volumes, Config: Tailscale VPN
  # # #------------------------------
  # #
  # # host_volume "tailscale-data" {
  # #   path      = "/srv/nomad/tailscale/data"
  # #   read_only = false
  # # }
  #
  # # #------------------------------
  # # # Volumes, Config (Media Server): Jellyfin
  # # #------------------------------
  # #
  # # host_volume "jellyfin-config" {
  # #   path      = "/srv/nomad/jellyfin/config"
  # #   read_only = false
  # # }

  #-----------------------------------------------------------------------------
  # Client Volumes END
  #-----------------------------------------------------------------------------
}
