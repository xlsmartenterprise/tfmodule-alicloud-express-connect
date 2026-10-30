# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-30

### Added
- Initial release of Alibaba Cloud Express Connect Terraform module
- Support for creating, importing, or referencing an existing Express Connect Physical Connection (`alicloud_express_connect_physical_connection`)
- Built-in verification via `alicloud_express_connect_physical_connections` data source and `lifecycle.precondition` guard ensuring shared ports (`VPConn`) and VBRs are only created when the parent Physical Connection exists and is in the `Enabled` state
- Dynamic creation of Virtual Physical Connections / Shared Ports (`alicloud_express_connect_virtual_physical_connection`) using `for_each`
- Dynamic creation of Virtual Border Routers (`alicloud_express_connect_virtual_border_router`) with DualStack IPv4/IPv6 and BFD support
- Dynamic creation of BGP Groups (`alicloud_vpc_bgp_group`) and BGP Peers (`alicloud_vpc_bgp_peer`)
- Comprehensive outputs for Physical Connection, Shared Ports, VBRs, BGP Groups, and BGP Peers
