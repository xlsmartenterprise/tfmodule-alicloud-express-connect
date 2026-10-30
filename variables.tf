# Physical Connection Variables
variable "create_physical_connection" {
  description = "Whether to create or manage the Express Connect physical connection resource."
  type        = bool
  default     = true
}

variable "existing_physical_connection_id" {
  description = "The ID of an existing Express Connect physical connection when create_physical_connection is false."
  type        = string
  default     = null
}

variable "access_point_id" {
  description = "The access point ID of the Express Connect circuit."
  type        = string
  default     = null
}

variable "line_operator" {
  description = "The connectivity provider of the Express Connect circuit (CT, CU, CM, CO, Equinix, Other)."
  type        = string
  default     = "Other"
}

variable "peer_location" {
  description = "The geographical location of the on-premises data center."
  type        = string
  default     = null
}

variable "port_type" {
  description = "The port type of the Express Connect circuit (100Base-T, 1000Base-T, 1000Base-LX, 10GBase-T, 10GBase-LR, 40GBase-LR, 100GBase-LR)."
  type        = string
  default     = "10GBase-LR"
}

variable "type" {
  description = "The type of Express Connect circuit. Default is VPC."
  type        = string
  default     = "VPC"
}

variable "bandwidth" {
  description = "The maximum bandwidth of the physical connection in Mbps."
  type        = number
  default     = 10000
}

variable "physical_connection_name" {
  description = "The name of the Express Connect physical connection."
  type        = string
  default     = null
}

variable "description" {
  description = "The description of the Express Connect physical connection."
  type        = string
  default     = null
}

variable "circuit_code" {
  description = "The circuit code provided by the connectivity provider."
  type        = string
  default     = null
}

variable "redundant_physical_connection_id" {
  description = "The ID of the redundant Express Connect physical connection."
  type        = string
  default     = null
}

variable "status" {
  description = "The status of the Express Connect circuit (Confirmed, Enabled, Canceled, Terminated)."
  type        = string
  default     = "Enabled"
}

variable "period" {
  description = "The subscription duration when status is set to Enabled."
  type        = number
  default     = null
}

variable "pricing_cycle" {
  description = "The billing cycle of the subscription (Month or Year)."
  type        = string
  default     = null
}

variable "resource_group_id" {
  description = "Default resource group ID for Virtual Physical Connections and VBRs."
  type        = string
  default     = null
}

# Virtual Physical Connections (Shared Ports / Hosted Connections)
variable "virtual_physical_connections" {
  description = "Map of Virtual Physical Connections (shared ports) to create on the physical connection."
  type = map(object({
    name              = optional(string, null)
    description       = optional(string, null)
    vpconn_ali_uid    = string
    vlan_id           = number
    spec              = string
    order_mode        = optional(string, "PayByVirtualPhysicalConnectionOwner")
    expect_spec       = optional(string, null)
    resource_group_id = optional(string, null)
    dry_run           = optional(bool, null)
  }))
  default = {}
}

# Virtual Border Routers (VBR)
variable "virtual_border_routers" {
  description = "Map of Virtual Border Routers (VBR) to create."
  type = map(object({
    name                     = optional(string, null)
    description              = optional(string, null)
    physical_connection_id   = optional(string, null)
    vpconn_key               = optional(string, null)
    vlan_id                  = number
    local_gateway_ip         = string
    peer_gateway_ip          = string
    peering_subnet_mask      = optional(string, "255.255.255.252")
    bandwidth                = optional(number, null)
    circuit_code             = optional(string, null)
    vbr_owner_id             = optional(string, null)
    enable_ipv6              = optional(bool, null)
    local_ipv6_gateway_ip    = optional(string, null)
    peer_ipv6_gateway_ip     = optional(string, null)
    peering_ipv6_subnet_mask = optional(string, null)
    min_rx_interval          = optional(number, null)
    min_tx_interval          = optional(number, null)
    detect_multiplier        = optional(number, null)
    mtu                      = optional(number, null)
    sitelink_enable          = optional(bool, null)
    status                   = optional(string, null)
    resource_group_id        = optional(string, null)
    tags                     = optional(map(string), null)
  }))
  default = {}
}

# BGP Groups
variable "bgp_groups" {
  description = "Map of BGP groups to create on VBR instances."
  type = map(object({
    name        = string
    description = optional(string, null)
    vbr_key     = optional(string, null)
    router_id   = optional(string, null)
    peer_asn    = string
    local_asn   = optional(string, "45104")
    auth_key    = optional(string, null)
    is_fake_asn = optional(bool, null)
    route_limit = optional(number, null)
    ip_version  = optional(string, "IPv4")
  }))
  default = {}
}

# BGP Peers
variable "bgp_peers" {
  description = "Map of BGP peers to create on BGP groups."
  type = map(object({
    bgp_group_key   = optional(string, null)
    bgp_group_id    = optional(string, null)
    peer_ip_address = optional(string, null)
    enable_bfd      = optional(bool, true)
    bfd_multi_hop   = optional(number, 1)
    ip_version      = optional(string, "IPv4")
  }))
  default = {}
}
