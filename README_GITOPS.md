# GKE GitOps Solutions - Documentation Index

This directory contains **two production-ready GitOps solutions** for your Google Kubernetes Engine cluster.

## 📚 Documentation Structure

### 📖 Main Guides

1. **[GKE_GITOPS_DEPLOYMENT.md](./GKE_GITOPS_DEPLOYMENT.md)** ⭐ START HERE
   - Overview of both solutions
   - Quick decision matrix
   - Step-by-step deployment instructions
   - Common troubleshooting

2. **[FLUX_VS_ARGOCD.md](./FLUX_VS_ARGOCD.md)**
   - Detailed feature comparison
   - Operational differences
   - Performance metrics
   - Use case recommendations

### 📁 Solution Directories

#### ArgoCD (Existing)
- **Directory:** `./argocd/`
- **Status:** Ready to deploy
- **Documentation:** See main README in argocd/
- **Configuration:** Already populated in `argocd/terraform.tfvars`

#### Flux v2 + Weave GitOps (New)
- **Directory:** `./flux/`
- **Status:** Ready to deploy
- **Documentation:** [flux/README.md](./flux/README.md)
- **Configuration:** Template in `flux/terraform.tfvars.example`

---

## 🚀 Quick Start

### Deploy ArgoCD (Already Configured)
```bash
cd argocd
terraform plan
terraform apply
terraform output argocd_lb_ip
```

### Deploy Flux (New Alternative)
```bash
cd flux
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
terraform output weave_access_url
```

---

## 🤖 CI/CD

