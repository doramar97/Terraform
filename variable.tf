variable "enviroment" {
  type = string 
  default = "production"
  description = "The enviroment of the vpc"
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["eu-central-1a","eu-central-1b"]
}

variable "cidr_block" {
  type    = string
  default = "30.0.0.0/16"
}