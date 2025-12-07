
# Authenticate & select the project
gcloud auth application-default login
gcloud config set project my-gcp-project

terraform fmt
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan

# Configure kubeconfig and test
gcloud container clusters get-credentials gke-primary --region us-central1 --project my-gcp-project
kubectl get nodes
