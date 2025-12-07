## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.33.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 5.33.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.33.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.gke](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_container_cluster.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_container_node_pool.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_service_account.nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Region (for regional cluster) or zone | `string` | `"us-central1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | GKE cluster name | `string` | `"gke-primary"` | no |
| <a name="input_gke_release_channel"></a> [gke\_release\_channel](#input\_gke\_release\_channel) | GKE release channel (RAPID \| REGULAR \| STABLE) | `string` | `"REGULAR"` | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | CIDRs allowed to access the control plane | <pre>list(object({<br/>    cidr_block   = string<br/>    display_name = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_block": "10.0.0.0/8",<br/>    "display_name": "corp"<br/>  }<br/>]</pre> | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | VPC name | `string` | `"vpc-gke"` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Initial node count per zone | `number` | `2` | no |
| <a name="input_node_machine_type"></a> [node\_machine\_type](#input\_node\_machine\_type) | Node pool machine type | `string` | `"e2-standard-4"` | no |
| <a name="input_pods_secondary_cidr"></a> [pods\_secondary\_cidr](#input\_pods\_secondary\_cidr) | Secondary range for GKE Pods (alias IP) | `string` | `"10.20.0.0/16"` | no |
| <a name="input_private_cluster"></a> [private\_cluster](#input\_private\_cluster) | Enable private nodes & private control plane endpoint | `bool` | `true` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Default region for regional resources | `string` | `"us-central1"` | no |
| <a name="input_services_secondary_cidr"></a> [services\_secondary\_cidr](#input\_services\_secondary\_cidr) | Secondary range for GKE Services (alias IP) | `string` | `"10.30.0.0/20"` | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | Primary subnet CIDR for nodes | `string` | `"10.10.0.0/20"` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Subnet for GKE nodes | `string` | `"subnet-gke"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | n/a |
| <a name="output_node_pool_name"></a> [node\_pool\_name](#output\_node\_pool\_name) | n/a |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | n/a |