# Kubernetes Ingress Resource for ALB via AWS Load Balancer Controller
resource "kubernetes_ingress_v1" "ingress_alb" {
  metadata {
    name      = "${var.prefix_env}-ingress-alb"
    namespace = "default"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/tags"   = "Terraform=true,Environment=${var.prefix_env}"
    }
  }

  spec {
    ingress_class_name = "${var.prefix_env}-ingressclass-alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_alb.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

# Kubernetes Service for the App
resource "kubernetes_service_v1" "service_alb" {
  metadata {
    name      = "${var.prefix_env}-service-alb"
    namespace = "default"
    labels = {
      app = var.app_name
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# Kubernetes Manifest for IngressClassParams
resource "kubernetes_manifest" "ingress_class_params" {
  manifest = {
    "apiVersion" = "eks.amazonaws.com/v1"
    "kind"       = "IngressClassParams"
    "metadata" = {
      "name" = "${var.prefix_env}-ingressclassparams-alb"
    }
    "spec" = {
      "scheme" = "internet-facing"
    }
  }
}

# Kubernetes Ingress Class
resource "kubernetes_ingress_class_v1" "ingressclass_alb" {
  depends_on = [kubernetes_manifest.ingress_class_params] # Correct dependency
  metadata {
    name = "${var.prefix_env}-ingressclass-alb"

    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }

  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = "${var.prefix_env}-ingressclassparams-alb"
    }
  }
}