# DevOps CI/CD Project: GitHub → Jenkins → Docker Hub → AWS EC2

A DevOps project that automates Docker image building, publishing, and deployment using Jenkins, Docker Hub, AWS EC2, and GitHub Webhooks.

The project also includes Terraform infrastructure provisioning, Ansible configuration management, Docker Compose, and monitoring with CloudWatch and SNS.

## 🌐 Live Demo

- **Live Website:** http://13.201.20.175
- **GitHub Repository:** https://github.com/dev-vinay18/devops-cicd-project
- **Docker Hub Image:** https://hub.docker.com/r/vinayw123/static-site

> **Note:** The website currently uses HTTP. HTTPS has not been configured.

## 🏗️ Architecture

```text
Developer Pushes Code to GitHub
              |
              v
       GitHub Webhook
              |
              v
       Jenkins Pipeline
              |
              v
       Checkout Source Code
              |
              v
      Build Docker Image
              |
              v
       Push to Docker Hub
     vinayw123/static-site
              |
              v
       Connect to AWS EC2
              |
              v
       Pull Latest Image
              |
              v
      Run Docker Container
              |
              v
          Smoke Test
              |
              v
      Live Website on EC2
```

Additional infrastructure and configuration management components include Terraform, Ansible, Docker Compose, CloudWatch, and SNS.

## 🛠️ Technologies Used

- **Cloud:** AWS EC2, VPC, Security Groups, Elastic IP
- **Infrastructure as Code:** Terraform
- **Configuration Management:** Ansible
- **Containerization:** Docker
- **Container Orchestration:** Docker Compose
- **CI/CD:** Jenkins Declarative Pipeline
- **Container Registry:** Docker Hub
- **Version Control:** Git and GitHub
- **Monitoring:** AWS CloudWatch and SNS
- **Operating System:** Linux
- **Scripting:** Bash

## 📁 Project Structure

```text
devops-cicd-project/
│
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── requirements.yml
│
├── terraform/
│   ├── main.tf
│   ├── monitoring.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
│
├── site/
│
├── Dockerfile
├── docker-compose.yml
├── docker-compose.dev.yml
├── Jenkinsfile
├── .gitignore
└── README.md
```

---

## 1. 🐳 Docker: Build and Run the Website

The application uses Nginx to serve the static website.

### Build the Docker Image

```bash
docker build -t vinayw123/static-site:latest .
```

### Run the Container

```bash
docker run -d \
  --name static-site \
  --restart always \
  -p 8080:80 \
  vinayw123/static-site:latest
```

### Access the Website

Open the following URL in your browser:

```text
http://localhost:8080
```

### Stop and Remove the Container

```bash
docker rm -f static-site
```

---

## 2. ☁️ Terraform: Provision AWS Infrastructure

Terraform provisions the EC2 infrastructure and supporting AWS resources.

### Infrastructure Components

- EC2 instance
- Security Group
- SSH access restricted to an authorized IP address
- HTTP access on port 80
- Docker installation through EC2 user data
- Elastic IP
- CloudWatch alarms
- Optional SNS email notifications

### Prerequisites

Install and configure:

- Terraform
- AWS CLI
- AWS account with appropriate IAM permissions
- An existing EC2 key pair

### Step 1: Navigate to the Terraform Directory

```bash
cd terraform
```

### Step 2: Create the Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure the required values, including:

- EC2 key pair name
- SSH allowed CIDR

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Validate the Configuration

```bash
terraform validate
```

### Step 5: Review the Infrastructure Plan

```bash
terraform plan
```

### Step 6: Create the Infrastructure

```bash
terraform apply
```

Review the proposed changes and confirm when prompted.

### Step 7: Retrieve the Public IP

```bash
terraform output public_ip
```

### Clean Up Resources

AWS resources can incur charges. After confirming that the website and any required services are no longer needed, destroy the infrastructure if appropriate.

```bash
terraform destroy
```

> **Important:** Do not destroy resources while you still need the live website or Jenkins environment.

---

## 3. 🔄 Jenkins: Continuous Integration and Deployment

Jenkins automates the application build, Docker image publishing, and deployment to EC2.

### Jenkins Pipeline Stages

The declarative `Jenkinsfile` implements the following stages:

