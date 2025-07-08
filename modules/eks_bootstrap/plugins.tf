# Time delay after worker-node creation
resource "time_sleep" "wait_for_node" {
  # Adjust this create_duration based on your needs
  create_duration = "30s"
}

# This manifist allows installing a number of k8s third party tools
# Mertrics server
resource "helm_release" "metrics_server" {
  count           = var.plugins == null ? 0 : var.plugins.metrics_server != null || var.plugins.cluster_autoscaler != null ? 1 : 0
  name            = "metrics-server"
  repository      = "https://kubernetes-sigs.github.io/metrics-server/"
  chart           = "metrics-server"
  force_update    = true
  cleanup_on_fail = true
  wait            = var.plugins.dont_wait_for_helm_install ? false : true
  values          = var.plugins.metrics_server.values != null ? var.plugins.metrics_server.values : []

  set = [
    {
      name  = "containerPort"
      value = "10250"
    }
  ]


  depends_on = [
    time_sleep.wait_for_node
  ]

}

# Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count           = var.plugins == null ? 0 : var.plugins.cluster_autoscaler != null ? 1 : 0
  name            = "cluster-autoscaler"
  repository      = "https://kubernetes.github.io/autoscaler"
  chart           = "cluster-autoscaler"
  namespace       = "kube-system"
  force_update    = true
  cleanup_on_fail = true
  wait            = var.plugins.dont_wait_for_helm_install ? false : true
  values          = var.plugins.cluster_autoscaler.values != null ? var.plugins.cluster_autoscaler.values : []
  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = var.plugins.cluster_autoscaler.cluster_name
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "awsRegion"
      value = var.plugins.cluster_autoscaler.region
    }
  ]

  depends_on = [
    time_sleep.wait_for_node,
    helm_release.metrics_server]
}


# ArgoCD
resource "helm_release" "argo_cd" {
  count           = var.plugins == null ? 0 : var.plugins.argo_cd != null ? 1 : 0
  name            = "argo"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argocd-apps"
  force_update    = true
  cleanup_on_fail = true
  wait            = var.plugins.dont_wait_for_helm_install ? false : true
  values          = var.plugins.argo_cd.values == null ? [] : var.plugins.argo_cd.values
  depends_on      = [time_sleep.wait_for_node,helm_release.metrics_server]
}

# Loki
resource "helm_release" "loki" {
  count            = var.plugins == null ? 0 : var.plugins.loki != null ? 1 : 0
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "monitoring"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  values           = var.plugins.loki.values == null ? [] : var.plugins.loki.values
  depends_on = [
    time_sleep.wait_for_node,
    helm_release.prometheus]
}

# Promethueus
resource "helm_release" "prometheus" {
  count            = var.plugins == null ? 0 : var.plugins.prometheus != null ? 1 : 0
  name             = "prometheus-community"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  values           = var.plugins.prometheus.values == null ? [] : var.plugins.prometheus.values

  set = [
    {
      name  = "serverFiles.\"prometheus\\.yml\".scrape_configs[0].static_configs[0].targets"
      value = "prometheus-operated.monitoring.svc.cluster.local:9090"
    }
  ]
  depends_on = [
    time_sleep.wait_for_node,
    helm_release.metrics_server
  ]
}

# AWS Alb
resource "helm_release" "aws_alb_controller" {
  count           = var.plugins == null ? 0 : var.plugins.aws_alb_controller != null ? 1 : 0
  name            = "aws"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
  force_update    = true
  cleanup_on_fail = true
  timeout         = 1200
  wait            = var.plugins.dont_wait_for_helm_install ? false : true
  wait_for_jobs   = true
  values          = var.plugins.aws_alb_controller.values == null ? [] : var.plugins.aws_alb_controller.values

  set = [
    {
      name  = "clusterName"
      value = var.plugins.aws_alb_controller.eks_cluster_name
    },
    {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
    },
    {
    name  = "region"
    value = var.plugins.aws_alb_controller.region
    },
    {
    name  = "vpcId"
    value = var.plugins.aws_alb_controller.vpc_id # or however you reference your VPC ID
    }
  ]

  depends_on = [
    time_sleep.wait_for_node,
    helm_release.metrics_server,
  helm_release.cluster_autoscaler]
}

# Nginx Controller
# Doc: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/
# Doc: https://kubernetes.github.io/ingress-nginx/deploy/
resource "helm_release" "nginx" {
  for_each = var.plugins.nginx_controller
  name             = "${each.key}"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true
  timeout          = 1200
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  values           = lookup(each.value, "values", [])
  # Ingress Class Configuration
  set = concat(
    [
      {
        name  = "controller.ingressClassByName"
        value = "true"
      },
      {
        name  = "controller.ingressClassResource.name"
        value = "${each.key}"
      },
      {
        name  = "controller.ingressClassResource.enabled"
        value = "true"
      },
      {
        name  = "controller.ingressClassResource.default"
        value = "false" # Prevents conflicts with ALB controller
      },
    ],
    lookup(each.value,"alb_config", null) != null ? [
      # AWS Load Balancer Annotations
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = lookup(each.value, "scheme_type", "internet-facing" ) != "internet-facing" ? "internal" : "external"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
        value = lookup(each.value.alb_config, "alb_ingress_traffic_mode", "ip")
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
        value = lookup(each.value, "scheme_type", "internet-facing")
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
        value = lookup(each.value.alb_config, "enable_cross_zone", false) == true ? true : false
      },
      {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ip-address-type"
      value = lower(lookup(each.value.alb_config, "alb_family_type", "ipv4"))
      }
    ] : []
  )
  depends_on = [
    time_sleep.wait_for_node,
    helm_release.aws_alb_controller,
  helm_release.metrics_server]
}

