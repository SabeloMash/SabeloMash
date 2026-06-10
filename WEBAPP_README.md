# CCTECH Store Repository Viewer Webapp

A web application that automatically detects the server/store name and displays the corresponding Git repository from `https://git.truenorth.co.za/CCTECH/`.

## Features

- **Automatic Store Detection**: Extracts the store name from the server hostname
- **Admin Authentication**: Uses GitLab token for secure access to private repositories
- **Repository Information Display**: Shows store name, repo URL, last commit, and default branch
- **Git Repository Access**: Links to clone or view the repository
- **Responsive Design**: Modern, mobile-friendly UI with gradient styling

## Deployment

### Prerequisites

- Ansible (for automated deployment)
- Linux server (Ubuntu 20.04 or later recommended)
- GitLab admin token for API access
- Apache2 web server

### How to Deploy

1. **Update the playbook variables** (in `Webapp.yml`):

```yaml
vars:
  app_dir: "/var/www/html/cctech-store-repo"
  git_base_url: "https://git.truenorth.co.za/CCTECH"
  git_user: "{{ git_admin_user | default('admin') }}"
  git_token: "{{ git_admin_token }}"  # Set your GitLab token
```

2. **Run the Ansible playbook**:

```bash
ansible-playbook Webapp.yml -i inventory.ini -e "git_admin_token=YOUR_GITLAB_TOKEN_HERE"
```

Or with a more complete example:

```bash
ansible-playbook Webapp.yml -i inventory.ini \
  -e "git_admin_token=glpat-xxxxxxxxxxxx" \
  --user ansible \
  --ask-become-pass
```

### Manual Setup (Without Ansible)

1. **Install required packages**:
```bash
sudo apt-get update
sudo apt-get install apache2 apache2-utils php php-curl git curl -y
```

2. **Create application directory**:
```bash
sudo mkdir -p /var/www/html/cctech-store-repo
sudo chown -R www-data:www-data /var/www/html/cctech-store-repo
```

3. **Deploy files**:
   - Copy `index.html` to `/var/www/html/cctech-store-repo/`
   - Copy `style.css` to `/var/www/html/cctech-store-repo/`
   - Copy `app.js` to `/var/www/html/cctech-store-repo/`
   - Copy `api.php` to `/var/www/html/cctech-store-repo/`

4. **Configure Apache VirtualHost**:
```bash
sudo nano /etc/apache2/sites-available/cctech-store-repo.conf
```

Add the configuration from the playbook's VirtualHost section.

5. **Enable modules and site**:
```bash
sudo a2enmod rewrite proxy proxy_fcgi setenvif
sudo a2ensite cctech-store-repo.conf
sudo systemctl restart apache2
```

## How It Works

### Store Name Detection

The webapp extracts the store name from the server hostname:
- **Hostname**: `TESTSTORE3` → **Store Name**: `TESTSTORE3`
- **Hostname**: `cctech-teststore3-web01` → **Store Name**: `CCTECHTESTSTORE3WEB01`
- The store name is then used to construct the repository URL

### Repository URL Construction

```
Base URL: https://git.truenorth.co.za/CCTECH/
Store Name: TESTSTORE3
Result: https://git.truenorth.co.za/CCTECH/TESTSTORE3.git
```

### API Endpoints

**GET /api.php?action=get_repo_info**

Returns JSON with:
```json
{
  "status": "success",
  "hostname": "TESTSTORE3",
  "ip_address": "192.168.1.100",
  "store_name": "TESTSTORE3",
  "repo_url": "https://git.truenorth.co.za/CCTECH/TESTSTORE3.git",
  "last_commit": "2026-06-03T10:30:00Z",
  "branch": "main"
}
```

## Accessing the Webapp

Once deployed, access the webapp at:
```
http://your-server-ip/
http://store-repo.cctech.local/
```

The page will automatically:
1. Detect the server's hostname
2. Extract the store name
3. Fetch repository information from GitLab
4. Display the store-specific Git repository URL

## Security Considerations

1. **GitLab Token Security**:
   - Use a read-only token (Project-level is better than account-level)
   - Store the token securely in your Ansible vault
   - Rotate tokens regularly

2. **Access Control**:
   - Restrict access via Apache authentication if needed
   - Use HTTPS in production
   - Implement IP whitelisting for admin access

3. **API Rate Limiting**:
   - GitLab API has rate limits
   - The webapp caches data in the browser session

## Customization

### Modify Store Name Extraction

Edit the PHP regex in `api.php`:
```php
$store_name = preg_replace('/[^A-Z0-9]/i', '', $hostname);
```

### Change Repository Base URL

Update the `git_base_url` variable in `Webapp.yml`:
```yaml
git_base_url: "https://your-git-server.com/GROUP"
```

### Customize UI Styling

Edit `style.css` to match your branding.

## Troubleshooting

### Repository Information Not Loading

1. **Check PHP error logs**:
```bash
sudo tail -f /var/log/apache2/error.log
```

2. **Verify GitLab token**:
```bash
curl -H "PRIVATE-TOKEN: YOUR_TOKEN" \
  "https://git.truenorth.co.za/api/v4/repository/CCTECH%2FTESTSTORE3"
```

3. **Check API connectivity**:
```bash
curl -v https://git.truenorth.co.za/api/v4/repository
```

### Hostname Not Detected Correctly

Check your server's hostname:
```bash
hostname
hostnamectl status
```

Ensure it contains alphanumeric characters that match your store naming convention.

## Files Structure

```
/var/www/html/cctech-store-repo/
├── index.html          # Main UI page
├── style.css          # Styling
├── app.js             # Frontend logic
└── api.php            # Backend API logic
```

## License

CCTECH Internal Use

## Support

For issues or questions, contact your CCTECH systems administrator.
