Script de Implantação Automatizada do Zabbix 7.2

Versão
19.3.25

Autor:
André Rodrigues
technova.sti@outlook.com

Este script automatiza a instalação e configuração do Zabbix 7.2 em ambientes distribuídos ou centralizados, utilizando PostgreSQL e Apache. Foi desenvolvido para simplificar a implantação, configurando automaticamente componentes essenciais e ajustando as definições do sistema e é recomendado para ambientes que terão mais de 10.000 métricas monitoradas (1 metrica = 1 item + 1 trigger + 1 grafico).

Para realizar o calculo de número de itens, valores processados por segundo, permanencia de dias no histórico, permanencia de dias das tendencias, dias de histórico das triggers, periodo de armazenamento de dados, etc., recomendo o uso da seguinte ferramenta:
https://tools.izi-it.io/

Para obter parâmetros necessário às suas necessidades quanto ao hardware que terá o Zabbix instalado, visite:
https://www.zabbix.com/documentation/5.4/pt/manual/installation/requirements

Plataformas Suportadas
Oracle Linux 9.5
RHEL 9.5
Rocky Linux 9.5

Pré-requisitos
Execução como root: O script deve ser executado com privilégios de administrador.
Gerenciador de Pacotes: Utiliza o dnf para instalar e atualizar pacotes.
Conexão com a Internet: Necessária para baixar pacotes, atualizar repositórios e efetuar o download do pacote de scripts SQL do Zabbix.

Funcionalidades Principais
Detecção Dinâmica de Configurações: Localiza os caminhos dos arquivos de configuração do PostgreSQL (pg_hba.conf e postgresql.conf) para ajustar as definições de acesso.
Backup de Configurações: Realiza backup dos arquivos de configuração antes de modificá-los.
Configuração de Segurança: Desativa o SELinux (tanto de forma imediata quanto no arquivo de configuração) e ajusta as regras do firewall para liberar portas essenciais (80, 10051 e 162).
Configuração do PostgreSQL: Define a senha do usuário postgres sem prompt, cria o banco de dados e o usuário para o Zabbix, e ajusta as configurações de autenticação.
Download e Importação do Schema do Zabbix: Faz o download do pacote de scripts SQL do Zabbix e extrai o schema (arquivos como server.sql.gz, create.sql.gz ou schema.sql.gz) para importar no banco de dados.

Opções de Instalação:
Opção 1: Ambiente distribuído - Instalação apenas do Banco de Dados (PostgreSQL).
Opção 2: Ambiente distribuído - Instalação do Zabbix Server (inclui criação do banco de dados e importação do schema).
Opção 3: Ambiente distribuído - Instalação do Zabbix Proxy.
Opção 4: Ambiente centralizado - Instalação de todos os componentes (Banco de Dados, Zabbix Server e Zabbix Proxy) em um único servidor.
Opção 5: Cancelar a execução do script sem fazer alterações.

Logs Detalhados: Todas as ações e mensagens de erro são registradas em dois arquivos:
install-zabbix-script-19.3.25-results.txt – Logs de execução e informações importantes.
install-zabbix-script-19.3.25-errors.txt – Mensagens de erro e detalhes de falhas.

Uso
Preparação:
Faça o download do script.
Torne o script executável:
chmod +x zabbix.sh

Execução:
Execute o script como root:
sudo ./zabbix.sh

Ao iniciar, o script apresentará um menu de opções. Selecione a opção desejada digitando o número correspondente e pressionando Enter.
O script realizará as atualizações do sistema, alterará o hostname de acordo com a opção escolhida e aplicará as configurações necessárias (SELinux, firewall, PostgreSQL, etc.).

Opções Disponíveis
1 - Ambiente Distribuído (Banco de Dados PostgreSQL):
Instala e configura o PostgreSQL, cria o banco de dados e o usuário para o Zabbix, importa o schema e instala o TimescaleDB e SNMP.

2 - Zabbix Server:
Instala o PostgreSQL, configura o banco de dados para o Zabbix, importa o schema e instala o Zabbix Server juntamente com Apache, PHP e SNMP.

3 - Zabbix Proxy:
Instala o Zabbix Proxy, configurando os repositórios necessários e o SNMP.

4 - Ambiente Centralizado (Todos os Componentes):
Instala e configura todos os componentes: PostgreSQL (com criação do banco de dados e importação do schema), Zabbix Server, Zabbix Proxy, Apache, PHP, TimescaleDB e SNMP.

5 - Cancelar Execução:
Encerra o script sem efetuar alterações no sistema.

Logs e Monitoramento
Arquivo de Resultados:
Todas as informações sobre a execução (sucesso das operações, modificações e configurações) são registradas em install-zabbix-script-19.3.25-results.txt.

Arquivo de Erros:
Qualquer erro ou falha durante a execução é registrado em install-zabbix-script-19.3.25-errors.txt.

Customização e Manutenção
Comentários no Script:
O script possui comentários detalhados em cada função, facilitando a compreensão e manutenção.
Ajustes Necessários:
Pode ser necessário ajustar o script conforme a configuração específica do ambiente ou versão do sistema operacional.

Contato e Contribuições
Em caso de dúvidas, sugestões ou contribuições, entre em contato através do e-mail technova.sti@outlook.com.

Esta documentação serve para orientar os administradores e desenvolvedores na utilização e manutenção do script, garantindo uma implantação eficiente do Zabbix 7.2 com as configurações necessárias para ambientes de produção.

============================================================================================================

Zabbix 7.2 Automated Deployment Script

Version
19.3.25

