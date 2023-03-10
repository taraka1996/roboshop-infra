terraform {
  backend "s3" {}
}

resource "aws_ssm_parameter" "foo" {
  count = length(var.parameters)
  name = var.parameters[count.index]
  type = "string"
  value = "bar"
}

variable "parameters" {}
default =
]

}
