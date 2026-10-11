# Creative Captains blog

Ghost 6 on a single GCP VM, deployed from this repo.

```
terraform/           VM, static IP, data disk + snapshots, firewall, Secret Manager, GitHub WIF
ghost/               Ghost's official Docker Compose stack (Ghost + MySQL + Caddy)
themes/              Custom themes, uploaded through the Ghost Admin API
scripts/             deploy.sh / fetch-env.sh run on the VM; import-theme.sh runs locally
.github/workflows/   deploy.yml (compose stack), deploy-theme.yml (themes)
```

How it fits together:

1. Terraform builds one `e2-small` Ubuntu VM with a separate data disk mounted at `/mnt/ghost-data`.
   Caddy terminates TLS with automatic Let's Encrypt certs, so there is no load balancer.
2. `ghost/.env` (secrets) lives in Secret Manager as `ghost-env`. It is never in git.
3. On push to `main`, GitHub Actions authenticates to GCP keylessly (Workload Identity Federation),
   copies `ghost/` to the VM over IAP SSH and runs `scripts/deploy.sh`, which fetches `.env`
   and runs `docker compose up -d`.
4. Theme changes under `themes/` are validated with gscan and uploaded with the Admin API.

## First-time setup

### 1. Push this repo to GitHub

```sh
gh repo create daemon4d-us/creative-captains-blog --private --source=. --push
```

If you use a different owner or name, set `github_repo` in `terraform/terraform.tfvars` to match.
The WIF provider only trusts that exact repository.

### 2. Create the infrastructure

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars   # set project_id
terraform init
terraform apply
terraform output
```

Note the `static_ip` and `github_variables` outputs.

### 3. DNS

`creativecaptains.com` is served by Cloud DNS (zone `creativecaptains` in project `reply-ai-490216`).
With `dns_managed_zone` and `dns_project` set in `terraform.tfvars`, Terraform creates the A record.
Otherwise add an `A` record for `blog.creativecaptains.com` pointing at `static_ip` by hand.
Wait until `dig +short blog.creativecaptains.com` returns the IP before deploying, or Caddy's
certificate request will fail and retry with backoff.

### 4. Secrets

```sh
cp ghost/.env.example ghost/.env
# edit: DATABASE_ROOT_PASSWORD and DATABASE_PASSWORD (openssl rand -hex 32), SMTP settings
gcloud secrets versions add ghost-env --data-file=ghost/.env --project <project_id>
```

SMTP is required for admin login emails and password resets. Any transactional provider works
(Mailgun, Postmark, SES, Resend). Newsletters are separate: Ghost sends bulk email only through
Mailgun, configured later in Ghost Admin > Settings > Email newsletter.

Database passwords cannot be changed after the first boot without rebuilding the data disk.

### 5. GitHub repository variables

In GitHub: Settings > Secrets and variables > Actions > Variables. Add each key from the
`github_variables` Terraform output:

| Variable | Value |
|----------|-------|
| `GCP_PROJECT_ID` | project id |
| `GCP_ZONE` | e.g. `us-west1-b` |
| `GCP_VM_NAME` | `ghost` |
| `GCP_WIF_PROVIDER` | `projects/<number>/locations/global/workloadIdentityPools/github/providers/github-oidc` |
| `GCP_DEPLOY_SA` | `ghost-deploy@<project>.iam.gserviceaccount.com` |
| `GHOST_URL` | `https://blog.creativecaptains.com` |

### 6. First deploy

Wait a couple of minutes after `terraform apply` for cloud-init to install Docker
(check with the `ssh_command` output and `cloud-init status --wait`). Then run the
**Deploy Ghost** workflow from the Actions tab, or push a change under `ghost/`.

Open `https://blog.creativecaptains.com/ghost` and create the owner account.

### 7. Admin API key (themes and Claude)

Ghost Admin > Settings > Integrations > Add custom integration (e.g. "GitHub Actions").
Copy the Admin API key and add it as a repository **secret** named `GHOST_ADMIN_API_KEY`.

For writing posts from Claude Desktop, create a second integration ("Claude") and give its
Admin API key and the site URL to a Ghost MCP server.

### 8. Theme

```sh
scripts/import-theme.sh source     # or casper
git add themes && git commit -m "Add Source theme" && git push
```

The workflow uploads it. Activate it once in Ghost Admin > Design & branding.

## Day two

| Task | How |
|------|-----|
| SSH | `terraform output -raw ssh_command` |
| Logs | `cd /opt/ghost && sudo docker compose logs -f ghost` |
| Update Ghost | Re-run the Deploy workflow; it pulls the latest `ghost:6-alpine` |
| Change config | Edit `ghost/.env` locally, `gcloud secrets versions add ghost-env --data-file=ghost/.env`, re-run Deploy |
| Backups | Daily snapshots of the data disk, kept 14 days (`gcloud compute snapshots list`) |
| Restore | Create a disk from a snapshot, point `google_compute_instance.this.attached_disk` at it, apply |
| Rebuild VM | `terraform taint google_compute_instance.this && terraform apply`; data disk and IP survive |

Rough cost: about $18/month in us-west1 (e2-small, static IP, 20 GB boot + 20 GB data disk, snapshots).

## Attribution

`ghost/compose.yml`, `ghost/caddy/snippets/*` and `ghost/mysql-init/*` come from
[TryGhost/ghost-docker](https://github.com/TryGhost/ghost-docker), MIT License, Ghost Foundation.
