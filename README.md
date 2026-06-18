# 🛠️ OS Setup & Optimization Toolkit

A script automation toolkit designed for IT Support specialists and System Administrators to perform post-installation system setups, system health diagnostics, temporary files cleaning, firewall status auditing, network latency checks, and packages list tracking.

---

## 🌟 Key Features

### 1. Windows Automation (`Configure-Windows.ps1`)
*   **System Diagnostics:** Inspects OS Caption, Version, hardware model, total physical RAM, and primary disk drive metrics.
*   **Temp Cleanup:** Deletes cached user items and system temp logs (running in Admin context) to reclaim disk space.
*   **Firewall Audit:** Displays activation statuses for all Windows Defender Firewall profiles (Domain, Private, Public).
*   **DNS & Ping Checks:** Verifies external DNS resolution capabilities and network latency to primary DNS targets.
*   **Software Inventory:** Uses Microsoft Package Manager (`winget`) to query and print the top installed packages list on the console.

### 2. Linux Automation (`configure_linux.sh`)
*   **System Metrics:** Prints active hostname, kernel, distribution details, memory allocations, and disk utilization.
*   **Cache Cleaning:** Runs package cache purge operations (`apt-get clean`) under root credentials.
*   **Firewall Status:** Queries activation status of the Uncomplicated Firewall (`ufw`).
*   **Ping Analysis:** Verifies network route validity and domain resolution.

---

## 💻 Local Setup & Execution Guide

### Windows Setup Execution
1.  Open PowerShell as Administrator.
2.  Navigate to this directory.
3.  Bypass Execution Policy for the session and execute:
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\Configure-Windows.ps1
    ```

### Linux Setup Execution
1.  Open your terminal inside this directory.
2.  Enable execute permissions on the shell file:
    ```bash
    chmod +x configure_linux.sh
    ```
3.  Run the setup script:
    ```bash
    ./configure_linux.sh
    ```
    *(To perform package cleaning tasks, execute using sudo: `sudo ./configure_linux.sh`)*
