# Cloudflare Tunnel

The tunnel container carries **no config** - everything is the token in `.env`
(`CLOUDFLARE_TOKEN`, pasted from the Zero Trust dashboard).

## Add a public hostname

Zero Trust -> Networks -> Tunnels -> your tunnel -> Public Hostnames -> Add:

| Subdomain | Domain (example) | Service | URL |
|---|---|---|---|
| `drive` | `drive.example.com` | HTTP | `http://<server-lan-ip>:8080` |
| `office` | `office.example.com` | HTTP | `http://<server-lan-ip>:8081` |
| `photos` | `photos.example.com` | HTTP | `http://<server-lan-ip>:2283` |
| `grafana` | `grafana.example.com` | HTTP | `http://<server-lan-ip>:3000` |

Replace `8080/8081/2283/3000` with your `FB_PORT`, `OFFICE_BIND` port,
`IMMICH_PORT`, `GRAFANA_PORT` if you changed the defaults.

Notes:
- `https://office.example.com` opened directly shows the OnlyOffice
  **welcome page**. That is normal - documents open through Files.
- If a doc shows `download failed`, the office container cannot reach the
  files URL: check this hostname table and the JWT secret match.