Author:
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
============================================================================================================

Script de implementación automatizada de Zabbix 7.2

Versión
19.3.25

Autor:
André Rodrigues
technova.sti@outlook.com

Este script automatiza la instalación y configuración de Zabbix 7.2 en entornos distribuidos o centralizados, utilizando PostgreSQL y Apache. Se desarrolló para simplificar la implementación configurando automáticamente componentes esenciales y ajustando la configuración del sistema y se recomienda para entornos que tendrán más de 10,000 métricas monitoreadas (1 métrica = 1 elemento + 1 disparador + 1 gráfico).

Para calcular la cantidad de elementos, valores procesados ​​por segundo, cantidad de días en el historial, cantidad de días en tendencias, cantidad de días en el historial de activadores, período de almacenamiento de datos, etc., recomiendo utilizar la siguiente herramienta:
https://tools.izi-it.io/

Para obtener los parámetros necesarios para sus necesidades respecto al hardware que tendrá instalado Zabbix, visite:
https://www.zabbix.com/documentation/5.4/es/manual/installation/requirements

Plataformas compatibles
Oracle Linux 9.5
RHEL 9.5
Rocky Linux 9.5

Prerrequisitos
Ejecutarse como root: el script debe ejecutarse con privilegios de administrador.
Administrador de paquetes: utiliza dnf para instalar y actualizar paquetes.
Conexión a Internet: necesaria para descargar paquetes, actualizar repositorios y descargar el paquete de script SQL de Zabbix.

Características principales
Detección de configuración dinámica: encuentra las rutas de los archivos de configuración de PostgreSQL (pg_hba.conf y postgresql.conf) para ajustar la configuración de acceso.
Copia de seguridad de la configuración: realiza una copia de seguridad de los archivos de configuración antes de modificarlos.
Configuración de seguridad: deshabilita SELinux (ya sea inmediatamente o en el archivo de configuración) y ajusta las reglas del firewall para permitir puertos esenciales (80, 10051 y 162).
Configuración de PostgreSQL: establezca la contraseña del usuario de postgres sin solicitarlo, cree la base de datos y el usuario para Zabbix y ajuste la configuración de autenticación.
Descargar e importación de esquemas de Zabbix: descarga el paquete de script SQL de Zabbix y extrae el esquema (archivos como server.sql.gz, create.sql.gz o schema.sql.gz) para importarlo a la base de datos.

Opciones de instalación:
Opción 1: Entorno distribuido - Solo instalación de base de datos (PostgreSQL).
Opción 2: Entorno distribuido - Instalación del servidor Zabbix (incluye creación de base de datos e importación de esquemas).
Opción 3: Entorno distribuido – Instalación de proxy Zabbix.
Opción 4: Entorno centralizado - Instalación de todos los componentes (Base de Datos, Servidor Zabbix y Proxy Zabbix) en un único servidor.
Opción 5: Cancelar la ejecución del script sin realizar ningún cambio.

Registros detallados: todas las acciones y mensajes de error se registran en dos archivos:
install-zabbix-script-19.3.25-results.txt – Registros de ejecución e información importante.
install-zabbix-script-19.3.25-errors.txt – Mensajes de error y detalles de fallas.

Usar
Preparación:
Descargue el script.
Hacer que el script sea ejecutable:
chmod +x zabbix.sh

Ejecución:
Ejecute el script como root:
sudo ./zabbix.sh

Al iniciarse, el script presentará un menú de opciones. Seleccione la opción deseada escribiendo el número correspondiente y presionando Enter.
El script realizará actualizaciones del sistema, cambiará el nombre de host según la opción elegida y aplicará las configuraciones necesarias (SELinux, firewall, PostgreSQL, etc.).

Opciones disponibles
1 - Entorno distribuido (base de datos PostgreSQL):
Instala y configura PostgreSQL, crea la base de datos y el usuario para Zabbix, importa el esquema e instala TimescaleDB y SNMP.

2 - Servidor Zabbix:
Instala PostgreSQL, configura la base de datos para Zabbix, importa el esquema e instala el servidor Zabbix junto con Apache, PHP y SNMP.

3 - Proxy Zabbix:
Instala Zabbix Proxy, configurando los repositorios necesarios y SNMP.

4 - Entorno centralizado (todos los componentes):
Instala y configura todos los componentes: PostgreSQL (con creación de bases de datos e importación de esquemas), Zabbix Server, Zabbix Proxy, Apache, PHP, TimescaleDB y SNMP.

5 - Cancelar ejecución:
Finaliza el script sin realizar ningún cambio en el sistema.

Registros y monitoreo
Archivo de resultados:
Toda la información sobre la ejecución (éxito de las operaciones, modificaciones y configuraciones) se registra en install-zabbix-script-19.3.25-results.txt.

Archivo de error:
Cualquier error o falla durante la ejecución se registra en install-zabbix-script-19.3.25-errors.txt.

Personalización y mantenimiento
Comentarios del guión:
El script tiene comentarios detallados sobre cada función, lo que hace que sea más fácil de entender y mantener.
Ajustes necesarios:
Es posible que necesites ajustar el script dependiendo de la configuración de tu entorno específico o de la versión del sistema operativo.

Contacto y contribuciones
Si tiene alguna pregunta, sugerencia o contribución, contáctenos en technova.sti@outlook.com.

Esta documentación sirve para orientar a los administradores y desarrolladores en el uso y mantenimiento de scripts, asegurando un despliegue eficiente de Zabbix 7.2 con las configuraciones necesarias para entornos de producción.
