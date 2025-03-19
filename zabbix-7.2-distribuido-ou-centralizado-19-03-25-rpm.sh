#!/bin/bash
# Script de implantação automatizada do Zabbix 7.2 para um ambiente distribuído ou centralizado.
# Criado por André Rodrigues (technova.sti@outlook.com) - Versão 19.3.25
# Testado em Oracle Linux 9.5, RHEL 9.5 e Rocky Linux 9.5.
#
# Este script utiliza:
#   - Detecção dinâmica dos caminhos de pg_hba.conf e postgresql.conf
#   - Desativação do SELinux (temporária e permanente)
#   - Configuração do PostgreSQL para definir a senha do usuário postgres sem prompt,
#     utilizando a variável de ambiente PGPASSWORD e sudo -H
#   - Download automático do pacote "zabbix-sql-scripts" (versão 7.2.4) e extração do schema 
#     (buscando por um arquivo cujo caminho contenha "postgresql", como server.sql.gz)
#
# Funções suportadas:
#   1 - Ambiente distribuído - Instalação do Banco de Dados (PostgreSQL)
#   2 - Ambiente distribuído - Instalação do Zabbix Server (inclui criação do DB e importação do schema)
#   3 - Ambiente distribuído - Instalação do Zabbix Proxy
#   4 - Ambiente centralizado - Todos os componentes necessários em um único servidor
#       (inclui criação do DB e importação do schema)
#   5 - Cancelar a execução deste script sem fazer alterações ao sistema
#
# O script renomeia o hostname conforme a função:
#   1 -> zbx-data01
#   2 -> zbx-srv01
#   3 -> zbx-proxy01
#   4 -> zbx-01
#
# Comandos adicionais aplicados após a escolha (1 a 4):
#   sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config  -> Garante que SELinux esteja desativado no arquivo de configuração
#   setenforce 0                                                  -> Desativa SELinux imediatamente
#   firewall-cmd --add-port=80/tcp --permanent                    -> Libera a porta 80 (HTTP)
#   firewall-cmd --add-port=10051/tcp --permanent                   -> Libera a porta 10051 (Zabbix Server)
#   firewall-cmd --add-port=162/udp --permanent                     -> Libera a porta 162 (SNMP traps)
#   firewall-cmd --reload                                          -> Recarrega as regras do firewall
#
# Este script deve ser executado como root.

##############################
# Verifica se o script está sendo executado como root
##############################
if [[ $EUID -ne 0 ]]; then
    echo "Este script precisa ser executado como root."
    exit 1
fi

# Configura o shell para encerrar em caso de erro e capturar erros em pipes
set -e
set -o pipefail

##############################
# Arquivos de log
##############################
RESULTS_FILE="./install-zabbix-script-19.3.25-results.txt"
ERRORS_FILE="./install-zabbix-script-19.3.25-errors.txt"
> "$RESULTS_FILE"
> "$ERRORS_FILE"

# Redireciona todas as saídas para os arquivos de log:
# - Toda a saída padrão (stdout) será enviada para o arquivo de resultados.
# - Toda a saída de erro (stderr) será enviada para o arquivo de erros.
exec > >(tee -a "$RESULTS_FILE")
exec 2> >(tee -a "$ERRORS_FILE")

##############################
# Funções de log (primeira versão)
##############################
# Função: log_result
# Descrição: Registra uma mensagem com data/hora. Nesta versão, a mensagem é apenas exibida.
# Parâmetros:
#   $1 - Texto da mensagem a ser logada.
log_result() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função: log_error
# Descrição: Registra uma mensagem de erro com data/hora. A saída é enviada para stderr.
# Parâmetros:
#   $1 - Texto da mensagem de erro.
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERRO: $1" >&2
}

# Configuração de trap para capturar erros e registrar via log_error
trap 'log_error "Erro na linha ${LINENO}: comando [${BASH_COMMAND}] retornou o código $?"' ERR

##############################
# Função de log (segunda versão)
# Observação: Esta definição sobrescreve a versão anterior de log_result, registrando também no arquivo de resultados.
##############################
# Função: log_result
# Descrição: Registra uma mensagem com data/hora e salva a saída no arquivo de resultados usando tee.
# Parâmetros:
#   $1 - Texto da mensagem a ser logada.
log_result() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$RESULTS_FILE"
}

