
# Container Networking and Security Lab (Codespaces Edition)

## Overview
In this lab, you will:
- Run Docker containers
- Explore container networking
- Create and use a custom bridged network
- Inspect container IP addresses
- Test connectivity between containers
- Deploy a web server (nginx)
- Validate your work using an automated check script

---

## Step 0: Open in Codespaces

1. Fork this [repository](https://github.com/dipaish/docketNetworking) to your GitHub account.
2. Navigate to your forked repository and select:
   **Code → Codespaces → Create codespace**
3. Wait for the environment to start.

> **Note:** Docker is pre-installed in this Codespace. You do not need to install Docker manually. The environment is ready for container networking tasks.

---

## Step 1: Verify Docker


**What these commands do:**
- `docker --version` shows the installed Docker version to confirm Docker is available.
- `docker ps` lists running containers (should be empty at first).

```bash
docker --version
docker ps
```

---

## Step 2: Pull Ubuntu Image


**What these commands do:**
- `docker pull ubuntu:focal` downloads the Ubuntu image (version focal) from Docker Hub so you can use it for containers.
- `docker images` lists all images available locally, including the one you just pulled.

```bash
docker pull ubuntu:focal
docker images
```

---

## Step 3: Create a Custom Bridge Network


**What these commands do:**
- `docker network create --driver bridge csf-net` creates a new custom bridge network named `csf-net` for your containers to use. This network isolates your containers from others and lets you control their communication.
- `docker network ls` lists all Docker networks, so you can confirm your new network was created.

```bash
docker network create --driver bridge csf-net 
docker network ls
```


**Why?**
> A user-defined bridge network (csf-net) allows containers to communicate securely and predictably. Unlike the default bridge, it provides better network isolation and lets you control which containers can talk to each other. This is important for container security, as it limits exposure and enables network segmentation—key principles in secure container deployments.

---

## Step 4: Run the First Container (on the custom network)


**What this command does:**
- `docker run -it -d --name csf-ubuntu1 --network csf-net ubuntu:focal` starts a new Ubuntu container named `csf-ubuntu1` in the background, attached to the `csf-net` network. The `-it` allows interactive mode, and `-d` runs it detached (in the background).

```bash
docker run -it -d --name csf-ubuntu1 --network csf-net ubuntu:focal
```

---

## Step 5: Run the Second Container (on the custom network)


**What this command does:**
- `docker run -it -d --name csf-ubuntu2 --network csf-net ubuntu:focal` starts a second Ubuntu container named `csf-ubuntu2`, also attached to the `csf-net` network, so it can communicate with the first container.

```bash
docker run -it -d --name csf-ubuntu2 --network csf-net ubuntu:focal
```

---

## Step 6: Get Container IP Address


**What this command does:**
- `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' csf-ubuntu1` shows the internal IP address of the `csf-ubuntu1` container on the custom network. You will use this IP to test connectivity.

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' csf-ubuntu1
```
Save this IP address for later use.

---

## Step 7: Access the Second Container’s Shell


**What this command does:**
- `docker exec -it csf-ubuntu2 /bin/bash` opens a shell inside the `csf-ubuntu2` container so you can run commands inside it.

```bash
docker exec -it csf-ubuntu2 /bin/bash
```

---

## Step 8: Update Packages


**What this command does:**
- `apt-get update` refreshes the list of available software packages inside the container, so you can install new tools.

```bash
apt-get update
```

---

## Step 9: Install Ping


**What this command does:**
- `apt-get install iputils-ping -y` installs the `ping` tool inside the container, which is needed to test network connectivity. The `-y` flag auto-confirms the install.

```bash
apt-get install iputils-ping -y
```

---

## Step 10: Test Connectivity


**What this command does:**
- `ping <IP_ADDRESS>` sends network test packets to the IP address of the first container. If you see replies, the containers can communicate over the custom network.

Replace `<IP_ADDRESS>` with the value from Step 5. You should see successful replies.

Exit the container shell with:
```bash
exit
```

---

## Step 11: Run the Nginx Web Server


**What this command does:**
- `docker run -d -p 8080:80 --name csf-nginx nginx:latest` starts an Nginx web server container named `csf-nginx`, mapping port 8080 on your Codespace to port 80 in the container. The `-d` flag runs it in the background.

```bash
docker run -d -p 8080:80 --name csf-nginx nginx:latest
```

---

## Step 12: Access the Web Server

**What to do:**
- Go to the Ports tab in Codespaces.
- Open port 8080.
- You should see: "Welcome to nginx!"

---

## Step 13: Check Your Work and Get Your Marksheet

Run the check script:
```bash
bash check.sh
```
This will generate a `marksheet.md` file with your GitHub username and a summary of your lab checks. Your instructor will use this for grading.