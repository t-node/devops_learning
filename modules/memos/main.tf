resource "helm_release" "memos" {
  name       = "memos"
  chart     = "memos"
  namespace = "memos"
  repository = "oci://ghcr.io/gabe565/charts"
  create_namespace = true

    timeout = 600
    atomic  = true

  version    = "0.1.0" 
  set = [ {
      name  = "env.TZ"
    value = "America/New_York"
  },{
  name  = "service.type"
  value = "NodePort"
},
{
  name  = "service.nodePort"
  value = "32080"   # choose any free port between 30000–32767
} ] 
}