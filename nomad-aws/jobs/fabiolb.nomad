job "fabiolb" {
  datacenters = ["dc1"]
  type        = "system"

  update {
    stagger      = "5s"
    max_parallel = 1
  }

  group "fabiolb" {
    task "fabiolb" {
      driver = "docker"

      config {
        network_mode = "host"
        image        = "fabiolb/fabio:1.5.2-go1.9.1"
        dns_servers = ["172.17.0.1"]
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 1

          port "http" {
            static = 9999
          }

          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}
