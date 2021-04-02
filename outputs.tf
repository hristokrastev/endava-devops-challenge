output "endpoint" {
  value = aws_eks_cluster.ekscluster.endpoint
}
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.ekscluster.certificate_authority[0].data
}
output "loadbalancer" {
  value = kubernetes_service.hhkkubeservice.status[0].load_balancer[0].ingress[0].hostname
  #kubernetes_service.hhkkubeservice.status[0].load_balancer[0].ingress[0].ip
}
output "db_name" {
  value = aws_db_instance.hhk-rds-db.name
}
output "db_endpoint" {
  value = aws_db_instance.hhk-rds-db.endpoint
}
resource "null_resource" "start-brave" {
  provisioner "local-exec" {
    command = "start brave ${kubernetes_service.hhkkubeservice.status[0].load_balancer[0].ingress[0].hostname}"
  }
  depends_on = [
    kubernetes_service.hhkkubeservice,
    kubernetes_deployment.hhk-kube
  ]
}