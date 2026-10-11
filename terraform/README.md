# terraform/

One VM, one data disk, one static IP, plus the IAM plumbing for keyless deploys from GitHub Actions.

| File | What it creates |
|------|-----------------|
| `apis.tf` | Enables Compute, Secret Manager, IAM, STS, IAP (and DNS when used) |
| `network.tf` | Dedicated VPC, firewall for 80/443 from anywhere and 22 from IAP only |
| `vm.tf` | Static IP, `pd-balanced` data disk with daily snapshots, e2-small Ubuntu VM with OS Login |
| `secrets.tf` | `ghost-env` secret (the `.env` file) readable by the VM |
| `github.tf` | Workload Identity pool/provider scoped to this repo and the `ghost-deploy` service account |
| `dns.tf` | Optional A record in an existing Cloud DNS zone |
| `cloud-init.yaml` | First boot: Docker, data disk mount, swap, log rotation |

```sh
cp terraform.tfvars.example terraform.tfvars   # edit project_id etc.
terraform init
terraform plan
terraform apply
terraform output
```

The data disk has `prevent_destroy = true`. Destroying everything requires removing that first on purpose.
