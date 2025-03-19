Script de implementación automatizada de Zabbix 7.2

Versión
19.3.25

Autor
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