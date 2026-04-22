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
./setup.sh <lakefs_secret_file>
```

`lakefs_secret_file` — path to the lakeFS credentials file (`login:passwd`).

Example:
```bash
./setup.sh ~/lakefs/.lakefs_credentials
```

## Data Structure

```
jhub_data/
  shared/                 # shared directory, mounted at /home/jovyan/work
    {username}/           # personal folder for each user
  ssl/                    # SSL certificates (auto-generated)
  .lakefs_credentials     # lakeFS credentials (mounted read-only at /home/jovyan/.lakefs_credentials)
```

## Access

After startup JupyterHub is available at:

`https://<server-vpn-ip>:8000`

The browser will warn about a self-signed certificate — click "Continue".

Sign up with the username `admin` to get administrator access.

## User Environment

The `jupyter-user` image is based on `nvidia/cuda:13.0.3-cudnn-runtime-ubuntu22.04`.

## Rebuilding the User Image

```bash
docker compose build jupyter-user
```

## Deleting a User

1. Delete via admin panel: `https://localhost:8000/hub/admin`
2. Remove user data manually:
```bash
rm -rf jhub_data/shared/<username>
```
