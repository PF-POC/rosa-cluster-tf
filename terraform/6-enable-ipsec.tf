resource "shell_script" "enable_ipsec" {
  count = var.enable-ipsec == "true" ? 1 : 0

  lifecycle_commands {
    create = templatefile(
      "./scripts/enable-ipsec.tftpl",
      {
        secret  = "${var.cluster_name}-credentials"
        cluster = var.cluster_name
        mode    = "full"
    })
    delete = templatefile(
      "./scripts/enable-ipsec.tftpl",
      {
        secret  = "${var.cluster_name}-credentials"
        cluster = var.cluster_name
        mode    = "disable"
    })
  }
  environment           = {}
  sensitive_environment = {}
  depends_on = [
    shell_script.cluster_seed
  ]
}