
# Container Networking and Security Lab (Codespaces Edition)

## Overview
In this lab, you will:
- Run Docker containers
- Explore container networking
- Inspect container IP addresses
- Test connectivity between containers
- Deploy a web server (nginx)
- Validate your work using an automated check script

---

## Step 0: Open in Codespaces

1. Fork this (repository)[https://github.com/dipaish/docketNetworking] to your GitHub account.
2. Navigate to your forked repository and select:
   **Code → Codespaces → Create codespace**
3. Wait for the environment to start.

---

## Step 1: Verify Docker

```bash
docker --version
docker ps
```

---

## Step 2: Pull Ubuntu Image

```bash
docker pull ubuntu:focal
docker images
```

---

## Step 3: Run the First Container

```bash
docker run -it -d --name csf-ubuntu1 ubuntu:focal
```

---

## Step 4: Run the Second Container

```bash
docker run -it -d --name csf-ubuntu2 ubuntu:focal
```

---

## Step 5: Get Container IP Address

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' csf-ubuntu1
```
Save this IP address for later use.

---

## Step 6: Access the Second Container’s Shell

```bash
docker exec -it csf-ubuntu2 /bin/bash
```

---

## Step 7: Update Packages

```bash
apt-get update
```

---

## Step 8: Install Ping

```bash
apt-get install iputils-ping -y
```

---

## Step 9: Test Connectivity

```bash
ping <IP_ADDRESS>
```
Replace `<IP_ADDRESS>` with the value from Step 5. You should see successful replies.

Exit the container shell with:
```bash
exit
```

---

## Step 10: Run the Nginx Web Server

```bash
docker run -d -p 8080:80 --name csf-nginx nginx:latest
```

---

## Step 11: Access the Web Server

- Go to the Ports tab in Codespaces.
- Open port 8080.
- You should see: "Welcome to nginx!"