1. **Checkout:** Retrieves the source code from GitHub.
2. **Build Docker Image:** Builds the application image and tags it with the Jenkins build number and `latest`.
3. **Push to Docker Hub:** Publishes both image tags.
4. **Deploy to EC2:** Connects to EC2 over SSH, pulls the latest image, removes the previous application container if present, and starts the updated container.
5. **Smoke Test:** Checks whether the deployed website responds.
6. **Post Actions:** Logs out of Docker Hub after the pipeline.

### Docker Hub Repository

The project publishes images to:

```text
vinayw123/static-site
```

Example image tags:

```text
vinayw123/static-site:6
vinayw123/static-site:latest
```

The numerical tag corresponds to the Jenkins build number.

### Jenkins Credentials

Configure the following credentials in Jenkins:

| Credential ID | Credential Type | Purpose |
|---|---|---|
| `dockerhub-cred` | Username with password | Docker Hub authentication |
| `ec2-ssh-key` | SSH Username with private key | SSH access to EC2 |

**Docker Hub credentials:**

- Username: `vinayw123`
- Password field: Docker Hub access token

**EC2 SSH credentials:**

- Username: `ubuntu`
- Private key: The key corresponding to the public key authorized on the EC2 instance

> Never commit passwords, access tokens, private keys, or other secrets to GitHub.

### Jenkins Job Configuration

1. Create a **Pipeline** job named `devops-cicd-project`.
2. Select **Pipeline script from SCM**.
3. Select **Git** as the SCM.
4. Enter the repository URL:

   ```text
   https://github.com/dev-vinay18/devops-cicd-project.git
   ```

5. Set the branch to:

   ```text
   */main
   ```

6. Set the Script Path to:

   ```text
   Jenkinsfile
   ```

7. Ensure Docker is installed on the Jenkins machine and the Jenkins user has permission to execute Docker commands.
8. Install the **SSH Agent** plugin.
9. Save the job and click **Build Now**.

### Verified Pipeline Result

The Jenkins pipeline has successfully completed these operations:

- Checked out the GitHub repository.
- Built the Docker image.
- Pushed the image tags to Docker Hub.
- Connected to EC2 over SSH.
- Pulled the latest image.
- Started the application container.
- Passed the remote smoke test.

The latest verified build completed with:

```text
Finished: SUCCESS
```

---

## 4. 🔗 GitHub Webhook: Automatic Pipeline Trigger

The project uses a GitHub webhook to notify Jenkins when code is pushed to the repository.

### Configure Jenkins

1. Open the `devops-cicd-project` job.
2. Click **Configure**.
3. Open **Build Triggers**.
4. Enable:

   ```text
   GitHub hook trigger for GITScm polling
   ```

5. Save the configuration.

### Configure GitHub

Open the repository:

```text
Settings → Webhooks
```

The webhook payload URL should follow this format:

```text
http://<JENKINS_PUBLIC_IP>:8080/github-webhook/
```

Configure the following settings:

| Setting | Value |
|---|---|
| Content type | `application/json` |
| Events | Just the push event |
| Active | Enabled |

GitHub must be able to reach the Jenkins webhook endpoint.

### Verify Automatic Triggering

1. Make a small change to `README.md`.
2. Commit the change directly to the `main` branch.
3. Open the Jenkins job.
4. Check whether a new build starts without clicking **Build Now**.

> **Verification status:** The existing GitHub webhook returned HTTP 200. Confirm automatic triggering by pushing a new commit and checking whether Jenkins starts a build automatically.

---

## 5. ⚙️ Ansible: Docker Installation and Deployment

Ansible automates Docker installation, image retrieval, and container deployment on the target server.

The playbook is located at:

```text
ansible/playbook.yml
```

### Prerequisites

- Ansible installed on the control machine
- SSH connectivity to the EC2 instance
- Correct EC2 IP address and SSH private-key path

Update `ansible/inventory.ini` with the correct EC2 public IP, username, and private-key path.

For the current Ubuntu EC2 instance, use the username:

```text
ubuntu
```

### Step 1: Navigate to the Ansible Directory

```bash
cd ansible
```

### Step 2: Install Required Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### Step 3: Test Connectivity

