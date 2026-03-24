# Story 1.2 — Manual Deployment Steps

Follow these steps in order. Check each box as you complete it.

## 1. Create Railway Project (Task 2.1)

- [ ] Go to [railway.app](https://railway.app) dashboard
- [ ] Create new project named `rackup`
- [ ] Connect to your GitHub repo
- [ ] Enable auto-deploy on push to `main`

## 2. Add PostgreSQL (Task 2.3)

- [ ] In the Railway project, click **+ New** → **Database** → **PostgreSQL**
- [ ] Confirm `DATABASE_URL` is auto-provisioned as a variable

## 3. Configure the Go Service (Task 2.2)

- [ ] Add a new service from your GitHub repo
- [ ] Set **Root Directory** to `rackup-server`
- [ ] Railway will detect the `Dockerfile` automatically
- [ ] Add environment variables in the service **Variables** tab:

| Variable | Value |
|----------|-------|
| `DATABASE_URL` | Already set by PostgreSQL addon — verify it's linked |
| `JWT_SECRET` | Generate a secure random value (e.g. `openssl rand -hex 32`) |
| `LOG_LEVEL` | `INFO` |
| `PORT` | Auto-set by Railway — do not override |

> **Do NOT hardcode secrets in code or Dockerfiles.**

## 4. Configure Health Check (Task 2.7)

- [ ] In service **Settings** → **Health Check**
- [ ] Set path: `/health`
- [ ] Leave interval at Railway default

## 5. Deploy and Verify (Task 2.6)

- [ ] Trigger a deploy (push to `main` or manual deploy)
- [ ] Wait for build to complete in Railway logs
- [ ] Check logs for `server starting` message
- [ ] Run:
  ```sh
  curl https://<your-railway-url>/health
  ```
- [ ] Confirm response:
  ```json
  {"status":"ok","rooms":0,"connections":0,"uptime":"..."}
  ```
- [ ] Verify HTTPS/TLS is active (Railway provides this automatically)
- [ ] Test graceful shutdown by triggering a redeploy — check logs for clean shutdown

## 6. Update Flutter Config with Real URL (Task 3.1)

- [ ] Copy your Railway service URL (e.g. `rackup-server-production.up.railway.app`)
- [ ] Tell the dev agent the URL so it can update `prod_config.dart` and `staging_config.dart`

---

Once all steps are done, come back and say **"manual steps complete"** with the Railway URL to finish the story.
