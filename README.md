# tfmodule-alicloud-express-connect

A Terraform module for creating and managing Alibaba Cloud Express Connect infrastructure, including Dedicated Physical Connections, Virtual Physical Connections (Hosted Connections / Shared Ports), Virtual Border Routers (VBR), BGP Groups, and BGP Peers with BFD support.

## Features

- **Physical Connection Management**: Create/import a dedicated Express Connect physical connection or reference an existing `Enabled` physical connection via data source verification
- **Shared Port (`VPConn`) Guard Logic**: Automatically ensures Virtual Physical Connections are only created when a parent Physical Connection exists and is in the `Enabled` state
- **Dynamic Shared Port Provisioning**: Allocate Layer-2 isolated VLAN sub-circuits (`VlanId: 1-2999`) to tenant Alibaba Cloud accounts (`vpconn_ali_uid`) using `for_each`
- **Virtual Border Router (`VBR`) Management**: Provision VBR instances on dedicated physical connections or accepted shared ports with IPv4/IPv6 DualStack and BFD timer configuration
- **Dynamic eBGP & BFD Peering**: Configure BGP groups (`alicloud_vpc_bgp_group`) and BGP peers (`alicloud_vpc_bgp_peer`) with hardware BFD support

## Usage

### Example 1: Manage Imported Physical Connection and Provision Shared Ports (Partner Mode)
```hcl
module "express_connect" {
  source = "github.com/xlsmartenterprise/tfmodule-alicloud-express-connect?ref=v1.0.0"

  create_physical_connection = true
  access_point_id            = "ap-southeast-5-pop-Jakarta-B"
  line_operator              = "Other"
  peer_location              = " ap-southeast-5"
  port_type                  = "10GBase-LR"
  type                       = "VPC"
  bandwidth                  = 10000
  status                     = "Enabled"
  resource_group_id          = "rg-acfnvjd6b7kg2uq"

  virtual_physical_connections = {
    tenant_a = {
      name           = "vpconn-tenant-a-vlan100"
      description    = "Shared port 100M for Tenant A"
      vpconn_ali_uid = "1234567890123456"
      vlan_id        = 100
      spec           = "100M"
      order_mode     = "PayByVirtualPhysicalConnectionOwner"
    }
  }
}
```

### Example 2: Provision Shared Ports on an Existing Physical Connection ID
```hcl
module "express_connect_shared_ports" {
  source = "github.com/xlsmartenterprise/tfmodule-alicloud-express-connect?ref=v1.0.0"

  create_physical_connection      = false
  existing_physical_connection_id = "pc-k1av0mq7plpt0qxgr89vn"
  resource_group_id               = "rg-acfnvjd6b7kg2uq"

  virtual_physical_connections = {
    tenant_b = {
      name           = "vpconn-tenant-b-vlan200"
      vpconn_ali_uid = "2345678901234567"
      vlan_id        = 200
      spec           = "500M"
      order_mode     = "PayByVirtualPhysicalConnectionOwner"
    }
  }
}
```

### Example 3: Create VBR and eBGP/BFD Peering on an Accepted Shared Port (Tenant Mode)
```hcl
module "express_connect_tenant_vbr" {
  source = "github.com/xlsmartenterprise/tfmodule-alicloud-express-connect?ref=v1.0.0"

  create_physical_connection      = false
  existing_physical_connection_id = "pc-xxxxxxxxxxxx"

  virtual_border_routers = {
    vbr_main = {
      name                = "vbr-jakarta-main"
      vlan_id             = 100
      local_gateway_ip    = "169.254.10.1"
      peer_gateway_ip     = "169.254.10.2"
      peering_subnet_mask = "255.255.255.252"
      min_rx_interval     = 1000
      min_tx_interval     = 1000
      detect_multiplier   = 3
    }
  }

  bgp_groups = {
    bgpg_idc = {
      name      = "bgpg-idc-primary"
      vbr_key   = "vbr_main"
      peer_asn  = "65001"
      local_asn = "45104"
    }
  }

  bgp_peers = {
    bgpp_idc = {
      bgp_group_key   = "bgpg_idc"
      peer_ip_address = "169.254.10.2"
      enable_bfd      = true
      bfd_multi_hop   = 1
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_physical_connection | Whether to create or manage the Express Connect physical connection resource | `bool` | `true` | no |
| existing_physical_connection_id | The ID of an existing Express Connect physical connection when `create_physical_connection` is `false` | `string` | `null` | no |
| access_point_id | The access point ID of the Express Connect circuit | `string` | `null` | no |
| line_operator | The connectivity provider (`CT`, `CU`, `CM`, `CO`, `Equinix`, `Other`) | `string` | `"Other"` | no |
| peer_location | The geographical location of the on-premises data center | `string` | `null` | no |
| port_type | The port type of the Express Connect circuit (`100Base-T`, `1000Base-T`, `1000Base-LX`, `10GBase-T`, `10GBase-LR`, `40GBase-LR`, `100GBase-LR`) | `string` | `"10GBase-LR"` | no |
| type | The type of Express Connect circuit | `string` | `"VPC"` | no |
| bandwidth | The maximum bandwidth of the physical connection in Mbps | `number` | `10000` | no |
| physical_connection_name | The name of the Express Connect physical connection | `string` | `null` | no |
| description | The description of the Express Connect physical connection | `string` | `null` | no |
| circuit_code | The circuit code provided by the connectivity provider | `string` | `null` | no |
| redundant_physical_connection_id | The ID of the redundant Express Connect physical connection | `string` | `null` | no |
| status | The status of the Express Connect circuit (`Confirmed`, `Enabled`, `Canceled`, `Terminated`) | `string` | `"Enabled"` | no |
| period | The subscription duration when status is set to `Enabled` | `number` | `null` | no |
| pricing_cycle | The billing cycle of the subscription (`Month` or `Year`) | `string` | `null` | no |
| resource_group_id | Default resource group ID for Virtual Physical Connections and VBRs | `string` | `null` | no |
| virtual_physical_connections | Map of Virtual Physical Connections (shared ports) to create on the physical connection | `map(object)` | `{}` | no |
| virtual_border_routers | Map of Virtual Border Routers (VBR) to create | `map(object)` | `{}` | no |
| bgp_groups | Map of BGP groups to create on VBR instances | `map(object)` | `{}` | no |
| bgp_peers | Map of BGP peers to create on BGP groups | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| physical_connection_id | The ID of the Express Connect physical connection |
| physical_connection_status | The status of the Express Connect physical connection |
| physical_connection | The Express Connect physical connection resource object |
| virtual_physical_connection_ids | Map of Virtual Physical Connection keys to their IDs |
| virtual_physical_connections | Complete Virtual Physical Connection resource objects |
| virtual_border_router_ids | Map of Virtual Border Router keys to their IDs |
| virtual_border_routers | Complete Virtual Border Router resource objects |
| bgp_group_ids | Map of BGP group keys to their IDs |
| bgp_peer_ids | Map of BGP peer keys to their IDs |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| alicloud | >= 1.260.1, < 2.0.0 |

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and changes.