# Cert Manager
# Time delay after worker-node creation
resource "time_sleep" "wait_for_alb_endpoint" {
  count      = var.plugins == null ? 0 : var.plugins.cert_manager != null || var.plugins.rancher != null ? 1 : 0
  depends_on = [helm_release.nginx, helm_release.aws_alb_controller]
  # Adjust this create_duration based on your needs
  create_duration = "60s"
}
resource "helm_release" "cert_manager" {
  count            = var.plugins == null ? 0 : var.plugins.cert_manager != null || var.plugins.rancher != null ? 1 : 0
  name             = "cert-manger"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  values           = var.plugins.cert_manager.values == null ? [] : var.plugins.cert_manager.values

  set = [
      {
    name  = "crds.keep"
    value = "true"
    },
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]


  depends_on = [
    time_sleep.wait_for_node,
    helm_release.metrics_server,
  time_sleep.wait_for_alb_endpoint]
}

# Secret Store CSI Driver: This setup does not include AWS role permission binding. This resource requries:
## 1. Role with trust policy that allows access to access to AWS Secret Store of the resource.
## 2. Pod Identity association resource that binds the role with the namespace and service account names related to the application which will use the secrets.
## 3. Service Account manifist to be created using annotation that assigns the role's arn, deployed in the namespace assigned in the pod identity association.
## 4. Pod should use the service account.
## 5. After that the csi manifists can be deployed and assigned by the pod as volume.
resource "helm_release" "secrets_store_csi_driver" {
  count      = var.plugins == null ? 0 : var.plugins.secrets_store_csi_driver != null ? 1 : 0
  name       = "secret-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  wait       = var.plugins.dont_wait_for_helm_install ? false : true
  values     = var.plugins.secrets_store_csi_driver.values == null ? [] : var.plugins.secrets_store_csi_driver.values

  set = [{
    name  = "syncSecret.enabled"
    value = "true"
  }]
  depends_on = [
    time_sleep.wait_for_node,
  helm_release.metrics_server]
}
resource "helm_release" "aws_secrets_store_csi_driver" {
  count           = var.plugins == null ? 0 : var.plugins.secrets_store_csi_driver == false ? 0 : 1
  name            = "aws-secret-store-csi-driver"
  repository      = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart           = "secrets-store-csi-driver-provider-aws"
  namespace       = "kube-system"
  force_update    = true
  cleanup_on_fail = true
  wait            = var.plugins.dont_wait_for_helm_install ? false : true
  depends_on = [
    time_sleep.wait_for_node,
    helm_release.secrets_store_csi_driver,
  helm_release.metrics_server]
}

# External Secrets
resource "helm_release" "external_secrets" {
  count            = var.plugins == null ? 0 : var.plugins.external_secrets != null ? 1 : 0
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  force_update     = true
  cleanup_on_fail  = true
  create_namespace = true
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  values           = var.plugins.external_secrets.values == null ? [] : var.plugins.external_secrets.values

  set = [{
    name  = "installCRDs"
    value = "true"
  }]
  depends_on = [time_sleep.wait_for_node, helm_release.metrics_server , helm_release.rancher]
}

# K8s Dashboard
resource "helm_release" "kubernetes_dashboard" {
  count            = var.plugins == null ? 0 : var.plugins.kubernetes_dashboard == null ? 0 : var.plugins.kubernetes_dashboard != null ? 1 : 0
  name             = "k8s-dashboard"
  repository       = "https://kubernetes.github.io/dashboard"
  chart            = "kubernetes-dashboard"
  namespace        = "kubernetes-dashboard"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true
  values           = var.plugins.kubernetes_dashboard.values == null ? [] : var.plugins.kubernetes_dashboard.values
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  set = flatten ([
    [
      {
        name  = "app.ingress.enabled"
        value = "true"
      },
      {
        name  = "app.ingress.ingressClassName"
        value = var.plugins.kubernetes_dashboard.use_internally ? "internal-nginx" : "external-nginx"
      }
    ],
    [
      # Dynamic block for hosts
      for id_key, id_value in var.plugins.kubernetes_dashboard.hosts :
        {
          name  = "app.ingress.hosts[${id_key}]"
          value = id_value
        }
    ]
  ])    

  depends_on = [
    time_sleep.wait_for_node,
    helm_release.nginx,
    helm_release.aws_alb_controller,
    helm_release.metrics_server,
    helm_release.cert_manager
  ]
}

# Rancher
resource "helm_release" "rancher" {
  count            = var.plugins == null ? 0 : var.plugins.rancher != null ? 1 : 0
  name             = "rancher-stable"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true
  cleanup_on_fail  = true
  wait_for_jobs    = true
  timeout          = 600
  disable_webhooks = true
  #upgrade_install  = true
  values           = var.plugins.rancher.values == null ? [] : var.plugins.rancher.values
  wait             = var.plugins.dont_wait_for_helm_install ? false : true
  set = concat(
    var.plugins.rancher.host != null && var.plugins.rancher.host != "" ? [
      {
        name  = "hostname"
        value = var.plugins.rancher.host
      }
    ] : [],
    [
      {
        name  = "ingress.ingressClassName"
        value = var.plugins.rancher.use_internal_ingress == true ? "internal-nginx" : "external-nginx"
      }
    ]
  )


  depends_on = [
    time_sleep.wait_for_node,
    helm_release.cert_manager,
    helm_release.aws_alb_controller,
    helm_release.nginx,
    helm_release.metrics_server
  ]
}