# Configuração de trap para capturar erros e registrar via log_result
trap 'log_result "Erro na linha ${LINENO}: comando [${BASH_COMMAND}] retornou o código $?"' ERR

##############################
# Define COLUMNS com valor padrão 80, se não definido
##############################
COLUMNS=$(tput cols 2>/dev/null || echo 80)

##############################
# Função: backup_config
# Descrição: Realiza o backup de um arquivo de configuração, criando uma cópia com a extensão ".bak" (se ainda não existir).
# Parâmetros:
#   $1 - Caminho do arquivo de configuração a ser copiado.
##############################
backup_config() {
    local file="$1"
    if [ -f "$file" ]; then
        cp -n "$file" "${file}.bak" && log_result "Backup de $file criado." || log_result "Erro ao criar backup de $file"
    else
        log_result "Arquivo $file não encontrado. Nenhum backup necessário."
    fi
}

##############################
# Função: post_installation_checks
# Descrição: Verifica se os serviços essenciais (httpd, postgresql, zabbix-server, zabbix-agent e zabbix-proxy)
#            estão instalados e ativos, registrando o status de cada um.
##############################
post_installation_checks() {
    local services=("httpd" "postgresql" "zabbix-server" "zabbix-agent" "zabbix-proxy")
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service"; then
            if systemctl is-active --quiet "$service"; then
                log_result "Serviço $service está ativo."
            else
                log_result "ERRO: Serviço $service NÃO está ativo."
            fi
        fi
    done
}

##############################
# Obtém DISTRO_ID de /etc/os-release e define variáveis para o repositório do Zabbix e URL do schema
##############################
DISTRO_ID=$(source /etc/os-release && echo $ID)

if [[ "$DISTRO_ID" == "ol" || "$DISTRO_ID" == "oracle" ]]; then
    ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.2/stable/oracle/9/x86_64/"
    SCHEMA_URL="${ZABBIX_REPO_URL}zabbix-sql-scripts-7.2.4-release1.el9.noarch.rpm"
elif [[ "$DISTRO_ID" == "rocky" ]]; then
    ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.2/stable/rocky/9/x86_64/"
    SCHEMA_URL="${ZABBIX_REPO_URL}zabbix-sql-scripts-7.2.4-release1.el9.noarch.rpm"
else
    ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.2/stable/rhel/9/x86_64/"
    SCHEMA_URL="${ZABBIX_REPO_URL}zabbix-sql-scripts-7.2.4-release1.el9.noarch.rpm"
fi

##############################
# Cabeçalho e disclaimer
##############################
HEADER_MSG=$(cat <<'EOF'
Zabbix 7.2 | PostgreSQL | Apache - Script ver. 19.3.25
EOF
)

source /etc/os-release
LINUX_VER=$PRETTY_NAME

DISCLAIMER_EN="$(echo -e "$HEADER_MSG")\n\nDetected system version: $LINUX_VER\n
This is version 19.3.25 of the automated installation script for Zabbix 7.2 using PostgreSQL and Apache.
This script was created by André Rodrigues and tested on Oracle Linux 9.5, RHEL 9.5, and Rocky Linux 9.5.
For inquiries, contact: technova.sti@outlook.com
If you managed to install your Zabbix server with little effort, please contribute to the project by sending a PIX to technova.sti@outlook.com :)
Thank you!
"

DISCLAIMER_ES="$(echo -e "$HEADER_MSG")\n\nVersión del sistema detectada: $LINUX_VER\n
Esta es la versión 19.3.25 del script automatizado para Zabbix 7.2 con PostgreSQL y Apache.
Este script fue creado por André Rodrigues y probado en Oracle Linux 9.5, RHEL 9.5 y Rocky Linux 9.5.
Para preguntas, contáctenos: technova.sti@outlook.com
¡Gracias!
Si lograste instalar tu servidor Zabbix con poco esfuerzo, por favor contribuye al proyecto enviando un PIX a technova.sti@outlook.com :)
"

