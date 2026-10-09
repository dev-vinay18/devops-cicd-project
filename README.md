# DevOps CI/CD Project: Jenkins -> Docker Hub -> EC2

GitHub push -> (webhook) -> Jenkins builds image -> pushes to Docker Hub (`instantprachi`) -> EC2 server pulls and runs it.

## Files
| Task | File(s) |
|---|---|
| Terraform: EC2, ports 22/80, Docker via user_data | `terraform/` |
| Ansible: install Docker, pull image, run container | `ansible/playbook.yml` |
| Docker Compose: nginx static site + optional watchtower | `docker-compose.yml`, `docker-compose.dev.yml` |
| Deploy to EC2 manually | Step 3 below |
| Jenkins declarative pipeline | `Jenkinsfile` |
| GitHub webhook | Step 5 below |

## Placeholders to change first
- `terraform/terraform.tfvars` -> `key_name` (an existing EC2 key pair)
- `Jenkinsfile` -> `REPO_URL`
- `ansible/inventory.ini` -> EC2 public IP and key path
- If your Docker Hub repo name is not `static-site`, update it in `Jenkinsfile`, `playbook.yml`, `docker-compose.yml`

## 1. Terraform: create the EC2 instance
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit key_name
terraform init
terraform plan
terraform apply
terraform output public_ip
```
Run `terraform destroy` when finished to avoid charges.

## 2. Jenkins: build and push the image (do this before Ansible/deploy)
1. Install plugins: Git, GitHub, Pipeline, Credentials Binding.
2. Add credentials: Manage Jenkins -> Credentials -> *Username with password*, ID `dockerhub-creds` (Docker Hub username + access token).
3. The Jenkins machine needs Docker, and the `jenkins` user must be in the docker group:
   `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins`
4. Create a Pipeline job -> "Pipeline script from SCM" -> your repo, branch `main`, script path `Jenkinsfile`.
5. Click Build Now once. Confirm the image appears on Docker Hub.

## 3. Deploy to EC2 manually (SSH)
```bash
ssh -i my-keypair.pem ec2-user@<EC2_PUBLIC_IP>
sudo docker pull instantprachi/static-site:latest
sudo docker run -d --name static-site --restart always -p 80:80 instantprachi/static-site:latest
```
Open `http://<EC2_PUBLIC_IP>` in a browser. (Use `-p 8080:80` for port 8080, but then you must open 8080 in the security group.)

## 4. Ansible: same deployment, automated
```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible -i inventory.ini web -m ping
ansible-playbook -i inventory.ini playbook.yml
```
If you already ran Step 3, remove that container first: `sudo docker rm -f static-site`.

## 5. GitHub webhook
1. Jenkins job -> Configure -> Build Triggers -> tick **GitHub hook trigger for GITScm polling**.
2. GitHub repo -> Settings -> Webhooks -> Add webhook:
   - Payload URL: `http://<JENKINS_HOST>:8080/github-webhook/` (keep the trailing slash)
   - Content type: `application/json`
   - Event: **Just the push event**
3. Push a commit to `main`. The Jenkins job should start by itself.

Jenkins must be reachable from the internet (public IP or a tunnel such as ngrok).

## Docker Compose
```bash
# Dev: serves ./site on http://localhost:8080
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Prod: runs your Docker Hub image on port 80
docker compose up -d

# Prod + watchtower auto-updates (checks every 5 minutes)
docker compose --profile autoupdate up -d
```

---

## Extra modules added
| Module | What it adds |
|---|---|
| Elastic IP (Terraform) | Stable public IP so the live URL survives stop/start |
| CloudWatch + SNS (`monitoring.tf`) | CPU > 80% and status-check-failed alarms with optional email alerts (`alert_email`) |
| Docker HEALTHCHECK | Docker reports container health (`docker ps` shows `healthy`) |
| Jenkins Deploy + Smoke Test stages | Full CI/CD: a push to `main` builds, pushes, deploys to EC2 and verifies the site responds |
| `.gitignore` | Keeps keys, `terraform.tfvars` and state files out of the public repo |

Extra Jenkins setup for the Deploy stage: install the **SSH Agent** plugin and add a credential of kind *SSH Username with private key* with ID `ec2-ssh-key` (user `ec2-user`, your `.pem` contents).

## Architecture
GitHub push -> webhook -> Jenkins (build, push, deploy, smoke test) -> Docker Hub -> EC2 (Terraform, Elastic IP, Docker) -> CloudWatch alarms -> SNS email

## Live URL
http://<elastic-ip>
