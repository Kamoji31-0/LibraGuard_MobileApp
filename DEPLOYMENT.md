# 🚀 LibraGuard - Web Deployment Handover Guide

This guide is prepared for the deployment team to deploy the LibraGuard Flutter Web app to your custom domain using **Namecheap**, **Cloudflare**, **Cloudflared Tunnel**, and your **Self-hosted Server**.

---

## 🏗️ Architecture Overview

```text
User Browser (https://libraguard.mkdezzu.site/login)
       │
       ▼
Cloudflare Edge (DNS & SSL for mkdezzu.site managed automatically)
       │
       │ (Encrypted Cloudflared Tunnel — No open router ports needed)
       ▼
Your Server: Cloudflared Connector
       │
       ▼
Nginx Web Server (Listening on localhost:8080, serving /var/www/libraguard)
       │
       ▼
Backend API (https://libraguard-api.onrender.com/api)
```

---

## 📦 Step 1: Getting the Web Build Files

You have **two options** to get the compiled production web assets:

### Option A: Download from GitHub Actions (Recommended)
1. Push your changes to `main` or trigger the workflow manually in GitHub:
   - Go to **Actions** → **Build Flutter Web Release** → Run workflow.
2. Once finished, click the workflow run and download the **`flutter-web-build`** artifact (zip file).
3. Extract its contents directly into `/var/www/libraguard` on your server.

### Option B: Build Manually
If building locally or directly on the server:
```bash
# Ensure root base-href is used for custom domain deployment
flutter build web --release --base-href "/"
```
The compiled files will be located in `build/web/`.

---

## 🖥️ Step 2: Server Setup (Nginx)

1. **Install Nginx** (if not already installed):
   ```bash
   sudo apt update
   sudo apt install -y nginx
   ```

2. **Copy the compiled web files to the server web directory**:
   ```bash
   sudo mkdir -p /var/www/libraguard
   sudo cp -r /path/to/build/web/* /var/www/libraguard/
   sudo chown -R www-data:www-data /var/www/libraguard
   sudo chmod -R 755 /var/www/libraguard
   ```

3. **Configure Nginx**:
   Copy the provided [`nginx.conf`](./nginx.conf) to `/etc/nginx/sites-available/libraguard`:
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/libraguard
   sudo ln -s /etc/nginx/sites-available/libraguard /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```
   > ℹ️ *The app will now be running locally on your server at `http://localhost:8080`.*

---

## ☁️ Step 3: Cloudflare & Domain Configuration

### 3.1 Point Namecheap to Cloudflare
1. In **Namecheap**: Domain List → Manage your domain.
2. Under **Nameservers**, change to **Custom DNS** and enter the two Cloudflare nameservers provided by your Cloudflare dashboard.
3. Wait for Cloudflare to verify the domain (status: **Active**).

### 3.2 Setup Cloudflared Tunnel
1. Go to the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/).
2. Navigate to **Networks** → **Tunnels** → click **Add a tunnel**.
3. Choose **Cloudflared** and name the tunnel (e.g., `libraguard-tunnel`).
4. Select your server OS (Ubuntu/Debian, Docker, Windows, etc.) and run the installation command provided on your server terminal.
5. Once the connector status shows **Connected**, click **Next**.
6. Set the **Public Hostname**:
   - **Subdomain**: `libraguard`
   - **Domain**: `mkdezzu.site`
   - **Type**: `HTTP`
   - **URL**: `localhost:8080` (or `127.0.0.1:8080`)
7. Click **Save tunnel**.

---

## 🔒 Step 4: Making the App Private (Optional)

If you only want authorized members to access the web app:
1. In Cloudflare Zero Trust: Go to **Access** → **Applications** → **Add an application**.
2. Select **Self-hosted**.
3. Set Application domain: `libraguard.mkdezzu.site`.
4. Under **Policies**, create a rule:
   - Action: **Allow**
   - Include: **Emails** (add the email addresses of allowed users).
5. Cloudflare will automatically prompt users for an email OTP pin before displaying the Flutter app.

---

## 🔍 Checklist for the Deployment Team

- [ ] Flutter build used `--base-href "/"`
- [ ] `/var/www/libraguard` contains `index.html`, `flutter_bootstrap.js`, `main.dart.js`, and `assets/`
- [ ] `nginx -t` tests successfully and Nginx is running
- [ ] Local server test: `curl http://localhost:8080` returns the HTML content
- [ ] Cloudflared connector is running (`sudo systemctl status cloudflared`)
- [ ] Domain resolves with valid HTTPS SSL via Cloudflare
- [ ] App connects smoothly to API (`https://libraguard-api.onrender.com/api`)