DISCLAIMER_PT="$(echo -e "$HEADER_MSG")\n\nVersão do sistema detectado: $LINUX_VER\n
Esta é a versão 19.3.25 do script automatizado para implantação do Zabbix 7.2 usando PostgreSQL e Apache.
Este script foi criado por André Rodrigues e testado em Oracle Linux 9.5, RHEL 9.5 e Rocky Linux 9.5.
Para dúvidas, entre em contato: technova.sti@outlook.com
Se você conseguiu instalar seu servidor Zabbix com pouco esforço, por favor, contribua com o projeto enviando um PIX para technova.sti@outlook.com :)
Obrigado!
"

SEPARATOR="=================================================="
echo -e "$DISCLAIMER_EN" | fold -s -w "${COLUMNS:-80}"
echo "$SEPARATOR"
echo -e "$DISCLAIMER_ES" | fold -s -w "${COLUMNS:-80}"
echo "$SEPARATOR"
echo -e "$DISCLAIMER_PT" | fold -s -w "${COLUMNS:-80}"
echo "$SEPARATOR"

##############################
# Função: install_epel_release
# Descrição: Instala o pacote epel-release, necessário para acessar alguns pacotes extras, verificando a distribuição.
#             Se a distribuição for RHEL, baixa o pacote diretamente via URL; caso contrário, usa o gerenciador de pacotes.
##############################
install_epel_release() {
    if [[ "$DISTRO_ID" == "rhel" ]]; then
        dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    else
        dnf install -y epel-release
    fi
}

##############################
# Menu de seleção de função
##############################
echo "Como você planeja executar esta instalação?"
echo "1 - Ambiente distribuído - Instalação do Banco de Dados PostgreSQL"
echo "2 - Ambiente distribuído - Instalação do Zabbix Server"
echo "3 - Ambiente distribuído - Instalação do Zabbix Proxy"
echo "4 - Ambiente centralizado - Todos os componentes necessários em um único servidor"
echo "5 - Cancelar a execução deste script sem fazer alterações ao sistema"
echo -n "Digite a opção adequada e tecle \"Enter\": "
read -r opcao

# Se a opção for 5, cancela a execução
if [[ "$opcao" == "5" ]]; then
    echo "Cancelando a execução deste script. Nenhuma alteração foi feita ao sistema."
    exit 0
fi

# Executa atualização e upgrade do sistema
sudo dnf update -y
sudo dnf upgrade -y

# Define o novo hostname conforme a opção selecionada
case "$opcao" in
    1) novo_hostname="zbx-data01" ;;
    2) novo_hostname="zbx-srv01" ;;
    3) novo_hostname="zbx-proxy01" ;;
    4) novo_hostname="zbx-01" ;;
    *) echo "Opção inválida. Saindo." ; exit 1 ;;
esac

log_result "Alterando hostname para $novo_hostname"
hostnamectl set-hostname "$novo_hostname"

##############################
# Configurações adicionais
##############################
log_result "Aplicando configurações adicionais..."
# Desativa SELinux permanentemente no arquivo de configuração
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
# Desativa SELinux imediatamente
setenforce 0
# Configura o firewall para liberar as portas necessárias:
#   - Porta 80/tcp para acesso HTTP
#   - Porta 10051/tcp para o Zabbix Server
#   - Porta 162/udp para traps SNMP
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --reload
log_result "Configurações adicionais aplicadas com sucesso."

##############################
# Variáveis do banco de dados
##############################
ZABBIX_DB_NAME="zabbix"
ZABBIX_DB_USER="zabbix"
ZABBIX_DB_PASSWORD="zabbix"
POSTGRES_PASSWORD="zabbix"
export PGPASSWORD="${POSTGRES_PASSWORD}"

