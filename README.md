DevOps CI/CD Project: GitHub → Jenkins → Docker Hub → AWS EC2

A DevOps project that automates Docker image building, publishing, and deployment using Jenkins, Docker Hub, AWS EC2, and a GitHub webhook.

The project also includes Terraform infrastructure provisioning, Ansible configuration management, Docker Compose, and monitoring with CloudWatch and SNS.

Live Demo

* Live Website: http://13.201.20.175
* GitHub Repository: https://github.com/dev-vinay18/devops-cicd-project
* Docker Hub Image: https://hub.docker.com/r/vinayw123/static-site

The live website uses HTTP. HTTPS has not been configured.

Architecture

Developer pushes code to GitHub
              |
              v
       GitHub Webhook
              |
              v
       Jenkins Pipeline
              |
              v
       Checkout Source
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

Additional infrastructure and configuration management components include Terraform, Ansible, Docker Compose, CloudWatch, and SNS.

Technologies Used

* AWS EC2
* AWS VPC and Security Groups
* AWS Elastic IP
* AWS CloudWatch and SNS
* Terraform
* Ansible
* Docker
* Docker Compose
* Docker Hub
* Jenkins Declarative Pipeline
* Git and GitHub
* Linux and Bash

Project Structure

devops-cicd-project/
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── requirements.yml
├── terraform/
│   ├── main.tf
│   ├── monitoring.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
├── site/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.dev.yml
├── Jenkinsfile
├── .gitignore
└── README.md

1. Docker: Build the Website Image

The application uses Nginx to serve the static website.

Build the Docker image locally:

docker build -t vinayw123/static-site:latest .

Run the container:

docker run -d \
  --name static-site \
  --restart always \
  -p 8080:80 \
  vinayw123/static-site:latest

Open the website:

http://localhost:8080

To stop and remove the container:

docker rm -f static-site

2. Terraform: Provision AWS Infrastructure

Terraform provisions the EC2 infrastructure and supporting resources.

The configuration includes:

* EC2 instance
* Security Group
* SSH access restricted to an allowed IP address
* HTTP access on port 80
* Docker installation through EC2 user data
* Elastic IP
* CloudWatch alarms
* Optional SNS email notifications

Prerequisites

Install and configure:

* Terraform
* AWS CLI
* An AWS account with appropriate IAM permissions
* An existing EC2 key pair

Deploy Infrastructure

Navigate to the Terraform directory:

cd terraform

Create your local variables file:

cp terraform.tfvars.example terraform.tfvars

Edit terraform.tfvars and configure the required values, including the EC2 key pair and permitted SSH CIDR.

Initialize Terraform:

terraform init

Validate the configuration:

terraform validate

Review the infrastructure changes:

terraform plan

Create the infrastructure:

terraform apply

Retrieve the public IP address:

terraform output public_ip

Important: Review AWS costs before deployment. Destroy resources when they are no longer required, but only after confirming that you no longer need the live website or Jenkins environment.

terraform destroy

3. Jenkins: Continuous Integration and Deployment

Jenkins automates the application’s build, image publishing, and EC2 deployment.

Jenkins Pipeline Stages

The declarative Jenkinsfile implements these stages:

1. Checkout: Retrieves the source code from GitHub.
2. Build Docker Image: Builds the application image and tags it with the Jenkins build number and latest.
3. Push to Docker Hub: Publishes both image tags.
4. Deploy to EC2: Connects to EC2 over SSH, pulls the latest image, removes the previous application container if present, and starts the updated container.
5. Smoke Test: Checks whether the deployed website responds.
6. Post Actions: Logs out of Docker Hub after the pipeline.

Docker Hub Image

The project publishes images to:

vinayw123/static-site

Example image tags:

vinayw123/static-site:6
vinayw123/static-site:latest

The numerical tag depends on the Jenkins build number.

Jenkins Credentials

Configure the following credentials in Jenkins:

Credential ID	Type	Purpose
dockerhub-cred	Username with password	Docker Hub authentication
ec2-ssh-key	SSH Username with private key	SSH access to EC2

For dockerhub-cred, use your Docker Hub username and an appropriate Docker Hub access token.

For ec2-ssh-key, configure the SSH username as ubuntu and use the private key corresponding to the public key authorized on the EC2 instance.

Never commit credentials, private keys, or access tokens to GitHub.

Jenkins Job Configuration

1. Create a Pipeline job named devops-cicd-project.
2. Select Pipeline script from SCM.
3. Select Git as the SCM.
4. Set the repository URL:

https://github.com/dev-vinay18/devops-cicd-project.git

5. Set the branch to:

*/main

6. Set the Script Path to:

Jenkinsfile

7. Ensure the Jenkins machine has Docker installed and the Jenkins user has permission to execute Docker commands.
8. Install the SSH Agent plugin.
9. Save the job and run Build Now.

Verified Pipeline Result

The Jenkins pipeline has successfully completed the following operations:

* Checked out the GitHub repository.
* Built the Docker image.
* Pushed the image tags to Docker Hub.
* Connected to EC2 over SSH.
* Pulled the latest image.
* Started the application container.
* Passed the remote smoke test.

The latest verified build completed with:

Finished: SUCCESS

4. GitHub Webhook: Automatic Pipeline Trigger

