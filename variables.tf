variable "vApp" {
  type    = string
  default = "rlv"
}

variable "vEnv" {
  type    = string
  default = "test"
}

variable "ec2-ingress-rules" {
  type = list(object({
    port        = number
    proto       = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 80
      proto       = "tcp"
      cidr_blocks = ["76.181.232.36/32"]
    },
    {
      port        = 22
      proto       = "tcp"
      cidr_blocks = ["76.181.232.36/32"]
    },
    {
      port        = 8080
      proto       = "tcp"
      cidr_blocks = ["76.181.232.36/32"]
    }
  ]
}

variable "ec2-egress-rules" {
  type = list(object({
    port        = number
    proto       = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 0
      proto       = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}