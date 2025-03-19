Script de Implantação Automatizada do Zabbix 7.2

Versão
19.3.25

Autor
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