The project uses a GitHub webhook to notify Jenkins when code is pushed to the repository.

Jenkins Configuration

Open the Jenkins job:

devops-cicd-project

Select Configure → Build Triggers and enable:

GitHub hook trigger for GITScm polling

Save the configuration.

GitHub Configuration

Open the GitHub repository:

Settings → Webhooks

The webhook payload URL should follow this format:

http://<JENKINS_PUBLIC_IP>:8080/github-webhook/

Configure:

Setting	Value
Content type	application/json
Events	Just the push event
Active	Enabled

GitHub must be able to reach the Jenkins webhook endpoint.

Verify Automatic Triggering

1. Make a small change to README.md.
2. Commit the change directly to main.
3. Open the Jenkins job.
4. Check whether a new build starts without clicking Build Now.

Verification status: The existing GitHub webhook has returned HTTP 200. Automatic pipeline triggering should also be tested by pushing a new commit and confirming that Jenkins starts a build.

5. Ansible: Docker Installation and Container Deployment

Ansible automates Docker installation, image retrieval, and container deployment on the target server.

The playbook is located at:

ansible/playbook.yml

Prerequisites

Install Ansible on the control machine and ensure SSH connectivity to EC2.

Update ansible/inventory.ini with the correct EC2 public IP, username, and private-key path.

Use the ubuntu username for the current Ubuntu EC2 instance.

Install Required Collections

cd ansible
ansible-galaxy collection install -r requirements.yml

Test the connection:

ansible -i inventory.ini web -m ping

Run the playbook:

ansible-playbook -i inventory.ini playbook.yml

The playbook should:

1. Install Docker if required.
2. Pull vinayw123/static-site:latest.
3. Start the container and configure it to restart automatically.
4. Publish the website on port 80.

Ensure the playbook uses the correct Docker Hub image and the appropriate Ubuntu package-management commands.

6. Docker Compose

Docker Compose provides a convenient way to run the website container.

The repository includes:

docker-compose.yml
docker-compose.dev.yml

Development Environment

To run the development configuration:

docker compose \
  -f docker-compose.yml \
  -f docker-compose.dev.yml \
  up -d

The development site is intended to be accessible at:

http://localhost:8080

Production Environment

To run the production configuration:

docker compose up -d

The production service should use:

vinayw123/static-site:latest

and publish container port 80 on host port 80.

Optional Automatic Image Updates

If Watchtower is configured in the Compose file, the optional auto-update profile can be started with:

docker compose --profile autoupdate up -d

This feature depends on the actual Watchtower service configuration in the Compose file.

7. Monitoring with CloudWatch and SNS

The Terraform monitoring configuration includes CloudWatch alarms for:

* High EC2 CPU utilization, above 80%.
* EC2 instance status-check failures.

An optional SNS email notification can be configured using the alert_email variable.

To receive notifications, provide an email address and confirm the SNS subscription when AWS sends the confirmation message.

These alarms help identify high CPU usage and instance health problems.

8. Docker Health Check

The Dockerfile includes an Nginx health check:

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/ > /dev/null || exit 1

Check the container’s health with:

docker ps

Inspect detailed health information with:

docker inspect --format='{{json .State.Health}}' static-site

The health status depends on whether the container’s health check is passing.

9. Troubleshooting

Website Does Not Open

Check the EC2 Security Group:

* HTTP port 80 must allow the intended public website traffic.
* SSH port 22 should remain restricted to an authorized IP.
* Confirm that the EC2 instance has a public IP and appropriate network routing.

Check the container:

sudo docker ps

View application logs:

sudo docker logs --tail 50 static-site

Test Nginx locally on EC2:

curl -I http://localhost/

Jenkins Pipeline Fails

Review the Jenkins Console Output and identify the stage that failed.

Check:

* Docker availability and permissions.
* Docker Hub credentials.
* SSH credential ID ec2-ssh-key.
* EC2 SSH connectivity.
* Container status and port 80 availability.

GitHub Webhook Does Not Trigger a Build

Check:

* The webhook URL and its trailing slash.
* GitHub’s recent delivery status.
* Jenkins’ GitHub webhook trigger setting.
* Jenkins reachability from the internet.
* Whether the webhook event is a push to the expected branch.

A successful webhook HTTP response does not by itself prove that the Jenkins job started.

10. Security Considerations

* Keep private SSH keys out of GitHub.
* Keep terraform.tfvars and Terraform state files out of version control.
* Use IAM credentials with appropriate permissions.
* Use Docker Hub access tokens instead of account passwords.
* Restrict SSH access to trusted IP addresses.
* Protect Jenkins with authentication and appropriate network controls.
* Use HTTPS and secure webhook practices for production environments.
* Avoid exposing Jenkins administration interfaces unnecessarily.

Conclusion

This project demonstrates an end-to-end DevOps workflow using GitHub, Jenkins, Docker, Docker Hub, AWS EC2, Terraform, Ansible, and Docker Compose.

It combines infrastructure provisioning, configuration management, containerization, continuous integration, deployment automation, and basic monitoring in one project.

The core Jenkins build, image publishing, EC2 deployment, and smoke test have been verified successfully. Remaining tasks should be checked against the internship requirements before final submission.
## Live URL
http://<elastic-ip>
