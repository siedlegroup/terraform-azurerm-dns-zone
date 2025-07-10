# custom resource to create optional wildcard records in the child domain

variable "wildcard_record_targets" {
  description = "A map of wildcard DNS A records to create. The key is the record name (e.g., '*' or '*.dev') and the value is the IPv4 address."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.wildcard_record_targets :
      (k == "*" || startswith(k, "*.")) &&
      length(split(".", v)) == 4 && alltrue([
        for p in split(".", v) : try(tonumber(p), -1) >= 0 && try(tonumber(p), -1) <= 255
      ])
    ])
    error_message = "Each key in wildcard_record_targets must be '*' or start with '*.', and each value must be a valid IPv4 address."
  }
}

resource "azurerm_dns_a_record" "wildcard" {
  for_each            = var.wildcard_record_targets
  provider            = azurerm.child
  name                = each.key
  zone_name           = lower(azurerm_dns_zone.child.name)
  resource_group_name = var.child_domain_resource_group_name
  ttl                 = 300
  records             = [each.value]
  tags                = var.tags
}
