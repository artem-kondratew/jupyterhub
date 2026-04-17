# JupyterHub

JupyterHub on Docker with GPU support, HTTPS, and isolated user environments.

## Requirements

- Docker + Docker Compose
- NVIDIA GPU + nvidia-container-toolkit
- OpenSSL
- VPN

## Quick Start

### 1. Clone the repository

```bash
git clone git@github.com:artem-kondratew/jupyterhub.git
cd jupyterhub
```

### 2. Run setup

```bash
./setup.sh <parquets_dir>
```

`parquets_dir` — path to the parquet files directory (will be created if it doesn't exist).

Example:
```bash
./setup.sh ~/parquets
```

## Data Structure

```
jhub_data/
  shared/           # shared directory, mounted at /home/jovyan/work
    {username}/     # personal folder for each user
    parquets/       # mounted parquet files directory
  ssl/              # SSL certificates (auto-generated)
```

## Access

After startup JupyterHub is available at:

`https://<server-vpn-ip>:8000`

The browser will warn about a self-signed certificate — click "Continue".

## User Environment

The `jupyter-user` image is based on `nvidia/cuda:13.0.3-cudnn-runtime-ubuntu22.04`.

## Rebuilding the User Image

```bash
docker compose build jupyter-user
```
