data "google_client_config" "provider" {}

# Automatically fetch current machine's public IP
data "http" "current_ip" {
  url = "https://api.ipify.org"
}
