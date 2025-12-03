output "aws_instance_public_ip" {
  value = aws_eip.app.public_ip

}
output "aws_instance_id" {
  value = aws_instance.web.id
}
output "aws_instance_public_dns" {
  value = aws_eip.app.public_dns
}
output "aws_instance_private_ip" {
  value = aws_instance.web.private_ip
}
output "key_pair_name" {
  value = aws_key_pair.key_ssh.key_name
}

output "k3s_kubeconfig_scp" {
  value = "scp -i C:\\Users\\Admin\\.ssh\\id_rsa ec2-user@${aws_eip.app.public_ip}:/home/ec2-user/.kube/config C:\\Users\\Admin\\k3s-config"
}