resource "helm_release" "memos" {
  name             = "memos"
  chart            = "memos"
  namespace        = "memos"
  repository       = "oci://ghcr.io/gabe565/charts"
  create_namespace = true

  timeout       = 100
  atomic        = false
  wait          = true
  wait_for_jobs = false

  version = "0.17.0"
  set = [{
    name  = "env.TZ"
    value = "America/New_York"
    }, {
    name  = "service.main.type"
    value = "NodePort"
    },
    {
      name  = "service.main.ports.http.nodePort"
      value = "32080" # choose any free port between 30000–32767
      }, {
      name  = "persistence.data.enabled"
      value = "true"
      }, {
      name  = "persistence.data.size"
      value = "5Gi"
      }, {
      name  = "persistence.data.storageClass"
      value = ""
      }, {
      name  = "persistence.data.accessMode"
      value = "ReadWriteOnce"
    }

  ]
}