This project includes a GitHub Actions workflow to automate the deployment of the underlying GKE infrastructure. For more details on the CI/CD pipeline, please see the [CI/CD section in the main README.md](../README.md#cicd).

---


## 📊 Solution Comparison at a Glance

| Aspect | ArgoCD | Flux v2 |
|--------|--------|---------|
| **Setup Time** | 5 minutes | 10 minutes |
| **UI Complexity** | Rich, feature-full | Clean, simple (Weave) |
| **Resource Usage** | 500m CPU, 256Mi RAM | 100m CPU, 64Mi RAM |
| **Learning Curve** | Medium | Low |
| **CNCF Status** | Incubating | Graduated ✓ |
| **Best For** | Enterprise features | Simplicity & performance |

---

## 🎯 Choose Your Path

### Path A: Use Existing ArgoCD Setup
- ✅ Configuration already exists
- ✅ Fastest to deploy (1 command)
- ✅ Mature, feature-rich solution
- ⏱️ Time to deploy: 5 minutes

**Go To:** [./argocd/](./argocd/)

### Path B: Deploy New Flux Solution
- ✨ Modern, lightweight alternative
- ✨ CNCF graduated project
- ✨ Simpler operational model
- ⏱️ Time to deploy: 10 minutes

**Go To:** [./flux/](./flux/)

### Path C: Evaluate Both
- 🔀 Deploy ArgoCD first
- 🔀 Deploy Flux in parallel
- 🔀 Compare side-by-side
- ⏱️ Time to evaluate: 2 weeks

**Go To:** [GKE_GITOPS_DEPLOYMENT.md](./GKE_GITOPS_DEPLOYMENT.md#run-both-for-evaluation)

---

## 📋 Files in This Directory

```
gke/
├── README_GITOPS.md                    ← You are here
├── GKE_GITOPS_DEPLOYMENT.md           ← Complete deployment guide
├── FLUX_VS_ARGOCD.md                  ← Detailed comparison
│
├── argocd/                            ← ArgoCD solution
│   ├── README.md
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── output.tf
│   ├── data.tf
│   ├── terraform.tfvars
│   ├── terraform.tfstate
│   └── .terraform/
│
├── flux/                              ← Flux solution (NEW)
│   ├── README.md
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── output.tf
│   ├── data.tf
│   ├── terraform.tfvars.example
│   ├── .terraform/
│   └── .terraform.lock.hcl
│
├── [other files...]
└── terraform.tfstate                  ← Root state (if any)
```

---

## ✅ Pre-Deployment Checklist

- [ ] GKE cluster is running
- [ ] `kubectl cluster-info` works
- [ ] `gcloud auth application-default login` completed
- [ ] GitHub repository ready with GitOps configs
- [ ] GitHub Personal Access Token created
- [ ] GCS bucket exists: `test-lab-tf-state`

---

## 🚀 Deployment Commands

### Quick Deploy - ArgoCD
```bash
cd argocd && terraform apply && terraform output argocd_lb_ip
```

### Quick Deploy - Flux
```bash
cd flux && cp terraform.tfvars.example terraform.tfvars && \
# Edit terraform.tfvars, then:
terraform init && terraform apply && terraform output weave_access_url
```

---

## 📖 Documentation Map

### For Decision Making
1. [GKE_GITOPS_DEPLOYMENT.md](./GKE_GITOPS_DEPLOYMENT.md) - Overview & quick comparison
2. [FLUX_VS_ARGOCD.md](./FLUX_VS_ARGOCD.md) - Detailed analysis

### For ArgoCD Deployment
1. [argocd/README.md](./argocd/README.md) - ArgoCD-specific guide

### For Flux Deployment
1. [flux/README.md](./flux/README.md) - Flux-specific guide (350+ lines)

### For Operations
- See solution-specific READMEs for:
  - Monitoring commands
  - Troubleshooting
  - Updating configurations
  - Accessing web UIs

---

## 🔗 External Resources

### Flux v2
- [Official Documentation](https://fluxcd.io/docs/)
- [GitHub Repository](https://github.com/fluxcd/flux2)
- [CNCF Project Page](https://www.cncf.io/projects/flux/)

### Weave GitOps
- [Official Documentation](https://docs.weave.works/docs/gitops/)
- [GitHub Repository](https://github.com/weaveworks/weave-gitops)

### ArgoCD
- [Official Documentation](https://argo-cd.readthedocs.io/)
- [GitHub Repository](https://github.com/argoproj/argo-cd)

### GCP/GKE
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GKE Networking](https://cloud.google.com/kubernetes-engine/docs/concepts/network)

---

## 💬 FAQ

### Q: Which solution should I choose?

**A:** Depends on your needs:
- **ArgoCD** if you want the richest UI and most features
- **Flux** if you want simplicity and minimal footprint
- **Both** if you want to evaluate for 2 weeks

See [FLUX_VS_ARGOCD.md](./FLUX_VS_ARGOCD.md#use-case-recommendations) for detailed recommendations.

### Q: Can I run both simultaneously?

**A:** Yes! Deploy in separate namespaces:
- ArgoCD → `argocd` namespace
- Flux → `flux-system` and `weave-gitops` namespaces

They won't interfere with each other.

### Q: How much disk space do I need?

**A:** Minimal. Each solution is ~100-300MB of Kubernetes resources. Terraform state files are small.

### Q: Can I switch from one to the other later?

**A:** Yes. See [FLUX_VS_ARGOCD.md - Migration Path](./FLUX_VS_ARGOCD.md#migration-path).

### Q: What about production use?

**A:** Both are production-ready:
- ArgoCD: Mature, widely adopted
- Flux: CNCF Graduated, production-tested

Choose based on preference, not maturity.

---

## 🆘 Need Help?

### Troubleshooting
1. Check solution-specific README
2. Review error messages in Kubernetes events
3. Check pod logs: `kubectl logs -n <namespace>`
4. See Troubleshooting sections in READMEs

### Common Commands
```bash
# Check pods
kubectl get pods -n argocd
kubectl get pods -n flux-system

# View logs
kubectl logs -n flux-system -l app=source-controller

# Describe resources
kubectl describe -n flux-system gitrepository

# View events
kubectl get events -A --sort-by='.lastTimestamp'
```

---

## 📝 Summary

You have **two excellent GitOps solutions**, both fully configured and ready to deploy:

| Solution | Status | Type | Time to Deploy |
|----------|--------|------|-----------------|
| **ArgoCD** | Ready to use | Traditional | 5 min |
| **Flux v2** | Ready to use | Modern | 10 min |

**Next Step:** Read [GKE_GITOPS_DEPLOYMENT.md](./GKE_GITOPS_DEPLOYMENT.md) to choose and deploy your preferred solution.

Happy GitOps! 🚀
