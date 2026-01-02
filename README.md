# GKE Cluster and GitOps with Terraform

This project provides a comprehensive setup for provisioning a Google Kubernetes Engine (GKE) cluster using Terraform. It also includes two production-ready GitOps solutions for deploying and managing applications on the cluster: ArgoCD and Flux.

## Usage

For detailed instructions on how to deploy and manage the GitOps solutions, please refer to the [GITOPS_README.md](GITOPS_README.md) file.

## CI/CD

This project uses GitHub Actions for continuous integration and deployment. The workflow is defined in the `.github/workflows/terraform.yml` file.

The workflow performs the following steps:
1.  Checks out the code.
2.  Installs Terraform.
3.  Authenticates to Google Cloud using Workload Identity Federation.
4.  Runs `terraform init` to initialize the Terraform working directory.
5.  Runs `terraform plan` on pull requests to preview the changes.
6.  Runs `terraform apply` on pushes to the `main` branch to apply the changes.

**Note:** There is a potential inconsistency in the `terraform.yml` file. The `TF_WORKING_DIR` environment variable is set to `./gke`, but the Terraform commands are executed in the `infra` directory. This might need to be corrected to `gke`.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement_google) | >= 5.33.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement_google-beta) | >= 5.33.0 |


## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.12.0 |

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
| [google_gke_backup_backup_plan.plan](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_backup_backup_plan) | resource |
| [google_service_account.nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_client_config.provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_name"></a> [backup\_name](#input\_backup\_name) | The name of the application to include in the GKE backup. | `string` | `"default"` | no |
| <a name="input_backup_namespace"></a> [backup\_namespace](#input\_backup\_namespace) | The namespace to include in the GKE backup. | `string` | `"default"` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Number of days to retain backups. | `number` | `7` | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | Whether to enable GKE Backup for the cluster. | `bool` | `true` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Whether to create a private endpoint for the GKE cluster master. | `bool` | `true` | no |
| <a name="input_gke_release_channel"></a> [gke\_release\_channel](#input\_gke\_release\_channel) | GKE release channel for the cluster. | `string` | `"REGULAR"` | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | List of authorized networks for the GKE master. | <pre>list(object({<br/>    cidr_block   = string<br/>    display_name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#input\_master\_ipv4\_cidr\_block) | CIDR block for GKE master authorized networks | `string` | `"172.16.0.0/28"` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Initial number of nodes for the default node pool. | `number` | `1` | no |
| <a name="input_node_machine_type"></a> [node\_machine\_type](#input\_node\_machine\_type) | Machine type for the GKE nodes. | `string` | n/a | yes |
| <a name="input_node_pool_max_count"></a> [node\_pool\_max\_count](#input\_node\_pool\_max\_count) | Maximum number of nodes for the default node pool autoscaling. | `number` | `3` | no |
| <a name="input_node_pool_min_count"></a> [node\_pool\_min\_count](#input\_node\_pool\_min\_count) | Minimum number of nodes for the default node pool autoscaling. | `number` | `1` | no |
| <a name="input_pods_secondary_cidr"></a> [pods\_secondary\_cidr](#input\_pods\_secondary\_cidr) | Secondary range for Pods (alias IP) | `string` | n/a | yes |
| <a name="input_private_cluster"></a> [private\_cluster](#input\_private\_cluster) | Whether to create a private GKE cluster. | `bool` | `true` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Default region | `string` | n/a | yes |
| <a name="input_services_secondary_cidr"></a> [services\_secondary\_cidr](#input\_services\_secondary\_cidr) | Secondary range for Services (alias IP) | `string` | n/a | yes |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | Primary subnet CIDR for nodes | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | n/a |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | n/a |


