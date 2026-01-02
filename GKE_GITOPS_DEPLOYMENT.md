# GKE GitOps Deployment Options - Summary

You now have **two complete, production-ready GitOps solutions** for your GKE cluster:

## 🚀 Option 1: ArgoCD (Existing)

**Location:** `/gke/argocd/`

- ✅ Fully configured and ready to deploy
- ✅ Built-in web UI with rich features
- ✅ Root application for bootstrap deployment
- ✅ Static external IP reservation
- ✅ Helm chart v5.51.6 (configurable)

### Quick Deploy

```bash
cd gke/argocd
# Values already in terraform.tfvars
terraform plan
terraform apply
```

### Access

```bash
# Get the external IP
terraform output argocd_lb_ip

# Access UI at http://<IP>:80
```

---

## 🌊 Option 2: Flux v2 + Weave GitOps (New)

**Location:** `/gke/flux/`

- ✨ Brand new, lightweight alternative
- ✨ Weave GitOps web UI included
- ✨ CNCF Graduated project
- ✨ Minimal resource footprint
- ✨ Native Kubernetes-first design

### Quick Deploy

```bash
cd gke/flux
cp terraform.tfvars.example terraform.tfvars
# Edit with your values
terraform init
terraform plan
terraform apply
```

### Access

```bash
# Get the external IP and admin password
terraform output weave_access_url
terraform output -raw weave_admin_password

# Access UI at http://<IP>
# Username: admin
# Password: (from command above)
```

---

## 📊 Quick Comparison

| Feature | ArgoCD | Flux |
|---------|--------|------|
| **Setup Complexity** | Low (config exists) | Low (template ready) |
| **UI Quality** | Excellent, feature-rich | Good (Weave GitOps) |
| **Learning Curve** | Medium | Low |
| **Resource Usage** | Medium (~500m CPU) | Low (~100m CPU) |
| **Git Sync** | Pull-based | Event-driven |
| **SOPS Support** | Via plugin | Native |
| **Community Size** | Large | Growing |
| **CNCF Status** | Sandbox → Incubating | Graduated ✓ |

---

## 🎯 Decision Guide

### Choose **ArgoCD** if:
- Team already familiar with it
- Need the most mature solution
- Want the richest UI experience
- Need enterprise features
- Managing multiple clusters (good multi-cluster support)

### Choose **Flux** if:
- Prefer lightweight, minimal footprint
- Want native Kubernetes approach
- Team values GitOps simplicity
- Need SOPS encryption support
- Evaluating modern CNCF-graduated project

### Run **Both** for evaluation:
- Deploy both in parallel
- Different namespaces (argocd, flux-system)
- Let your team evaluate both
- Choose after 1-2 weeks of usage

---

## 📁 File Locations

### ArgoCD Files
```
kuburnetes/gke/
├── argocd/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── output.tf
│   ├── data.tf
│   ├── terraform.tfvars
│   └── terraform.tfstate (after apply)
```

### Flux Files
```
kuburnetes/gke/
├── flux/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── output.tf
│   ├── data.tf
│   ├── terraform.tfvars.example
│   ├── README.md
│   └── .terraform/
```

### Comparison Documentation
```
kuburnetes/gke/
├── FLUX_VS_ARGOCD.md              (detailed comparison)
└── GKE_GITOPS_DEPLOYMENT.md       (this file)
```

---

## ⚙️ Configuration Requirements

### Both Solutions Need:

1. **GKE Cluster Access**
   ```bash
   # Ensure your kubeconfig is configured
   kubectl cluster-info
   kubectl get nodes
   ```

2. **GCP Credentials**
   ```bash
   gcloud auth application-default login
   ```

3. **GitHub Repository**
   - Your GitOps configurations stored in GitHub
   - Personal Access Token with `repo` scope

4. **Terraform State Backend**
   - GCS bucket: `test-lab-tf-state`
   - Prefix: `gke-gitops` (ArgoCD) or `gke-gitops-flux` (Flux)
   - Both configured in `providers.tf`

---

## 🚀 Step-by-Step Deployment

### For ArgoCD:
```bash
# 1. Navigate to directory
cd /Users/ricardotrentin/Documents/2025/kuburnetes/gke/argocd

# 2. Check variables (should already be configured)
cat terraform.tfvars

# 3. Plan deployment
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan

# 5. Get access info
terraform output argocd_lb_ip
```

### For Flux:
```bash
# 1. Navigate to directory
cd /Users/ricardotrentin/Documents/2025/kuburnetes/gke/flux

# 2. Copy example config
cp terraform.tfvars.example terraform.tfvars

# 3. Edit configuration
# Update: config_context, project, region, github_token, github_owner, github_repo
nano terraform.tfvars  # or use your editor

# 4. Initialize with GCS backend
terraform init

# 5. Plan deployment
terraform plan -out=tfplan

# 6. Apply
terraform apply tfplan

# 7. Get access info
terraform output weave_access_url
terraform output -raw weave_admin_password
```

---

## 📡 Understanding the Deployment

### What Gets Deployed

**ArgoCD:**
1. `argocd` namespace
2. ArgoCD server, controller, repo-server, redis pods
3. LoadBalancer service with static IP
4. ArgoCD root application for bootstrap
5. RBAC and service accounts

