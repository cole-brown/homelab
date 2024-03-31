#-------------------------------------------------------------------------------
# Qbittorrent Docker
#-------------------------------------------------------------------------------
# Qbittorrent (Torrent Tracker API Support) running on Docker
#
# Links:
#   https://www.nomadproject.io/docs/job-specification/job
#
#   https://www.qbittorrent.org/
#   https://hub.docker.com/r/linuxserver/qbittorrent
#------------------------------

job "qbittorrent" {
  # Default is "global".
  # region      = "global"
  datacenters = ["home-2024-dc"]

  # Default is "service".
  # type = "service"

  # Constrain to a certain host?
  #  constraint {
  #    # https://www.nomadproject.io/docs/runtime/interpolation
  #    attribute = "${attr.unique.hostname}"
  #    value = "blowhole"
  # }

  group "qbittorrent" {
    # Defaults to 1.
    # count = 1

    restart {
      attempts = 5
      delay    = "30s"
      # "fail" does not try any more restarts after it fails `attempts` times in the `interval`.
      # "delay" will try restarts again after waiting until the next `interval`.
      # mode     = "fail"
    }

    #------------------------------
    # Network, Ports
    #------------------------------
    # Don't need to define any ports because it's on a macvlan network,
    # so it gets all its own ports.
    # network {
    #   # Web UI - HTTP
    #   port "http" {
    #     static = 9117
    #   }
    # }

    #------------------------------
    # Volumes: Nomad Client Host Volumes
    #------------------------------

    #---
    # NFS mount.
    #---
    volume "files-media" {
      type = "host"
      source = "files-media"
      read_only = false
    }

    #---
    # Qbittorrent data storage location.
    #---
    volume "qbittorrent-config" {
      type = "host"
      source = "qbittorrent-config"
      read_only = false
    }

    #------------------------------
    # Task
    #------------------------------
    task "qbittorrent" {
      # https://www.nomadproject.io/docs/job-specification/task

      # Docker Container
      driver = "docker"

      # Use "UID:GID" if the volumes are owned by a non-root user/group.
      #   ~sudo groupadd --gid 2001 qbittorrent~
      #   ~sudo useradd --no-create-home --uid 2001 --gid 2001 --no-user-group --shell /usr/sbin/nologin qbittorrent~
      # user = "2001:2001" # "qbittorrent:qbittorrent"
      #
      # NOTE [2024-03-31]: Don't set this user/group. Only use PUID/PGID in
      # `env`. If this is set, you can't connect to the qBittorrent web UI.
      #   > $ id nomad media
      #   > uid=999(nomad) gid=991(nomad) groups=991(nomad)
      #   > uid=1001(media) gid=1001(media) groups=1001(media)
      # user = "1000:1000" # "main:main"

      # These are Nomad Docker Bind Mounts.
      # Stored wherever the =host_volume= stanza in the Nomad Client config says they should be.
      volume_mount {
        volume      = "files-media"
        destination = "/data"
        read_only   = false
      }

      volume_mount {
        volume      = "qbittorrent-config"
        destination = "/config"
        read_only   = false
      }

      config {
        #------------------------------
        # General Config
        #------------------------------
        # https://www.nomadproject.io/docs/job-specification/task

        # This is the LinuxServer Qbittorrent image.
        #   - It has a separate Dockerfile for various architectures, and this should grab the correct one.
        image = "lscr.io/linuxserver/qbittorrent"

        # If image's tag is "latest" or omitted, the docker image will always be pulled regardless of this setting.
        # force_pull = "true"

        # Don't need to define any ports because it's on a macvlan network,
        # so it gets all its own ports.
        # ports = [
        # ]

        #------------------------------
        # Docker Network: macvlan
        #------------------------------
        # NOTE: Nomad can't manage a macvlan network. It forwards host ports if you do a network
        # stanza with ~to = "<port-num>"~...
        network_mode = "raspi_vnet"
        ipv4_address = "192.168.50.11"
      }

      env {
        TZ         = "US/Pacific"
        WEBUI_PORT = 80

        # Run as user:group `main:main` in order to fix file permission errors on the NFS mounts.
        # The torrents would just be: Status Errored
        # The logs would say:
        #   (W) 2022-02-20T12:12:36 - File error alert.
        #     Torrent: "Fedora Silverblue ISOs".
        #     File: "/data/download/Fedora Silverblue ISOs/Fedora-Silverblue-ostree-x86_64-35-1.2.iso.!qB".
        #     Reason: Fedora Silverblue ISOs mkdir (/data/download/Fedora Silverblue ISOs/Fedora-Silverblue-ostree-x86_64-35-1.2.iso.!qB)
        #     error: Permission denied
        #
        # home-2024-raspi5:
        #   > $ $ ls -lah /srv/nomad/qbittorrent/
        #   > drwxr-xr-x 3 nomad nomad 4.0K Mar 24 14:42 .
        #   > drwxr-xr-x 4 main  main  4.0K Mar 24 14:45 config
        #   > $ id nomad main
        #   > uid=999(nomad) gid=991(nomad) groups=991(nomad)
        #   > uid=1000(main) gid=1000(main) groups=1000(main),4(adm),20(dialout),24(cdrom),27(sudo),29(audio),44(video),46(plugdev),60(games),100(users),102(input),105(render),106(netdev),995(spi),994(i2c),993(gpio)
        #   > $ ls -lah /media/nfs/media/
        #   > drwxr-xr-x 2 media media 4.0K Jan  1  2023 .
        #   > $ id media
        #   > uid=1001(media) gid=1001(media) groups=1001(media)
        PUID = 1001
        PGID = 1001
      }

      service {
        name = "qbittorrent"
      }

      #------------------------------
      # Resource Reservations
      #---
      # Don't reserve anything - just let this Nomad job reserve the default and then use whatever.
      #------------------------------
      # resources {
      #   # main@home-2019-raspi4:/srv/nomad/pihole/etc/pihole$ sudo lscpu | grep -i mhz
      #   # CPU max MHz:                     1500.0000
      #   # CPU min MHz:                     600.0000
      #   cpu = nnn # MHz
      #
      #   # main@home-2019-raspi4:/srv/nomad/pihole/etc/pihole$ cat /proc/meminfo | grep -i mem
      #   # MemTotal:        1892528 kB
      #   # MemFree:           47384 kB
      #   # MemAvailable:    1416612 kB
      #   # Shmem:             10556 kB
      #   memory = 1024 # mB
      # }
    }
  }
}
