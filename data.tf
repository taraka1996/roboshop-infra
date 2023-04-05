data "aws_ssm_parameter" "ssh_pass" {
  name = "${var.env}.ssh.pass"

}
output "ssh_pass_value" {
  value = data.aws_ssm_parameter.ssh_pass.value
}


data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "devops-practice-with-ansible"
  owners      = ["self"]

}
