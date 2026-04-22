import os

c = get_config()

async def pre_spawn_hook(spawner):
    username = spawner.user.name
    user_dir = f'/jhub_data/shared/{username}'
    os.makedirs(user_dir, exist_ok=True)
    os.chown(user_dir, 1000, 1000)

c.Spawner.pre_spawn_hook = pre_spawn_hook

c.JupyterHub.authenticator_class = 'nativeauthenticator.NativeAuthenticator'
c.NativeAuthenticator.open_signup = True
c.Authenticator.allow_all = True
c.Authenticator.admin_users = {'admin'}

c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.DockerSpawner.image = "jupyter-user:latest"
c.DockerSpawner.name_template = "jupyter-{username}"
c.DockerSpawner.pull_policy = 'never'

shared_dir = os.environ.get('SHARED_DIR', f'{os.environ["HOME"]}/jupyterhub/jhub_data/shared')
lakefs_creds = os.environ.get('LAKEFS_CREDENTIALS_FILE', '')

c.DockerSpawner.volumes = {
    shared_dir: '/home/jovyan/work',
}

if lakefs_creds:
    c.DockerSpawner.volumes[lakefs_creds] = {'bind': '/home/jovyan/.lakefs_credentials', 'mode': 'ro'}

c.DockerSpawner.notebook_dir = '/home/jovyan/work'

c.JupyterHub.shutdown_on_logout = True
c.DockerSpawner.remove = True

c.JupyterHub.ssl_cert = '/jhub_data/ssl/server.crt'
c.JupyterHub.ssl_key = '/jhub_data/ssl/server.key'

c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.hub_connect_url = 'http://jupyterhub:8081'
c.DockerSpawner.network_name = 'jhub_net'

c.Spawner.http_timeout = 120
c.Spawner.start_timeout = 120

c.DockerSpawner.extra_host_config = {
    "device_requests": [
        {
            "Driver": "nvidia",
            "Count": -1,
            "Capabilities": [["gpu"]],
        }
    ]
}
