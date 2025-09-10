# linux-server

## Installation Steps

Follow these steps to install all modules and run the setup:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/anshulyadav32/linux-server.git
   cd linux-server
   ```

2. **Make sure you have bash installed.**

3. **(Optional) Review and configure module scripts as needed:**
   - All modules are located in the `modules/` directory.
   - You can inspect or modify individual module scripts before installation.

4. **Run the main install script:**
   ```bash
   bash install.sh
   ```
   This will execute the webserver installation and any other logic defined in `install.sh`.

---

## Notes
- Ensure you have the necessary permissions to execute scripts.
- Some modules may require additional dependencies. Check each module's script for details.
- For troubleshooting, refer to the logs or output from the install scripts.
