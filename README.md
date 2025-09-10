

# linux-server

Automated Linux server setup and configuration scripts for webserver, database, and more. Easily deploy and manage your server modules with a single install command.

[View GitHub Pages site](https://anshulyadav32.github.io/linux-server/)



## Quick Installation (Recommended)



### For Linux (Recommended):
Run this command in your terminal for a one-line remote install:
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash
```

#### To install only the DNS module remotely:
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash -s dns
```


---

## Manual Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/anshulyadav32/linux-server.git
   cd linux-server
   ```

2. **Make sure you have bash installed.**


3. **(Optional) Review and configure module scripts as needed:**
    - All modules are located in the `modules/` directory.
    - You can inspect or modify individual module scripts before installation.
    - To install only the DNS module manually:
       ```bash
       bash modules/dns/install.sh
       ```

4. **Run the main install script:**
   ```bash
   bash install.sh
   ```
   This will execute the webserver installation and any other logic defined in `install.sh`.

---

GitHub Repository: [linux-server](https://github.com/anshulyadav32/linux-server)

---

## Notes
- Ensure you have the necessary permissions to execute scripts.
- Some modules may require additional dependencies. Check each module's script for details.
- For troubleshooting, refer to the logs or output from the install scripts.