##############################
# Função: download_zabbix_schema
# Descrição: Efetua o download do pacote de scripts SQL do Zabbix (caso o schema não exista localmente)
#            e extrai o arquivo de schema (server.sql.gz, create.sql.gz ou schema.sql.gz) de acordo com o conteúdo.
##############################
download_zabbix_schema() {
    SCHEMA_RPM="/tmp/zabbix-sql-scripts.rpm"
    SCHEMA_DIR="/tmp/zabbix-schema"
    
    mkdir -p "$SCHEMA_DIR"
    
    # Procura por arquivos cujo caminho contenha "postgresql" e com nomes de schema
    SCHEMA_FILE=$(find "$SCHEMA_DIR" -type f -path "*postgresql*" \( -name "server.sql.gz" -o -name "create.sql.gz" -o -name "schema.sql.gz" \) 2>/dev/null | head -n 1)
    if [ -z "$SCHEMA_FILE" ]; then
        log_result "Arquivo de schema não encontrado em $SCHEMA_DIR, tentando baixar de $SCHEMA_URL..."
        if ! wget -O "$SCHEMA_RPM" "$SCHEMA_URL"; then
            log_result "Download falhou com URL $SCHEMA_URL."
        fi
        log_result "Extraindo pacote RPM..."
        rpm2cpio "$SCHEMA_RPM" | (cd "$SCHEMA_DIR" && cpio -idmv)
        SCHEMA_FILE=$(find "$SCHEMA_DIR" -type f -path "*postgresql*" \( -name "server.sql.gz" -o -name "create.sql.gz" -o -name "schema.sql.gz" \) 2>/dev/null | head -n 1)
    else
        log_result "Arquivo de schema já existe: $SCHEMA_FILE"
    fi
    
    if [ -f "$SCHEMA_FILE" ]; then
        log_result "Schema encontrado em $SCHEMA_FILE"
    else
        log_result "Não foi possível baixar ou extrair o schema do Zabbix."
    fi
}

##############################
# Função: configure_postgres_and_zabbix_db
# Descrição: Detecta dinamicamente os caminhos dos arquivos de configuração do PostgreSQL (pg_hba.conf e postgresql.conf),
#            realiza backups destes arquivos, altera configurações para que o acesso seja feito via "trust" temporário,
#            define a senha do usuário postgres e cria o banco de dados e o usuário para o Zabbix.
##############################
configure_postgres_and_zabbix_db() {
    log_result "Detectando caminho do pg_hba.conf e postgresql.conf..."
    cd / && sudo -u postgres -H psql -tAc "SHOW hba_file;" > /tmp/hba_file.txt
    cd / && sudo -u postgres -H psql -tAc "SHOW config_file;" > /tmp/conf_file.txt
    HBA_FILE=$(cat /tmp/hba_file.txt | tr -d '[:space:]')
    CONF_FILE=$(cat /tmp/conf_file.txt | tr -d '[:space:]')
    log_result "Arquivo hba_file: $HBA_FILE"
    log_result "Arquivo postgresql.conf: $CONF_FILE"

    backup_config "$HBA_FILE"
    backup_config "$CONF_FILE"

    sed -i "s/^#listen_addresses.*/listen_addresses = 'localhost'/" "$CONF_FILE"
    systemctl restart postgresql

    sed -i '/ident/d' "$HBA_FILE"
    sed -i '/peer/d' "$HBA_FILE"

    sed -i "/^local\s\+all\s\+postgres/d" "$HBA_FILE"
    echo "local   all   postgres                  trust" >> "$HBA_FILE"
    systemctl restart postgresql
    log_result "pg_hba.conf ajustado para trust do usuário postgres (temporário)."

    cd / && sudo -u postgres -H env PGPASSWORD="${POSTGRES_PASSWORD}" psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';" >> "$RESULTS_FILE" 2>> "$ERRORS_FILE"
    log_result "Senha do usuário postgres definida como '${POSTGRES_PASSWORD}'."

    sed -i "/^local\s\+all\s\+postgres/d" "$HBA_FILE"
    cat <<EOF >> "$HBA_FILE"
local   all   zabbix                    md5
local   all   all                       md5
host    all   all   127.0.0.1/32        md5
host    all   all   ::1/128             md5
EOF
    systemctl restart postgresql
    log_result "pg_hba.conf final aplicado (md5 para todos)."

    log_result "Criando banco de dados e usuário para o Zabbix..."
    cd / && sudo -u postgres -H env PGPASSWORD="${POSTGRES_PASSWORD}" psql <<EOF >> "$RESULTS_FILE" 2>> "$ERRORS_FILE"
DROP DATABASE IF EXISTS ${ZABBIX_DB_NAME};
DROP ROLE IF EXISTS ${ZABBIX_DB_USER};
CREATE ROLE ${ZABBIX_DB_USER} LOGIN ENCRYPTED PASSWORD '${ZABBIX_DB_PASSWORD}';
CREATE DATABASE ${ZABBIX_DB_NAME} OWNER ${ZABBIX_DB_USER};
EOF
}

