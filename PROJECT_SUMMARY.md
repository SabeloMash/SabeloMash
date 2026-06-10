# CCTECH Store Repository Viewer - Project Summary

## Project Overview

A complete web application suite for viewing store-specific Git repositories based on server hostname. The webapp automatically detects the store name from the server and displays the corresponding GitLab repository information.

**Key Feature**: `https://git.truenorth.co.za/CCTECH/{STORE_NAME}.git`

When deployed on server `TESTSTORE3`, users access: `https://git.truenorth.co.za/CCTECH/TESTSTORE3.git`

---

## Files Created

### 1. **Webapp.yml** (Main Deployment)
**Type**: Ansible Playbook  
**Purpose**: Complete automated deployment of the webapp  

**What it deploys**:
- Apache2 web server with PHP support
- HTML UI with gradient styling
- Backend API (PHP) for hostname detection
- JavaScript frontend for data loading
- CSS styling (responsive, mobile-friendly)
- Apache VirtualHost configuration

**How to use**:
```bash
ansible-playbook Webapp.yml \
  -i inventory.ini \
  -e "git_admin_token=glpat-xxxxxxxxxxxx"
```

**Deployment targets**: `/var/www/html/cctech-store-repo/`

---

### 2. **store-repo-viewer-standalone.html** (Standalone Testing)
**Type**: Single HTML File (Complete Webapp)  
**Purpose**: Test the concept without deployment infrastructure  

**Features**:
- No backend required
- Manual hostname/store name input
- Optional GitLab token for API access
- Copy-to-clipboard clone URL
- Works locally on any browser

**How to use**:
1. Open in any web browser (double-click or `file:///path/to/file.html`)
2. Enter Git base URL (default: `https://git.truenorth.co.za/CCTECH`)
3. Enter store name or leave blank to auto-detect
4. Optionally add GitLab token for API features
5. Click "Generate Repository Info"

**Perfect for**: Testing before full deployment, demos, quick testing

---

### 3. **QUICKSTART.md** (Getting Started Guide)
**Type**: Markdown Documentation  
**Purpose**: Fast-track guide for deployment and usage  

**Contains**:
- 5-minute quick start steps
- Prerequisites checklist
- Step-by-step deployment commands
- How the webapp works (technical overview)
- Customization examples
- Troubleshooting guide
- Common commands

**Best for**: First-time users who want to get running quickly

---

### 4. **WEBAPP_README.md** (Complete Documentation)
**Type**: Markdown Documentation  
**Purpose**: Comprehensive reference documentation  

**Sections**:
- Feature overview
- Complete deployment instructions
- Manual setup without Ansible
- How it works (detailed)
- API endpoints reference
- Security best practices
- Customization guide
- Troubleshooting
- File structure

**Best for**: In-depth reference, production deployment planning

---

### 5. **deploy-helper.sh** (Deployment Assistant)
**Type**: Bash Script  
**Purpose**: Interactive deployment helper  

**What it does**:
- Checks dependencies (Ansible, Python3)
- Validates GitLab token
- Generates inventory file if needed
- Shows deployment commands
- Sets up test environment
- Provides verification commands

**How to use**:
```bash
chmod +x deploy-helper.sh
sudo bash deploy-helper.sh
# or
export GITLAB_TOKEN=glpat-xxxxxxxxxxxx
sudo bash deploy-helper.sh
```

**Benefits**: Beginner-friendly, prevents common mistakes

---

### 6. **inventory-example.ini** (Ansible Inventory)
**Type**: Ansible Inventory File  
**Purpose**: Define target servers for deployment  

**Contains**:
- Example store server definitions
- Connection settings (username, SSH key)
- Become/sudo configuration
- Local testing environment

**How to use**:
```bash
cp inventory-example.ini inventory.ini
nano inventory.ini
# Edit with your store servers
ansible-playbook Webapp.yml -i inventory.ini -e "git_admin_token=..."
```

**Customize**: Add your store hostnames/IPs to `[stores]` section

---

### 7. **PROJECT_SUMMARY.md** (This File)
**Type**: Markdown Documentation  
**Purpose**: Overview of all project files and structure  

---

## Deployment Paths

### Path 1: Quick Standalone Testing (< 5 minutes)
```
1. Open store-repo-viewer-standalone.html in browser
2. Enter store name or test hostname
3. See repository URL generated
✓ Perfect for demos and testing concepts
```

### Path 2: Full Production Deployment (15-30 minutes)
```
1. Copy inventory-example.ini → inventory.ini
2. Edit inventory.ini with store servers
3. Run: ansible-playbook Webapp.yml -i inventory.ini -e "git_admin_token=..."
4. Access webapp at: http://store-name/
✓ Complete production-ready setup
```

### Path 3: Interactive Deployment with Helper (10-20 minutes)
```
1. Run: sudo bash deploy-helper.sh
2. Follow interactive prompts
3. Script generates inventory and shows deployment commands
4. Run suggested ansible-playbook command
✓ Beginner-friendly guided deployment
```

---

## Technology Stack

### Frontend
- **HTML5**: Semantic markup
- **CSS3**: Gradient backgrounds, responsive design, animations
- **JavaScript**: Vanilla JS (no frameworks), async/await, fetch API

### Backend
- **PHP 8.1+**: API endpoints, hostname detection
- **Apache 2.4**: Web server with modules (rewrite, proxy)
- **Git**: Version control integration (optional)
- **cURL**: HTTP requests to GitLab API

### Infrastructure
- **Ansible**: Infrastructure as code, automated deployment
- **Linux**: Ubuntu 20.04+ (Debian-based)

---

## Key Features

