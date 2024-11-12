variable "metadata" {
  type = object({
    name        = string
    environment = string
    region      = string
  })
  default = {
    name        = ""
    environment = ""
    region      = ""
  }
}