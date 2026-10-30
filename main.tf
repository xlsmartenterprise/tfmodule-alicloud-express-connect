locals {
  has_existing_physical_connection = (
    !var.create_physical_connection &&
    var.existing_physical_connection_id != null &&
    var.existing_physical_connection_id != ""
  )

  has_physical_connection = var.create_physical_connection || local.has_existing_physical_connection

  physical_connection_id = (
    var.create_physical_connection
    ? alicloud_express_connect_physical_connection.this[0].id
    : (
      local.has_existing_physical_connection && length(data.alicloud_express_connect_physical_connections.existing[0].ids) > 0
      ? data.alicloud_express_connect_physical_connections.existing[0].ids[0]
      : null
    )
  )

  physical_connection_status = (
    var.create_physical_connection
    ? alicloud_express_connect_physical_connection.this[0].status
    : (
      local.has_existing_physical_connection && length(data.alicloud_express_connect_physical_connections.existing[0].connections) > 0
      ? data.alicloud_express_connect_physical_connections.existing[0].connections[0].status
      : null
    )
  )

  # Shared ports (VPConn) and VBRs are only created when a physical connection is present
  should_create_vpconn = local.has_physical_connection && length(var.virtual_physical_connections) > 0
  should_create_vbr    = local.has_physical_connection && length(var.virtual_border_routers) > 0
}

# Verify existing Express Connect Physical Connection when create_physical_connection is false
data "alicloud_express_connect_physical_connections" "existing" {
  count  = local.has_existing_physical_connection ? 1 : 0
  ids    = [var.existing_physical_connection_id]
  status = "Enabled"
}

# Create or manage Express Connect Physical Connection
resource "alicloud_express_connect_physical_connection" "this" {
  count = var.create_physical_connection ? 1 : 0

  access_point_id                  = var.access_point_id
  line_operator                    = var.line_operator
  peer_location                    = var.peer_location
  port_type                        = var.port_type
  type                             = var.type
  bandwidth                        = var.bandwidth
  physical_connection_name         = var.physical_connection_name
  description                      = var.description
  circuit_code                     = var.circuit_code
  redundant_physical_connection_id = var.redundant_physical_connection_id
  status                           = var.status
  period                           = var.period
  pricing_cycle                    = var.pricing_cycle

  lifecycle {
    ignore_changes = [
      period,
      pricing_cycle,
    ]
  }
}

# Manage Physical Connection tags in Terraform state
resource "terraform_data" "physical_connection_tags" {
  count = local.has_physical_connection && length(var.tags) > 0 ? 1 : 0

  triggers_replace = [
    local.physical_connection_id,
    jsonencode(var.tags),
  ]

  input = {
    physical_connection_id = local.physical_connection_id
    tags                   = var.tags
  }
}

# Create Virtual Physical Connections (Hosted Connections / Shared Ports)
resource "alicloud_express_connect_virtual_physical_connection" "vpconn" {
  for_each = local.should_create_vpconn ? var.virtual_physical_connections : {}

  parent_physical_connection_id    = local.physical_connection_id
  virtual_physical_connection_name = each.value.name
  description                      = each.value.description
  vpconn_ali_uid                   = each.value.vpconn_ali_uid
  vlan_id                          = each.value.vlan_id
  spec                             = each.value.spec
  order_mode                       = each.value.order_mode
  expect_spec                      = each.value.expect_spec
  resource_group_id                = coalesce(each.value.resource_group_id, var.resource_group_id)
  dry_run                          = each.value.dry_run

  depends_on = [
    alicloud_express_connect_physical_connection.this,
    data.alicloud_express_connect_physical_connections.existing,
  ]

  lifecycle {
    precondition {
      condition     = local.physical_connection_id != null && local.physical_connection_status == "Enabled"
      error_message = "Shared ports (Virtual Physical Connections) can only be created when the parent Physical Connection already exists and has status = Enabled."
    }
  }
}

# Create Virtual Border Routers (VBR) only when Physical Connection or Shared Port exists
resource "alicloud_express_connect_virtual_border_router" "vbr" {
  for_each = local.should_create_vbr ? var.virtual_border_routers : {}

  physical_connection_id = (
    each.value.physical_connection_id != null
    ? each.value.physical_connection_id
    : (
      each.value.vpconn_key != null
      ? alicloud_express_connect_virtual_physical_connection.vpconn[each.value.vpconn_key].id
      : local.physical_connection_id
    )
  )
  virtual_border_router_name = each.value.name
  description                = each.value.description
  vlan_id                    = each.value.vlan_id
  local_gateway_ip           = each.value.local_gateway_ip
  peer_gateway_ip            = each.value.peer_gateway_ip
  peering_subnet_mask        = each.value.peering_subnet_mask
  bandwidth                  = each.value.bandwidth
  circuit_code               = each.value.circuit_code
  vbr_owner_id               = each.value.vbr_owner_id
  enable_ipv6                = each.value.enable_ipv6
  local_ipv6_gateway_ip      = each.value.local_ipv6_gateway_ip
  peer_ipv6_gateway_ip       = each.value.peer_ipv6_gateway_ip
  peering_ipv6_subnet_mask   = each.value.peering_ipv6_subnet_mask
  min_rx_interval            = each.value.min_rx_interval
  min_tx_interval            = each.value.min_tx_interval
  detect_multiplier          = each.value.detect_multiplier
  mtu                        = each.value.mtu
  sitelink_enable            = each.value.sitelink_enable
  status                     = each.value.status
  resource_group_id          = coalesce(each.value.resource_group_id, var.resource_group_id)
  tags                       = each.value.tags

  depends_on = [
    alicloud_express_connect_physical_connection.this,
    data.alicloud_express_connect_physical_connections.existing,
    alicloud_express_connect_virtual_physical_connection.vpconn,
  ]

  lifecycle {
    precondition {
      condition     = each.value.physical_connection_id != null || each.value.vpconn_key != null || (local.physical_connection_id != null && local.physical_connection_status == "Enabled")
      error_message = "VBR can only be created when a valid Physical Connection (status = Enabled) or Shared Port (VPConn) already exists."
    }
  }
}

# Create BGP Groups on VBRs
resource "alicloud_vpc_bgp_group" "bgp_groups" {
  for_each = var.bgp_groups

  router_id      = each.value.router_id != null ? each.value.router_id : alicloud_express_connect_virtual_border_router.vbr[each.value.vbr_key].id
  bgp_group_name = each.value.name
  description    = each.value.description
  peer_asn       = each.value.peer_asn
  local_asn      = each.value.local_asn
  auth_key       = each.value.auth_key
  is_fake_asn    = each.value.is_fake_asn
  route_limit    = each.value.route_limit
  ip_version     = each.value.ip_version
}

# Create BGP Peers on BGP Groups
resource "alicloud_vpc_bgp_peer" "bgp_peers" {
  for_each = var.bgp_peers

  bgp_group_id    = each.value.bgp_group_id != null ? each.value.bgp_group_id : alicloud_vpc_bgp_group.bgp_groups[each.value.bgp_group_key].id
  peer_ip_address = each.value.peer_ip_address
  enable_bfd      = each.value.enable_bfd
  bfd_multi_hop   = each.value.bfd_multi_hop
  ip_version      = each.value.ip_version
}