```bash
ansible -i inventory.ini web -m ping
```

### Step 4: Run the Playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

### Expected Playbook Tasks

The playbook should:

1. Install Docker if required.
2. Pull `vinayw123/static-site:latest`.
3. Start the container.
4. Configure the container to restart automatically.
5. Publish the website on port 80.

Ensure that the playbook uses the correct Docker Hub image and appropriate Ubuntu package-management commands.

---

## 6. 📦 Docker Compose

Docker Compose provides a convenient way to run the website container.

The repository includes:

```text
docker-compose.yml
docker-compose.dev.yml
```

### Development Environment

Run the development configuration:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.dev.yml \
  up -d
```

The development website is intended to be accessible at:

```text
http://localhost:8080
```

### Production Environment

Run the production configuration:

```bash
docker compose up -d
```

The production service should use:

```text
vinayw123/static-site:latest
```

The service should publish container port 80 on host port 80.

### Optional Automatic Image Updates

If Watchtower is configured in the Compose file, start the optional automatic-update profile:

```bash
docker compose --profile autoupdate up -d
```

This feature depends on the actual Watchtower service configuration in the Compose file.

---

## 7. 📊 Monitoring with CloudWatch and SNS

The Terraform monitoring configuration includes CloudWatch alarms for:

- High EC2 CPU utilization above 80%.
- EC2 instance status-check failures.

An optional SNS email notification can be configured using the `alert_email` variable.

### Enable Email Notifications

1. Configure the `alert_email` variable.
2. Apply the Terraform configuration.
3. Check your email for the SNS subscription confirmation.
4. Confirm the subscription.

These alarms help identify high CPU usage and EC2 instance health problems.

---

## 8. ❤️ Docker Health Check

The Dockerfile includes an Nginx health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/ > /dev/null || exit 1
```

### Check Container Health

```bash
docker ps
```

### Inspect Health Information

```bash
docker inspect \
  --format='{{json .State.Health}}' \
  static-site
```

The health status depends on whether the container's health check is passing.

---

## 9. 🛠️ Troubleshooting

### Website Does Not Open

Check the EC2 Security Group:

- HTTP port 80 must allow the intended website traffic.
- SSH port 22 should remain restricted to an authorized IP address.
- Confirm that the EC2 instance has a public IP and appropriate network routing.

Check the container:

```bash
sudo docker ps
```

View application logs:

```bash
sudo docker logs --tail 50 static-site
```

Test Nginx locally on EC2:

```bash
curl -I http://localhost/
```

### Jenkins Pipeline Fails

Review the Jenkins **Console Output** and identify the stage that failed.

Check:

- Docker availability and permissions
- Docker Hub credentials
- SSH credential ID `ec2-ssh-key`
- EC2 SSH connectivity
- Container status
- Port 80 availability

### GitHub Webhook Does Not Trigger a Build

Check:

- Webhook URL and trailing slash
- GitHub recent delivery status
- Jenkins GitHub webhook trigger setting
- Jenkins reachability from the internet
- Whether the push targets the expected branch

> A successful webhook HTTP response does not, by itself, prove that Jenkins started a build.

---

## 🔐 Security Considerations

- Keep private SSH keys out of GitHub.
- Keep `terraform.tfvars` and Terraform state files out of version control.
- Use IAM credentials with appropriate permissions.
- Use Docker Hub access tokens instead of account passwords.
- Restrict SSH access to trusted IP addresses.
- Protect Jenkins with authentication and appropriate network controls.
- Use HTTPS and secure webhook practices for production environments.
- Avoid exposing Jenkins administration interfaces unnecessarily.

---

## 🎯 Conclusion

This project demonstrates a DevOps workflow using GitHub, Jenkins, Docker, Docker Hub, AWS EC2, Terraform, Ansible, Docker Compose, CloudWatch, and SNS.

It combines infrastructure provisioning, configuration management, containerization, continuous integration, deployment automation, and basic monitoring.

The core Jenkins build, image publishing, EC2 deployment, and smoke test have been verified successfully. Remaining tasks should be tested against the internship requirements before final submission.

---

## 🌐 Live Website

**URL:** http://13.201.20.175.20.175 the internship requirements before final submission.
## Live URL
http://<elastic-ip>
