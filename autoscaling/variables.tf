variable "region" {
  type        = string
  description = "Default region"
  default     = "us-east-1"
}

variable "cidr_block" {
    default = "10.0.0.0/16"
    type = string
    description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
    default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
    type = list
    description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
    default = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
    type = list
    description = "List of private subnet CIDR blocks"
}

variable "ami_ubuntu_20_04_list" {
  type        = map(any)
  description = "List of Ubuntu 20.04 AMI"
  default = {
    "us-east-1"      = "ami-09e67e426f25ce0d7"
    "us-east-2"      = "ami-00399ec92321828f5"
    "us-west-1"      = "ami-0d382e80be7ffdae5"
    "us-west-2"      = "ami-03d5c68bab01f3496"
    "ap-south-1"     = "ami-0c1a7f89451184c8b"
    "ap-northeast-3" = "ami-0001d1dd884af8872"
    "ap-northeast-2" = "ami-04876f29fd3a5e8ba"
    "ap-southeast-1" = "ami-0d058fe428540cd89"
    "ap-southeast-2" = "ami-0567f647e75c7bc05"
    "ap-northeast-1" = "ami-0df99b3a8349462c6"
    "ca-central-1"   = "ami-0801628222e2e96d6"
    "eu-central-1"   = "ami-05f7491af5eef733a"
    "eu-west-1"      = "ami-0a8e758f5e873d1c1"
    "eu-west-2"      = "ami-0194c3e07668a7e36"
    "eu-west-3"      = "ami-0f7cd40eac2214b37"
    "eu-north-1"     = "ami-0ff338189efb7ed37"
    "sa-east-1"      = "ami-054a31f1b3bf90920"
  }
}

variable "availability_zone_list" {
  type = map(any)
  description = "List of Availability zones according to region"
  default = {
    "us-east-1" = ["us-east-1a",  "us-east-1b",  "us-east-1c" ]
    "us-east-2" = ["us-east-2a",  "us-east-2b",  "us-east-2c" ]
    "us-west-1" = ["us-west-1a",  "us-west-1b",  "us-west-1c" ]
    "us-west-2" = ["us-west-2a",  "us-west-2b",  "us-west-2c" ]
    "ap-south-1" = ["ap-south-1a",  "ap-south-1b",  "ap-south-1c" ]
    "ap-northeast-3" = ["ap-northeast-3a",  "ap-northeast-3b",  "ap-northeast-3c" ] 
    "ap-northeast-2" = ["ap-northeast-2a",  "ap-northeast-2b",  "ap-northeast-2c" ]  
    "ap-southeast-1" = ["ap-southeast-1a",  "ap-southeast-1b",  "ap-southeast-1c" ] 
    "ap-southeast-2" = ["ap-southeast-2a",  "ap-southeast-2b",  "ap-southeast-2c" ]
    "ap-northeast-1" = ["ap-northeast-1a",  "ap-northeast-1b",  "ap-northeast-1c" ]
    "ca-central-1" = ["ca-central-1a",  "ca-central-1b",  "ca-central-1c" ]
    "eu-central-1" = ["eu-central-1a",  "eu-central-1b",  "eu-central-1c" ]
    "eu-west-1" = ["eu-west-1a",  "eu-west-1b",  "eu-west-1c" ] 
    "eu-west-2" = ["eu-west-2a",  "eu-west-2b",  "eu-west-2c" ] 
    "eu-west-3" = ["eu-west-3a",  "eu-west-3b",  "eu-west-3c" ]  
    "eu-north-1" = ["eu-north-1a",  "eu-north-1b",  "eu-north-1c" ]  
    "sa-east-1" = ["sa-east-1a",  "sa-east-1b",  "sa-east-1c" ]
  }
}

variable "instance_type" {
  type        = string
  description = "Type of EC2 instance"
  default     = "t2.micro"
}

variable "tag_name" {
  type        = string
  description = "Value of Name tag"
  default     = "PlayQ-2019"
}

variable "tag_type" {
  type        = string
  description = "Value of Type tag"
  default     = "webserver"
}

variable "tags_on_launch" {
  default = [
    {
      key                 = "Name"
      value               = "PlayQ-2019"
      propagate_at_launch = true
    },
    {
      key                 = "Type"
      value               = "webserver"
      propagate_at_launch = true
    },
  ]
}

variable "key_name" {
  type        = string
  description = "The name of the key pair"
  default     = "webservers"
}

variable "ssh_key" {
  type        = string
  description = "SSH public key for accessing to EC2 instances"
  default     = ""
}

