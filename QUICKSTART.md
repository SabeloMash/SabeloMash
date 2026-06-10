# CCTECH Store Repository Viewer - Quick Start Guide

## Overview

This webapp automatically detects your store/server name and displays the corresponding Git repository from `https://git.truenorth.co.za/CCTECH/`.

**Repository URL Pattern**: `https://git.truenorth.co.za/CCTECH/{STORE_NAME}.git`

Example: If your server hostname is `TESTSTORE3`, the webapp will automatically link to `https://git.truenorth.co.za/CCTECH/TESTSTORE3.git`

---

## Quick Start (5 minutes)

### Step 1: Prerequisites
```bash
# Ensure Ansible is installed
ansible --version

# Ensure you have SSH access to your target servers
ssh ansible@teststore3.cctech.local
```

### Step 2: Get GitLab Admin Token
1. Log in to GitLab: `https://git.truenorth.co.za`
2. Click your profile → Settings → Access Tokens
3. Create a new token with `api` and `read_repository` scopes
4. Copy the token (e.g., `glpat-xxxxxxxxxxxx`)

### Step 3: Prepare Inventory
```bash
# Copy and edit the example inventory
cp inventory-example.ini inventory.ini
nano inventory.ini
```

Add your store servers to the `[stores]` section:
```ini
[stores]
teststore3 ansible_host=192.168.1.50
teststore4 ansible_host=192.168.1.51
```

### Step 4: Deploy
```bash
# Option A: Deploy to all stores
ansible-playbook Webapp.yml \
  -i inventory.ini \
  -e "git_admin_token=glpat-YOUR_TOKEN_HERE"

# Option B: Deploy to single store
ansible-playbook Webapp.yml \
  -i inventory.ini \
  -e "git_admin_token=glpat-YOUR_TOKEN_HERE" \
  --limit teststore3

# Option C: Using the helper script
sudo bash deploy-helper.sh
export GITLAB_TOKEN=glpat-YOUR_TOKEN_HERE
sudo bash deploy-helper.sh
```

### Step 5: Access the Webapp
```
http://teststore3/
http://teststore3.cctech.local/
```

---

## What Gets Deployed

### Files Deployed to `/var/www/html/cctech-store-repo/`

| File | Purpose |
|------|---------|
| `index.html` | Main web interface |
| `style.css` | UI styling (gradient, responsive design) |
| `app.js` | Frontend logic (fetches and displays repo info) |
| `api.php` | Backend API (hostname detection, repo URL construction) |

### Services Configured

- **Apache2**: Web server with modules (rewrite, proxy, proxy_fcgi)
- **PHP**: Backend scripting for API
- **VirtualHost**: `store-repo.cctech.local` configuration

---

## How It Works

### 1. Server Detection
When you visit the webapp, it automatically:
- Gets the server hostname (e.g., `TESTSTORE3`)
- Extracts the store name using regex (`/[^A-Z0-9]/i`)
- Gets the server IP address

### 2. Repository URL Construction
```
Base URL: https://git.truenorth.co.za/CCTECH/
+ Store Name: TESTSTORE3
= Result: https://git.truenorth.co.za/CCTECH/TESTSTORE3.git
```

### 3. Repository Information
If GitLab token is provided, the webapp fetches:
- Last commit timestamp
- Default branch name
- Repository status

### 4. Display
The webapp shows:
- ✓ Server name and IP
- ✓ Store name
- ✓ Repository URL (clickable link)
- ✓ Last commit info
- ✓ Branch name
- ✓ Clone and Web View buttons

---

## Customization

### Change Git Base URL

Edit `Webapp.yml` before deploying:

```yaml
vars:
  git_base_url: "https://your-git-server.com/GROUP"
```

### Modify Store Name Extraction

For different hostname formats, edit the regex in `api.php`:

```php
// Current: Keeps only alphanumeric (TESTSTORE3)
$store_name = preg_replace('/[^A-Z0-9]/i', '', $hostname);

// Alternative: Keep hyphens (teststore-3 → teststore3)
$store_name = strtoupper(str_replace('-', '', $hostname));

// Alternative: Take first part before dot (teststore3.local → teststore3)
$store_name = explode('.', $hostname)[0];
```

