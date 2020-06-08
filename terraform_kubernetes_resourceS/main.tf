#################### Enter the provider details #############################################

provider "kubernetes" {
  config_path = "$HOME/.kube/config"
  config_context = "kubernetes-admin@kubernetes"
}

##################### Deployment Resource Configuration ##############################################

resource "kubernetes_deployment" "node_deploy" {
  metadata {
    name = "node-fibo-deployment"
    labels = {
      app = "node-fibo"
    }
  }
  spec {
    replicas = 10
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "30%"
      }
    }
    selector {
      match_labels = {
        app = "node-fibo"
      }
    }
    template {
      metadata {
        labels = {
          app = "node-fibo"
        }
      }
      spec {
        priority_class_name = "node-priority-class"
        container {
          image = "<image_id:version>"
          name = "node-fibo"
          port {
            container_port = 8080
          }
          resources {
            limits {
              cpu = "40m"
              memory = "120Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds = 30
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "loadbalancer_service" {
  metadata {
    name = "node-fibo-service"
  }
  spec {
    selector = {
      app = "node-fibo"
    }
    port {
      port = 3000
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}


resource "kubernetes_priority_class" "priority_class" {
  metadata {
    name = "node-priority-class"
  }
  value = 1000000000
}

