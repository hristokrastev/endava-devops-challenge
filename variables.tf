variable "password" {
  description = "Password for the DB"
  type        = string
  default     = "Thisisnotsecurepassword!234"
}

variable "username" {
  description = "Username for the DB" 
  type        = string
  default     = "hhk"
}

variable "rds_vpc_id" {
  default     = "vpc-c167e5aa"
  description = "Our default RDS virtual private cloud (rds_vpc)."
}

variable "public_subnets" {
  default     = ["subnet-0da84b70", "subnet-407f340c", "subnet-5e329835"]
  description = "The public subnets of our RDS VPC rds-vpc."
}

variable "alarms_email" {
  default     = "shadow_6@abv.bg"
  description = "email for the alarm"
}