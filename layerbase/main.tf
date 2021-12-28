module "vpc" {
  source = "/Users/carl5322/repositorios/modulos/vpc"

  environment              = "prod"
  name_account             = "log-archive"
  name_vpc                 = "log-archive-virginia-vpc"
  availability_zones_count = "3"
  instance_tenancy         = "default"
  vpc_cidr_range           = "172.21.0.0/16"
  public_subnets           = ["172.21.16.0/20", "172.21.32.0/20", "172.21.48.0/20"]
  private_subnets          = ["172.21.64.0/18", "172.21.128.0/18", "172.21.192.0/18"]
}


