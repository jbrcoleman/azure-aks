variable "location" {
  description = "Azure region for resources"
  default     = "East US"
}

variable "allowed_ip" {
  description = "IP address allowed to access the web application"
  type        = string
  default     = "" 
}