##############################
# Função: import_zabbix_schema
# Descrição: Realiza a importação do schema do Zabbix no banco de dados.
#            Primeiramente, chama a função download_zabbix_schema para garantir que o arquivo de schema esteja disponível.
#            Em seguida, aguarda alguns segundos e importa o schema utilizando o comando psql.
##############################
import_zabbix_schema() {
    download_zabbix_schema
    if [ -n "$SCHEMA_FILE" ] && [ -f "$SCHEMA_FILE" ]; then
        log_result "Aguardando 5 segundos para garantir que o PostgreSQL esteja pronto..."
        sleep 5
        log_result "Importando schema do Zabbix a partir de $SCHEMA_FILE..."
        # Executa o psql como usuário postgres conectando como -U zabbix
        timeout 600 sudo -u postgres -H env PGPASSWORD="${ZABBIX_DB_PASSWORD}" psql -U ${ZABBIX_DB_USER} ${ZABBIX_DB_NAME} -v ON_ERROR_STOP=1 < <(zcat "$SCHEMA_FILE")
        log_result "Schema importado com sucesso."
    else
        log_result "Schema SQL do Zabbix não encontrado. A importação não foi realizada."
    fi
}

##############################
# Função: install_timescaledb
# Descrição: Instala o TimescaleDB (extensão para PostgreSQL) e ajusta sua configuração,
#            reiniciando o serviço do PostgreSQL após a instalação.
# Notas: Esta função é utilizada apenas para as opções 1 e 4.
##############################
install_timescaledb() {
    log_result "Instalando TimescaleDB para PostgreSQL..."
    if dnf install -y timescaledb-postgresql-13; then
        log_result "TimescaleDB instalado com sucesso."
        timescaledb-tune --yes
        systemctl restart postgresql
    else
        log_result "Erro ao instalar TimescaleDB."
    fi
}

##############################
# Função: install_snmp
# Descrição: Instala os pacotes SNMP e SNMP-utils, habilita e inicia o serviço snmpd.
#            Essa função é chamada em todas as opções de instalação (1 a 4).
##############################
install_snmp() {
    log_result "Instalando SNMP..."
    dnf install -y net-snmp net-snmp-utils
    systemctl enable --now snmpd
    log_result "SNMP instalado e iniciado com sucesso."
}

##############################
# Fluxo principal conforme a opção selecionada
##############################
case "$opcao" in
    1)
        # Opção 1: Apenas Banco de Dados
        log_result "Instalando PostgreSQL..."
        dnf install -y postgresql-server postgresql-contrib
        log_result "Inicializando o banco de dados PostgreSQL..."
        postgresql-setup --initdb || true
        log_result "Habilitando e iniciando PostgreSQL..."
        systemctl enable --now postgresql

        configure_postgres_and_zabbix_db
        import_zabbix_schema
        install_timescaledb  # TimescaleDB instalado apenas na opção 1
        install_snmp        # SNMP instalado em todas as opções

        echo ""
        echo "Informações importantes (Opção 1 - Banco de Dados):"
        echo " - Hostname do servidor: $novo_hostname"
        echo " - SELinux foi desativado (verifique /etc/selinux/config)."
        echo " - Senha do usuário postgres definida como: $POSTGRES_PASSWORD"
        echo " - Banco de dados Zabbix: $ZABBIX_DB_NAME"
        echo " - Usuário do banco de dados Zabbix: $ZABBIX_DB_USER"
        echo " - Senha do usuário zabbix: $ZABBIX_DB_PASSWORD"
        ;;
    2)
        # Opção 2: Zabbix Server
        log_result "Instalando PostgreSQL e configurando banco de dados para o Zabbix..."
        dnf install -y postgresql-server postgresql-contrib
        postgresql-setup --initdb || true
        systemctl enable --now postgresql

        configure_postgres_and_zabbix_db
        import_zabbix_schema

        log_result "Instalando Zabbix Server..."
        dnf install -y httpd php php-mysqlnd
        if ! command -v fping &>/dev/null; then
            install_epel_release
            dnf install -y fping
        fi
        cat <<EOF > /etc/yum.repos.d/zabbix.repo