### 1. Automatic Store Detection
```php
// From hostname: TESTSTORE3, CC-TESTSTORE3, or teststore3.local
// Extracts: TESTSTORE3
$store_name = preg_replace('/[^A-Z0-9]/i', '', $hostname);
```

### 2. Repository URL Construction
```
Input: Hostname = TESTSTORE3
Process: https://git.truenorth.co.za/CCTECH/ + TESTSTORE3.git
Output: https://git.truenorth.co.za/CCTECH/TESTSTORE3.git
```

### 3. GitLab Integration
```
- Uses admin token for API access
- Fetches last commit timestamp
- Gets default branch name
- Displays repository metadata
```

### 4. Responsive UI
```
- Works on desktop (1920x1080)
- Works on tablet (768x1024)
- Works on mobile (375x667)
- Touch-friendly buttons
```

---

## File Organization

```
SabeloMash/
├── Webapp.yml                          ← Main Ansible playbook
├── store-repo-viewer-standalone.html  ← Standalone testing version
├── deploy-helper.sh                   ← Interactive deployment script
├── inventory-example.ini              ← Example Ansible inventory
├── QUICKSTART.md                      ← Quick start guide
├── WEBAPP_README.md                   ← Full documentation
├── PROJECT_SUMMARY.md                 ← This file
└── [Existing files...]

Deployed on servers at:
/var/www/html/cctech-store-repo/
├── index.html                         ← Main page (from Webapp.yml)
├── style.css                          ← Styling (from Webapp.yml)
├── app.js                             ← Frontend logic (from Webapp.yml)
└── api.php                            ← Backend API (from Webapp.yml)
```

---

## Quick Reference

### For Demos/Testing
```bash
# Open standalone version
./store-repo-viewer-standalone.html    # Double-click to open in browser
```

### For Single Store Deployment
```bash
ansible-playbook Webapp.yml \
  -i inventory.ini \
  -e "git_admin_token=glpat-YOUR_TOKEN" \
  --limit teststore3
```

### For Bulk Deployment
```bash
ansible-playbook Webapp.yml \
  -i inventory.ini \
  -e "git_admin_token=glpat-YOUR_TOKEN"
```

### Verify Deployment
```bash
ssh ansible@teststore3
curl http://localhost/api.php?action=get_repo_info
```

---

## Customization Quick Guide

### Change Git Server
**File**: `Webapp.yml`  
**Line**: `git_base_url: "https://git.truenorth.co.za/CCTECH"`  
**Change to**: Your git server URL

### Change Store Name Detection
**File**: `Webapp.yml` (api.php section)  
**Line**: `$store_name = preg_replace('/[^A-Z0-9]/i', '', $hostname);`  
**Customize**: Adjust regex for your naming scheme

### Change UI Colors
**File**: `Webapp.yml` (style.css section)  
**Lines**: Background gradients and button colors  
**Customize**: Replace color codes (e.g., `#667eea` to your color)

### Change Deployment Path
**File**: `Webapp.yml`  
**Line**: `app_dir: "/var/www/html/cctech-store-repo"`  
**Change to**: Your preferred path

---

## Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Can't access webapp | Check Apache status: `sudo systemctl status apache2` |
| API not responding | Check PHP: `curl http://server/api.php?action=get_repo_info` |
| Store name not detected | Check hostname: `hostname` |
| GitLab API not working | Verify token: `curl -H "PRIVATE-TOKEN: token" https://git.../api/v4/user` |
| Permission denied | Run as sudo: `sudo ansible-playbook ...` |
| Port 80 in use | Change port in Apache config or stop conflicting service |

See **WEBAPP_README.md** for detailed troubleshooting.

---

## Security Notes

### GitLab Token
- ✓ Use project-level token (more secure than account token)
- ✓ Grant only `api` and `read_repository` scopes
- ✓ Rotate every 90 days
- ✓ Store in Ansible vault, not plain text

### Production Deployment
- ✓ Enable HTTPS with SSL certificate
- ✓ Restrict access by IP if needed
- ✓ Use Apache basic authentication
- ✓ Set up monitoring and alerts
- ✓ Regular security updates

---

## Next Steps

### 1. Quick Test (5 minutes)
```bash
# Open standalone version to see how it works
./store-repo-viewer-standalone.html
```

### 2. Prepare Deployment (10 minutes)
```bash
# Review documentation
cat QUICKSTART.md

# Get GitLab token from admin
# https://git.truenorth.co.za/admin/personal_access_tokens
```

### 3. Deploy (15-30 minutes)
```bash
# Option A: Interactive
sudo bash deploy-helper.sh

# Option B: Direct
ansible-playbook Webapp.yml -i inventory.ini -e "git_admin_token=..."
```

### 4. Verify (5 minutes)
```bash
# Test on deployed server
curl http://store-name/api.php?action=get_repo_info
```

---

## Support & Documentation

| Document | Purpose | Best For |
|----------|---------|----------|
| **PROJECT_SUMMARY.md** | This file | Overview, file locations |
| **QUICKSTART.md** | Fast deployment guide | Getting started quickly |
| **WEBAPP_README.md** | Complete reference | Production deployment, deep dives |
| **Webapp.yml** | Ansible playbook | Automation, infrastructure |
| **deploy-helper.sh** | Interactive helper | Beginners, interactive setup |
| **store-repo-viewer-standalone.html** | Standalone test | Quick testing, demos |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | June 2026 | Initial release with full deployment suite |

---

## Contact & Support

For issues or questions:
1. Check **WEBAPP_README.md** troubleshooting section
2. Review **QUICKSTART.md** for common solutions
3. Contact your CCTECH systems administrator

---

**CCTECH Internal Use - June 2026**
