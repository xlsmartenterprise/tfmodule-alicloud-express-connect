output "physical_connection_id" {
  description = "The ID of the Express Connect physical connection."
  value       = local.physical_connection_id
}

output "physical_connection_status" {
  description = "The status of the Express Connect physical connection."
  value       = local.physical_connection_status
}

output "physical_connection" {
  description = "The Express Connect physical connection resource object."
  value       = var.create_physical_connection ? alicloud_express_connect_physical_connection.this[0] : null
}

output "virtual_physical_connection_ids" {
  description = "Map of Virtual Physical Connection keys to their IDs."
  value = {
    for k, v in alicloud_express_connect_virtual_physical_connection.vpconn : k => v.id
  }
}

output "virtual_physical_connections" {
  description = "Complete Virtual Physical Connection resource objects."
  value       = alicloud_express_connect_virtual_physical_connection.vpconn
}

output "virtual_border_router_ids" {
  description = "Map of Virtual Border Router keys to their IDs."
  value = {
    for k, v in alicloud_express_connect_virtual_border_router.vbr : k => v.id
  }
}

output "virtual_border_routers" {
  description = "Complete Virtual Border Router resource objects."
  value       = alicloud_express_connect_virtual_border_router.vbr
}

output "bgp_group_ids" {
  description = "Map of BGP group keys to their IDs."
  value = {
    for k, v in alicloud_vpc_bgp_group.bgp_groups : k => v.id
  }
}

output "bgp_peer_ids" {
  description = "Map of BGP peer keys to their IDs."
  value = {
    for k, v in alicloud_vpc_bgp_peer.bgp_peers : k => v.id
  }
}
