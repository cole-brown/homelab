#-------------------------------------------------------------------------------
# Jackett Docker
#-------------------------------------------------------------------------------
# Jackett (Torrent Tracker API Support) running on Docker
#
# Links:
#   https://www.nomadproject.io/docs/job-specification/job
#
#   https://github.com/Jackett/Jackett
#   https://hub.docker.com/r/linuxserver/jackett
#------------------------------

job "jackett" {
  # Default is "global".
  # region      = "global"
  datacenters = ["home-2024-dc"]

  # Default is "service".
  # type = "service"

  # Constrain to a certain host?
  #  constraint {
  #    # https://www.nomadproject.io/docs/runtime/interpolation
  #    attribute = "${attr.unique.hostname}"
  #    value = "something"
  # }

  group "jackett" {
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
    # Jackett data storage location.
    #---
    volume "jackett-config" {
      type = "host"
      source = "jackett-config"
      read_only = false
    }

    #------------------------------
    # Task
    #------------------------------
    task "jackett" {
      # https://www.nomadproject.io/docs/job-specification/task

      # Docker Container
      driver = "docker"

      # Use "UID:GID" if the volumes are owned by a non-root user/group.
      #   ~sudo groupadd --gid 2001 jackett~
      #   ~sudo useradd --no-create-home --uid 2001 --gid 2001 --no-user-group --shell /usr/sbin/nologin jackett~
      # user   = "2001:2001" # "jackett:jackett"

      # These are Nomad Docker Bind Mounts.
      # Stored wherever the =host_volume= stanza in the Nomad Client config says they should be.
      volume_mount {
        volume      = "files-media"
        destination = "/data"
        read_only   = false
      }

      volume_mount {
        volume      = "jackett-config"
        destination = "/config"
        read_only   = false
      }

      config {
        #------------------------------
        # General Config
        #------------------------------
        # https://www.nomadproject.io/docs/job-specification/task

        # This is the LinuxServer Jackett image.
        #   - It has a separate Dockerfile for various architectures, and this should grab the correct one.
        image = "lscr.io/linuxserver/jackett"

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
        ipv4_address = "192.168.50.6"
      }

      env {
        TZ = "US/Pacific"

        # Allows Jackett to update inside of the container.
        # Currently recommended by Jackett: https://hub.docker.com/r/linuxserver/jackett
        AUTO_UPDATE = true

        # Run Options here:
        # RUN_OPTS = "<optional>"
      }

      service {
        name = "jackett"
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
