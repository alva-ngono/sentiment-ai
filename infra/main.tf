terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# Reseau Docker partage Jenkins / SonarQube / SentimentAI
resource "docker_network" "cicd" {
  name = "cicd-network"
}

# Image Docker SentimentAI -- image LOCALE buildee par Jenkins
resource "docker_image" "sentiment" {
  name         = "sentiment-ai:${var.image_tag}"
  keep_locally = true
}

# Conteneur staging
resource "docker_container" "sentiment_staging" {
  name    = var.container_name
  image   = docker_image.sentiment.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 8000
    external = var.app_port
  }

  env = [
    "ENV=staging",
    "LOG_LEVEL=INFO",
  ]

  healthcheck {
    test     = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}