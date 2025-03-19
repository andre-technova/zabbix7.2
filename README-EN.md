Zabbix 7.2 Automated Deployment Script

Version
19.3.25

Author
André Rodrigues
technova.sti@outlook.com

This script automates the installation and configuration of Zabbix 7.2 in distributed or centralized environments, using PostgreSQL and Apache. It was developed to simplify deployment, automatically configuring essential components and adjusting system settings and is recommended for environments that will have more than 10,000 monitored metrics (1 metric = 1 item + 1 trigger + 1 graph).

To calculate the number of items, values ​​processed per second, number of days in history, number of days in trends, number of days in trigger history, data storage period, etc., I recommend using the following tool:
https://tools.izi-it.io/

To obtain the parameters necessary for your needs regarding the hardware that will have Zabbix installed, visit:
https://www.zabbix.com/documentation/5.4/pt/manual/installation/requirements

Supported Platforms
Oracle Linux 9.5
RHEL 9.5
Rocky Linux 9.5

Prerequisites
Execution as root: The script must be run with administrator privileges.
Package Manager: Uses dnf to install and update packages.
Internet Connection: Required to download packages, update repositories and download the Zabbix SQL script package.

Main Features
Dynamic Configuration Detection: Finds the paths of PostgreSQL configuration files (pg_hba.conf and postgresql.conf) to adjust access settings.
Configuration Backup: Backs up configuration files before modifying them.
Security Configuration: Disables SELinux (both immediately and in the configuration file) and adjusts firewall rules to allow essential ports (80, 10051 and 162).
PostgreSQL Configuration: Sets the postgres user password without prompting, creates the database and user for Zabbix, and adjusts authentication settings.
Zabbix Schema Download and Import: Downloads the Zabbix SQL script package and extracts the schema (files such as server.sql.gz, create.sql.gz or schema.sql.gz) to import into the database.

Installation Options:
Option 1: Distributed environment - Installation of the Database only (PostgreSQL).
Option 2: Distributed environment - Installation of Zabbix Server (includes database creation and schema import).
Option 3: Distributed environment - Installation of Zabbix Proxy.
Option 4: Centralized environment - Installation of all components (Database, Zabbix Server and Zabbix Proxy) on a single server.
Option 5: Cancel the script execution without making any changes.

Detailed Logs: All actions and error messages are recorded in two files:
install-zabbix-script-19.3.25-results.txt – Execution logs and important information.
install-zabbix-script-19.3.25-errors.txt – Error messages and failure details.

Usage
Preparation:
Download the script.
Make the script executable:
chmod +x zabbix.sh

Execution:
Run the script as root:
sudo ./zabbix.sh

When starting, the script will present a menu of options. Select the desired option by typing the corresponding number and pressing Enter.
The script will perform system updates, change the hostname according to the chosen option and apply the necessary settings (SELinux, firewall, PostgreSQL, etc.).

Available Options
1 - Distributed Environment (PostgreSQL Database):
Installs and configures PostgreSQL, creates the database and user for Zabbix, imports the schema and installs TimescaleDB and SNMP.

2 - Zabbix Server:
Installs PostgreSQL, configures the database for Zabbix, imports the schema and installs Zabbix Server along with Apache, PHP and SNMP.

3 - Zabbix Proxy:
Installs Zabbix Proxy, configuring the necessary repositories and SNMP.

4 - Centralized Environment (All Components):
Installs and configures all components: PostgreSQL (with database creation and schema import), Zabbix Server, Zabbix Proxy, Apache, PHP, TimescaleDB and SNMP.

5 - Cancel Execution:
Ends the script without making any changes to the system.

Logs and Monitoring
Results File:
All information about the execution (success of operations, modifications and configurations) is recorded in install-zabbix-script-19.3.25-results.txt.

Errors File:
Any errors or failures during execution are recorded in install-zabbix-script-19.3.25-errors.txt.

Customization and Maintenance
Script Comments:
The script has detailed comments on each function, making it easier to understand and maintain.
Necessary Adjustments:
It may be necessary to adjust the script according to the specific configuration of the environment or operating system version.

Contact and Contributions
If you have any questions, suggestions or contributions, please contact technova.sti@outlook.com.

This documentation is intended to guide administrators and developers in the use and script maintenance, ensuring an efficient deployment of Zabbix 7.2 with the necessary configurations for production environments.