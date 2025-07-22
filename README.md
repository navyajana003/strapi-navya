# 🚀 Strapi Task 1 - navya

This project was created as part of the PearlThoughts DevOps Internship program to explore Strapi CMS.

---

## 📦 What's Included

- ✅ Created a new **Collection Type**: `navya`
- ✅ Fields included in the `navya` content type:
  - `Full_name` (Text)
  - `Age` (Number)
- All files are in my-strapi-app
---

## 🧪 How to Test

1. **Clone the repository**:
   ```bash
   git clone https://github.com/PearlThoughts-DevOps-Internship/Strapi-Monitor-Hub.git
   cd Strapi-Monitor-Hub/navyajana
2. Install dependencies:
    ```npm install```
3. Start the Stapi Server:
    ```npm run develop```

Here’s a professional set of lines you can add to your `README.md` file for **Task 2**:


## 🚀 Task 2: Dockerize Strapi Application

This task involves containerizing the Strapi backend application using Docker.

### ✅ Steps Performed:

* Created a `Dockerfile` using the official `node:20` image.
* Exposed Strapi's default port (`1337`) and ran the app in development mode.

### 🐳 Docker Commands Used:

```bash
docker build -t strapi-dockerized .
docker run -it -p 1337:1337 strapi-dockerized
```

> The `-it` flag ensures interactive terminal access, and `-p` maps container port 1337 to local port 1337.


---

# 🚀 Task 3: Strapi Production Setup with PostgreSQL & Nginx (Dockerized)

This repository contains a production-ready setup of a Strapi CMS backend using:

- ✅ **Strapi** (Node.js Headless CMS)
- ✅ **PostgreSQL** as the production database
- ✅ **Docker & Docker Compose**
- ✅ **Nginx** as a reverse proxy (exposes Strapi on port 80)

---

## 📁 Project Structure

```

├── strapi-app/
│   └── .env/               # .env file
│   └── Dockerfile          # Dockerfile for strapi app
├── docker-compose.yml      # Docker multi-container orchestration
├── nginx
│    └── default.conf       # Nginx reverse proxy configuration
└── README.md               # This documentation

````

---

## 🛠️ Prerequisites

- Docker
- Docker Compose

---

## 🚀 How to Run (Production)

```bash
# From root directory
docker-compose up -d --build
```

Once running, access:

* **Strapi Admin**: `http://localhost`
* (Internally: Strapi runs on port `1337` and is reverse proxied by Nginx)

---


Here is a `README.md` file for your **Terraform-based Strapi + PostgreSQL Deployment on AWS EC2 with Docker**:

---

# 🚀 Task 4: Terraform Deployment: Strapi + PostgreSQL on AWS EC2 with Docker

This project automates the deployment of a Dockerized Strapi application and a PostgreSQL container on an Ubuntu-based AWS EC2 instance using Terraform.

## 📦 What This Project Does

- Provisions an Ubuntu EC2 instance in the `us-east-2` region.
- Installs Docker and Docker Compose on the instance.
- Runs a PostgreSQL container for the Strapi backend.
- Pulls a prebuilt Strapi Docker image from Docker Hub.
- Runs the Strapi container and connects it to the PostgreSQL container via a custom Docker network.
- Uses a custom SSH key pair for secure access.

---

## 📁 Project Structure

```

terraform-strapi-deploy/
│
├── main.tf           # EC2 instance creation and Docker setup
├── variable.tf       # Input variables
├── outputs.tf         # Outputs like public IP
├── terraform.tfvars  # store variables
└── README.md         # Project overview and instructions

````

## 🔐 Security Group Rules

- Port `22`: SSH access
- Port `1337`: Strapi Admin Panel
- Port `5432`: (Optional) PostgreSQL access (for debugging)

---

## 🔧 How It Works (User Data Boot Script)

```bash
#!/bin/bash
apt update -y
apt install -y docker.io
systemctl start docker
systemctl enable docker
docker network create strapi-net

# Run PostgreSQL container
docker run -d --name postgres --network strapi-net \
  -e POSTGRES_DB=strapi \
  -e POSTGRES_USER=strapi \
  -e POSTGRES_PASSWORD=strapi \
  -v /srv/pgdata:/var/lib/postgresql/data \
  postgres:15

# Run Strapi container from Docker Hub image
docker pull navyajana/strapi-app:latest
docker run -d --name strapi --network strapi-net \
  -e DATABASE_CLIENT=postgres \
  -e DATABASE_HOST=postgres \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=strapi \
  -e DATABASE_USERNAME=strapi \
  -e DATABASE_PASSWORD=strapi \
  -e APP_KEYS=... \
  -e API_TOKEN_SALT=... \
  -e ADMIN_JWT_SECRET=... \
  -p 1337:1337 \
  navyajana/strapi-app:latest
````

---

## ⚙️ How to Deploy

```bash
terraform init
terraform plan
terraform apply
```

Once deployed, SSH into the instance using the `.pem` key:

```bash
ssh -i strapi-key.pem ubuntu@<public_ip>
```

Then access Strapi Admin Panel:

```url
http://<public_ip>:1337
```

---

## 📤 Outputs

* `public_ip`: The public IP address of the EC2 instance 

---


# Task 5

Automate Strapi Deployment with GitHub Actions + Terraform
 
Set up GitHub Actions workflows to:

>Automatically build and push the Docker image on code push.

>Trigger Terraform workflow manually to deploy the updated image on EC2.

>Ensure EC2 instance uses SSH 

>Verify deployment via public IP 


Task Breakdown

>>1. CI/CD - Code Pipeline

    a) Set up .github/workflows/ci.yml to:

    b) Run on push to main branch.

    c) Build Docker image of Strapi.

    d) Push to Docker Hub or ECR.

    e) Save image tag as GitHub Action output.


>>2. CD - Terraform Pipeline

    a) Set up .github/workflows/terraform.yml to:

    b) Be manually triggered (workflow_dispatch)

    c) Run terraform init, plan, and apply

    d) Use GitHub Secrets for AWS credentials

    e) Use output image tag to pull and deploy container on EC2
 
## Steps

### 1) Create github actions YAML files
#### ci.yml 
To Build and Push Docker Image. This Workflow will trigger on code push on branch main of the repository.

#### terraform.yml
To Create resources and Deploy docker container using docker images pushed on dockerhub using previous workflow. This workflow will trigger manually.

### 2) Store Secrets 
Go to repository --> go to settings --> go to secrets and variables --> go to actions --> store secrets 

For storing environment variables and secrets like access key ID and password


### 3) Push code 

 Push code to the github repository. It will trigger ci.yml file's workflow.
``` git push origin main ```


### 4) Trigger terraform.yml
Go to repository --> go to actions --> search workflow name --> run workflow manually --> give image_tag of docker image as an input to workflow 

This will create resources and deploy strapi container on EC2 using terraform