**Flux:**
1. `flux-system` namespace with:
   - source-controller (fetches from Git)
   - kustomize-controller (applies manifests)
   - helm-controller (manages Helm charts)
   - notification-controller (sends alerts)
2. `weave-gitops` namespace with:
   - Weave GitOps UI pod
   - LoadBalancer service with static IP
3. GitRepository CRD (points to your GitHub repo)
4. Kustomization CRD (defines what to sync)
5. Secrets (GitHub token)
6. RBAC and service accounts

---

## 🔄 Git Repository Structure

Both solutions expect your Git repository to contain Kubernetes manifests. Example structure:

```
k8sgitops/
├── applications/           (default sync path)
│   ├── app1/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── app2/
│   │   └── kustomization.yaml
│   └── ...
├── .flux/                  (Flux specific configs)
│   ├── defaults/
│   └── sync/
└── README.md
```

Both ArgoCD and Flux will:
- Poll your repository (default: 1-5 minute interval)
- Detect changes automatically
- Apply manifests to cluster
- Maintain desired state

---

## 🛡️ Security Considerations

### Both Solutions:
- ✅ GitHub token stored as Kubernetes secret
- ✅ RBAC configured appropriately
- ✅ Service accounts with limited permissions
- ✅ Secrets encrypted at rest (GKE default)

### Additional for ArgoCD:
- Consider enabling ArgoCD RBAC
- Review server service exposure

### Additional for Flux:
- Weave GitOps requires admin credentials
- Change default password immediately
- Consider SOPS for encrypted secrets

---

## 📈 Monitoring & Maintenance

### Monitor Deployments:
```bash
# Check if pods are running
kubectl get pods -n argocd        # for ArgoCD
kubectl get pods -n flux-system   # for Flux
kubectl get pods -n weave-gitops  # for Weave

# View logs
kubectl logs -n flux-system deployment/source-controller

# Check synchronization status
flux status
```

### Update Chart Versions:
```bash
# Edit terraform.tfvars
# Change flux_chart_version or weave_chart_version

terraform plan
terraform apply
```

### Destroy (if needed):
```bash
# ArgoCD
cd gke/argocd && terraform destroy

# Flux
cd gke/flux && terraform destroy
```

---

## 🎓 Learning Path

### New to GitOps?
1. Start with Flux (simpler, Git-first)
2. Read: `gke/flux/README.md`
3. Deploy and explore
4. Try ArgoCD after 1-2 weeks

### ArgoCD Experience?
1. Review Flux comparison: `FLUX_VS_ARGOCD.md`
2. Deploy Flux as alternative
3. Compare feature parity
4. Choose based on team preference

### Want Both?
1. Deploy ArgoCD first (config ready)
2. Deploy Flux second (new learning)
3. Run parallel for 2-4 weeks
4. Team votes on preferred solution

---

## 🆘 Troubleshooting

### Common Issues

**"kubeconfig not found"**
```bash
# Ensure kubeconfig_path points to valid file
ls -la ~/.kube/config
cat ~/.kube/config | head -5
```

**"Cannot authenticate to GCP"**
```bash
gcloud auth application-default login
terraform init  # reinitialize
```

**"GitHub token not working"**
```bash
# Verify token has repo scope
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Check that repo is accessible
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/repos/OWNER/REPO
```

**"Pods not starting"**
```bash
# Check events
kubectl get events -n flux-system --sort-by='.lastTimestamp'

# View pod logs
kubectl logs -n flux-system -l app=source-controller
```

See individual READMEs for detailed troubleshooting.

---

## 📞 Support Resources

- **Flux Documentation:** https://fluxcd.io/docs/
- **Weave GitOps Docs:** https://docs.weave.works/docs/gitops/
- **ArgoCD Documentation:** https://argo-cd.readthedocs.io/
- **GKE Networking:** https://cloud.google.com/kubernetes-engine/docs/

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] GKE cluster is running and accessible
- [ ] `kubectl` configured correctly
- [ ] GitHub repository ready with GitOps configs
- [ ] GitHub PAT created with repo scope
- [ ] GCS bucket exists with proper permissions

### ArgoCD Deployment
- [ ] terraform plan shows expected resources
- [ ] terraform apply completes successfully
- [ ] Pods running in argocd namespace
- [ ] External IP assigned
- [ ] UI accessible at http://<IP>

### Flux Deployment
- [ ] terraform init with GCS backend succeeds
- [ ] terraform plan shows expected resources
- [ ] terraform apply completes successfully
- [ ] Pods running in flux-system and weave-gitops
- [ ] External IP assigned
- [ ] UI accessible at http://<IP>

### Post-Deployment
- [ ] GitRepository status shows connected
- [ ] Kustomization shows successful reconciliation
- [ ] Applications deployed from your repository
- [ ] Web UI shows deployment status

---

## 🎉 You're Ready!

Both GitOps solutions are fully configured and ready to deploy. Choose your path:

```bash
# Option 1: Deploy ArgoCD
cd gke/argocd
terraform apply

# Option 2: Deploy Flux
cd gke/flux
terraform apply

# Option 3: Evaluate both
# Deploy both in sequence, compare over 2 weeks
```

Good luck with your GitOps implementation! 🚀
