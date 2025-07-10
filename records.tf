variable "records" {
  description = "A map of DNS records to create. Supported types: A, AAAA, CNAME, TXT. The key is the record name (e.g., '@', 'www', '*')."
  type = map(object({
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.records) : contains(["A", "AAAA", "CNAME", "TXT"], upper(r.type))])
    error_message = "The record type must be one of: A, AAAA, CNAME, TXT."
  }

  validation {
    condition     = alltrue([for r in values(var.records) : !(upper(r.type) == "CNAME" && length(r.records) != 1)])
    error_message = "CNAME records must have exactly one record value."
  }
}

locals {
  a_records     = { for k, v in var.records : k => v if upper(v.type) == "A" }
  aaaa_records  = { for k, v in var.records : k => v if upper(v.type) == "AAAA" }
  cname_records = { for k, v in var.records : k => v if upper(v.type) == "CNAME" }
  txt_records   = { for k, v in var.records : k => v if upper(v.type) == "TXT" }
}

resource "azurerm_dns_a_record" "a" {
  for_each            = local.a_records
  provider            = azurerm.child
  name                = each.key
  zone_name           = lower(azurerm_dns_zone.child.name)
  resource_group_name = var.child_domain_resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = var.tags
}

resource "azurerm_dns_aaaa_record" "aaaa" {
  for_each            = local.aaaa_records
  provider            = azurerm.child
  name                = each.key
  zone_name           = lower(azurerm_dns_zone.child.name)
  resource_group_name = var.child_domain_resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = var.tags
}

resource "azurerm_dns_cname_record" "cname" {
  for_each            = local.cname_records
  provider            = azurerm.child
  name                = each.key
  zone_name           = lower(azurerm_dns_zone.child.name)
  resource_group_name = var.child_domain_resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.records[0]
  tags                = var.tags
}

resource "azurerm_dns_txt_record" "txt" {
  for_each            = local.txt_records
  provider            = azurerm.child
  name                = each.key
  zone_name           = lower(azurerm_dns_zone.child.name)
  resource_group_name = var.child_domain_resource_group_name
  ttl                 = each.value.ttl
  tags                = var.tags

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }
} 