[zabbix]
name=Zabbix Repository
baseurl=${ZABBIX_REPO_URL}
enabled=1
gpgcheck=0
EOF
        dnf clean all && dnf makecache
        dnf install -y --disablerepo=epel zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-agent
        
        # Automatiza a configuração do DBPassword no arquivo de configuração do Zabbix Server
        sed -i 's/^# DBPassword=.*/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf || echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf

        systemctl enable --now zabbix-server zabbix-agent httpd

        install_snmp  # SNMP instalado para opção 2

        post_installation_checks
        HOST_IP=$(hostname -I | awk '{print $1}')
        log_result "Instalação concluída! Acesse http://$HOST_IP/zabbix para finalizar a configuração via interface web.
        
Para acessar o banco de dados durante a configuração do Zabbix, utilize:
Usuário: $ZABBIX_DB_USER
Senha: $ZABBIX_DB_PASSWORD
        
Para realizar o login na interface web do Zabbix, utilize:
Usuário: Admin
Senha: zabbix"
        ;;
    3)
        # Opção 3: Zabbix Proxy
        log_result "Instalando Zabbix Proxy..."
        if ! command -v fping &>/dev/null; then
            install_epel_release
            dnf install -y fping
        fi
        cat <<EOF > /etc/yum.repos.d/zabbix.repo
[zabbix]
name=Zabbix Repository
baseurl=${ZABBIX_REPO_URL}
enabled=1
gpgcheck=0
EOF
        dnf clean all && dnf makecache
        dnf install -y --disablerepo=epel zabbix-proxy-pgsql
        systemctl enable --now zabbix-proxy

        install_snmp  # SNMP instalado para opção 3

        log_result "Zabbix Proxy instalado e iniciado com sucesso."
        ;;
    4)
        # Opção 4: Todos os componentes em um único servidor
        log_result "Instalando TODOS os componentes (Banco de Dados, Zabbix Server e Zabbix Proxy)..."
        dnf install -y postgresql-server postgresql-contrib
        postgresql-setup --initdb || true
        systemctl enable --now postgresql

        configure_postgres_and_zabbix_db
        import_zabbix_schema

        dnf install -y httpd php php-mysqlnd
        if ! command -v fping &>/dev/null; then
            install_epel_release
            dnf install -y fping
        fi
        cat <<EOF > /etc/yum.repos.d/zabbix.repo
[zabbix]
name=Zabbix Repository
baseurl=${ZABBIX_REPO_URL}
enabled=1
gpgcheck=0
EOF
        dnf clean all && dnf makecache
        dnf install -y --disablerepo=epel zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-agent zabbix-proxy-pgsql
        
        # Automatiza a configuração do DBPassword no arquivo de configuração do Zabbix Server
        sed -i 's/^# DBPassword=.*/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf || echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf

        systemctl enable --now zabbix-server zabbix-agent zabbix-proxy httpd

        install_timescaledb  # TimescaleDB instalado para opção 4
        install_snmp         # SNMP instalado para opção 4

        post_installation_checks
        HOST_IP=$(hostname -I | awk '{print $1}')
        log_result "Instalação concluída! Acesse http://$HOST_IP/zabbix para finalizar a configuração via interface web.
        
Para acessar o banco de dados durante a configuração do Zabbix, utilize:
Usuário: $ZABBIX_DB_USER
Senha: $ZABBIX_DB_PASSWORD
        
Para realizar o login na interface web do Zabbix, utilize:
Usuário: Admin
Senha: zabbix"
        ;;
    *)
        echo "Opção inválida."
        exit 1
        ;;
esac