### Custom Styling

Edit `style.css` to match your branding:

```css
header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    /* Change to your colors */
}

.btn-primary {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
```

---

## Troubleshooting

### Issue: "Repository Information Not Loading"

**Check 1**: Is API accessible?
```bash
curl http://teststore3/api.php?action=get_repo_info
```

Expected output:
```json
{"status":"success","hostname":"TESTSTORE3",...}
```

**Check 2**: Apache logs
```bash
sudo tail -f /var/log/apache2/cctech-store-repo-error.log
```

**Check 3**: PHP functionality
```bash
php -m | grep curl
```

---

### Issue: "Hostname Not Detected Correctly"

Check your server's hostname:
```bash
hostname
# or
cat /etc/hostname
# or
hostnamectl status
```

Ensure it contains your store identifier (e.g., TESTSTORE3).

---

### Issue: "GitLab API Not Responding"

Check token validity:
```bash
curl -H "PRIVATE-TOKEN: glpat-xxxxx" \
  "https://git.truenorth.co.za/api/v4/user"
```

Check if repository exists:
```bash
curl -H "PRIVATE-TOKEN: glpat-xxxxx" \
  "https://git.truenorth.co.za/api/v4/projects/CCTECH%2FTESTSTORE3"
```

---

## File Locations

```
Project Files:
├── Webapp.yml                   ← Main Ansible playbook
├── deploy-helper.sh           ← Deployment helper script
├── inventory-example.ini      ← Example inventory file
├── WEBAPP_README.md           ← Full documentation
└── QUICKSTART.md              ← This file

Deployed Locations (on target servers):
└── /var/www/html/cctech-store-repo/
    ├── index.html             ← Main UI
    ├── style.css              ← Styling
    ├── app.js                 ← Frontend logic
    └── api.php                ← Backend API

Apache Configuration:
└── /etc/apache2/sites-available/cctech-store-repo.conf
```

---

## Security Notes

### GitLab Token Best Practices

1. **Use Project-Level Token** (not account-level):
   - More restrictive scope
   - Can be revoked without affecting user access

2. **Minimum Required Scopes**:
   - `api` - For repository info
   - `read_repository` - For commit details

3. **Rotation Schedule**:
   - Rotate every 90 days
   - Update Ansible variable after rotation

### Production Deployment

1. Use HTTPS (install SSL certificate):
```bash
sudo apt-get install certbot python3-certbot-apache
sudo certbot --apache -d store-repo.cctech.local
```

2. Restrict Access:
```apache
<Directory /var/www/html/cctech-store-repo>
    Require ip 192.168.1.0/24
</Directory>
```

3. Basic Authentication:
```bash
sudo htpasswd -c /etc/apache2/.htpasswd admin
```

---

## Common Commands

### View Deployment Logs
```bash
# Last 50 lines
sudo tail -50 /var/log/apache2/cctech-store-repo-error.log

# Real-time logs
sudo tail -f /var/log/apache2/cctech-store-repo-error.log
```

### Restart Services
```bash
sudo systemctl restart apache2
sudo systemctl status apache2
```

### Test Configuration
```bash
sudo apache2ctl configtest
```

### Manual Testing
```bash
# Test API
curl http://teststore3/api.php?action=get_repo_info

# Test with custom hostname
php -d variables_order="EGPCS" -r "echo gethostname();"
```

---

## Next Steps

1. ✓ Run deployment with `ansible-playbook Webapp.yml -i inventory.ini -e "git_admin_token=..."`
2. ✓ Access the webapp at `http://your-store-name/`
3. ✓ Verify repository information displays correctly
4. ✓ Test "Clone Repository" and "View on Web" buttons
5. ✓ Set up HTTPS for production (optional)
6. ✓ Configure access controls if needed

---

## Support & Documentation

- **Full Documentation**: See `WEBAPP_README.md`
- **Playbook**: `Webapp.yml`
- **Helper Script**: `deploy-helper.sh`
- **Example Inventory**: `inventory-example.ini`

For more details on any component, refer to the full README.

---

**Version**: 1.0  
**Last Updated**: June 2026  
**CCTECH Internal Use**
