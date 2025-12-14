# AKS Terraform Setup - Environment Variables

To run Terraform commands for the AKS cluster, you need to set the Azure subscription ID environment variable.

## Option 1: Set via command line (temporary)

```bash
export ARM_SUBSCRIPTION_ID="47ab116c-8c15-4453-b06a-3fecd09ebda9"

# Then run terraform commands
terraform plan
terraform apply
```

## Option 2: Add to your shell profile (permanent)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Azure Terraform
export ARM_SUBSCRIPTION_ID="47ab116c-8c15-4453-b06a-3fecd09ebda9"
```

Then reload:
```bash
source ~/.zshrc
```

## Option 3: Create .env file (recommended for projects)

Create a file named `.env` in the aks directory:

```bash
export ARM_SUBSCRIPTION_ID="47ab116c-8c15-4453-b06a-3fecd09ebda9"
```

Before running terraform, source it:

```bash
cd /Users/ricardotrentin/Documents/2025/kuburnetes/aks
source .env
terraform plan
```

## Option 4: Use terraform.tfvars (alternative)

Create `terraform.tfvars` in the aks directory:

```hcl
# Note: This is not recommended for sensitive values like subscription IDs
# Use environment variables instead
```

## How It Works

- The root `providers.tf` declares the Azure provider without a specific subscription
- Terraform automatically picks up the subscription ID from the `ARM_SUBSCRIPTION_ID` environment variable
- The `module.aks_production` uses its own `subscription_id` variable (passed from main.tf locals)
- This dual approach gives flexibility: root operations use environment subscription, module operations use specified subscription

## Testing

```bash
# Verify your subscription is set
az account show
echo $ARM_SUBSCRIPTION_ID

# Then run terraform
terraform validate
terraform plan
terraform apply
```

## Troubleshooting

If you get "subscription ID could not be determined":

1. Check if you're logged into Azure:
   ```bash
   az login
   ```

2. Verify the subscription ID:
   ```bash
   az account show --query id -o tsv
   ```

3. Set the environment variable:
   ```bash
   export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   ```

4. Try terraform again:
   ```bash
   terraform plan
   ```
