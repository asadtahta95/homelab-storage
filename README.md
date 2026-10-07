# Homelab Storage Server

Self-hosted Google Drive + Docs/Sheets/Slides replacement, one-click install.
Battle-tested on Debian 13 (Intel i3, 16 GB RAM, plain HDDs).

```
Browser --HTTPS--> Cloudflare Tunnel --> Nginx? No - straight to containers:
  drive.example.com  -> Filebrowser Quantum  (files, WebDAV, shares)
  office.example.com -> OnlyOffice Docs      (edit docx/xlsx/pptx in browser)
  photos.example.com -> Immich               (Google Photos replacement)
  grafana.example.com-> Grafana + Prometheus (optional monitoring)
```

## Stacks

| Folder | What | Default ports |
|---|---|---|
| `filebrowser/` | Filebrowser Quantum + OnlyOffice DocumentServer | 8080, 127.0.0.1:8081 |
| `immich/` | Immich server + ML + Postgres + Redis | 2283 |
| `monitoring/` | Prometheus v2 + Blackbox + Grafana + mktxp | 9090, 9115, 3000, 49090 |
| `tunnel/` | Cloudflare Tunnel client | - |
| `scripts/` | Admin password reset, backup template | - |

Pinned versions live in each `docker-compose.yml`. Prometheus is
deliberately pinned to the last **v2** (`v2.55.1`): the `--web.console.*`
flags in the compose file were removed in v3.

## Quick start (one click)

```bash
git clone <your-repo-url> homelab-storage
cd homelab-storage
sudo ./install.sh
```

The installer will:

1. Install Docker + compose plugin if missing
2. Ask for domain names, ports, storage path and admin credentials
3. Generate all secrets (OnlyOffice JWT, DB + Grafana passwords, session key)
4. Render configs, create folders, pull images and start the stacks
5. Run health checks and print the URLs + next steps

Install only what you need:

```bash
sudo ./install.sh --stacks=storage              # files + office editor only
sudo ./install.sh --stacks=storage,photos       # + Immich
sudo ./install.sh --stacks=storage,photos,monitoring,tunnel  # everything (= all)
```

Non-interactive use: export the variables from `.env.example` first, the
installer respects pre-set values.

## After install

1. **Tunnel hostnames** - see `tunnel/README.md` for the exact table
   (drive/office/photos/grafana -> LAN ip + port).
2. **Verify editing** - upload a small `.docx` in Files, click it: the
   OnlyOffice editor should open and save back automatically.
3. **Change the Filebrowser admin password** (Settings -> Users). The one in
   `.env` was only for first-boot bootstrap. Locked out? Run
   `sudo ./scripts/reset-admin.sh`.
4. **Uploads** - in the app: open the sidebar (hamburger, top left) ->
   `+ File Actions` -> Upload. For multi-GB files use the LAN address,
   not the public domain (faster, no Cloudflare request-size limits).
5. **Backups** - adapt `scripts/backup-template.sh` (Immich DB dump + borg)
   and add it to cron. Your `.env` and `*/data` folders are git-ignored:
   back them up separately, they are **not** in this repo.

## Repository hygiene (read before pushing!)

This repo contains **templates and examples only**. Real secrets must never
be committed:

- `.env`, `immich/.env`, `monitoring/mktxp/mktxp.conf`,
  `monitoring/prometheus/prometheus.yml` (may hold bearer tokens),
  `filebrowser/data/`, `immich/postgres/`, `*.sqlite`, `*.sql.gz`
  are all in `.gitignore`. Keep it that way.
- Before `git push`, run: `git status --porcelain` and
  `git grep -riE "bearer_token|password\s*=\s*[^C]" -- ':!*.example' ':!*.template.*' ':!README.md' ':!install.sh'`
  and make sure nothing real shows up.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Doc shows `download failed` | Office container must reach the Files URL: check tunnel hostnames + `ONLYOFFICE_JWT_SECRET` match |
| `permission denied` writing to a shared folder | Container runs as uid 1000; the compose already adds `group_add: ["100"]` (users). On OMV keep folders `root:users` + `775` |
| Uploads stall on big files | Use LAN URL; chunks are 10 MB (`uploadChunkSizeMb`) to survive proxies |
| Cache/shm warnings from Filebrowser | `filebrowser/data/tmp` is a 2 GB RAM disk; raise `size=` in compose on big machines |
| Grafana OOM | Recent Grafana needs ~500 MB idle; limit is already 768 MB |

## Layout

```
├── install.sh                  # one-click installer
├── .env.example                # all settings (copy of what install.sh writes)
├── filebrowser/                # compose + config.template.yaml
├── immich/                     # upstream compose + .env.example
├── monitoring/                 # compose + prometheus/blackbox/mktxp/grafana
├── tunnel/                     # cloudflared compose + hostname table
└── scripts/                    # reset-admin.sh, backup-template.sh
```
