#!/bin/bash

# Script para monitorar portas e executar ações baseadas no status
# Autor: Sistema de Monitoramento
# Data: $(date)

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Arquivo de configuração
CONFIG_FILE="port_monitor.conf"
LOG_FILE="port_monitor.log"

# Função para logging
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "OPÇÕES:"
    echo "  -c, --config FILE    Arquivo de configuração (padrão: port_monitor.conf)"
    echo "  -l, --log FILE       Arquivo de log (padrão: port_monitor.log)"
    echo "  -v, --verbose        Modo verboso"
    echo "  -h, --help           Exibe esta ajuda"
    echo "  --setup              Cria arquivo de configuração exemplo"
    echo ""
    echo "FORMATO DO ARQUIVO DE CONFIGURAÇÃO:"
    echo "PORTA:SERVIÇO:AÇÃO_SE_DOWN:AÇÃO_SE_UP"
    echo ""
    echo "Exemplo:"
    echo "80:nginx:systemctl start nginx:echo 'Nginx OK'"
    echo "3306:mysql:systemctl start mysql:echo 'MySQL OK'"
}


# Função para verificar se uma porta está em uso
check_port() {
    local port=$1
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":$port "
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port "
    else
        # Fallback usando /proc/net/tcp
        [ -f /proc/net/tcp ] && grep -q "$(printf "%04X" $port)" /proc/net/tcp
    fi
}

# Função para obter informações do processo na porta
get_port_info() {
    local port=$1
    if command -v ss >/dev/null 2>&1; then
        ss -tulnp | grep ":$port " | head -1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulnp 2>/dev/null | grep ":$port " | head -1
    else
        echo "Porta $port - informações detalhadas não disponíveis"
    fi
}

# Função para executar ação com timeout
execute_action() {
    local action=$1
    local timeout=${2:-30}
    
    if [ -n "$action" ] && [ "$action" != "-" ]; then
        echo -e "${BLUE}Executando: $action${NC}"
        log_message "INFO" "Executando ação: $action"
        
        # Executa com timeout
        timeout $timeout bash -c "$action"
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}Ação executada com sucesso${NC}"
            log_message "SUCCESS" "Ação executada com sucesso: $action"
        elif [ $exit_code -eq 124 ]; then
            echo -e "${RED}Ação expirou após ${timeout}s${NC}"
            log_message "ERROR" "Ação expirou: $action"
        else
            echo -e "${RED}Ação falhou com código $exit_code${NC}"
            log_message "ERROR" "Ação falhou ($exit_code): $action"
        fi
        
        return $exit_code
    fi
}

# Função principal de monitoramento
monitor_ports() {
    local verbose=$1
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Arquivo de configuração não encontrado: $CONFIG_FILE${NC}"
        echo "Use --setup para criar um arquivo exemplo."
        exit 1
    fi
    
    echo -e "${BLUE}=== Monitor de Portas - $(date) ===${NC}"
    log_message "INFO" "Iniciando monitoramento de portas"
    
    local total_ports=0
    local active_ports=0
    local inactive_ports=0
    
    # Lê o arquivo de configuração
    while IFS=':' read -r port service action_down action_up || [ -n "$port" ]; do
        # Ignora comentários e linhas vazias
        [[ "$port" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$port" ]] && continue
        
        total_ports=$((total_ports + 1))
        
        echo ""
        echo -e "${YELLOW}Verificando porta $port ($service)...${NC}"
        
        if check_port "$port"; then
            active_ports=$((active_ports + 1))
            echo -e "${GREEN}✓ Porta $port está ATIVA${NC}"
            
            if [ "$verbose" = true ]; then
                port_info=$(get_port_info "$port")
                echo -e "${BLUE}Detalhes: $port_info${NC}"
            fi
            
            log_message "INFO" "Porta $port ($service) está ativa"
            
            # Executa ação quando porta está UP
            if [ -n "$action_up" ] && [ "$action_up" != "-" ]; then
                echo -e "${BLUE}Porta Up tudo OK${NC}"
            fi
            
        else
            inactive_ports=$((inactive_ports + 1))
            echo -e "${RED}✗ Porta $port está INATIVA${NC}"
            log_message "WARNING" "Porta $port ($service) está inativa"
            
            # Executa ação quando porta está DOWN
            if [ -n "$action_down" ] && [ "$action_down" != "-" ]; then
                echo -e "${YELLOW}Executando ação para porta inativa...${NC}"
                execute_action "$action_down"
                
                # Verifica novamente após a ação
                sleep 5
                if check_port "$port"; then
                    echo -e "${GREEN}✓ Porta $port foi restaurada!${NC}"
                    log_message "SUCCESS" "Porta $port ($service) foi restaurada"
                    active_ports=$((active_ports + 1))
                    inactive_ports=$((inactive_ports - 1))
                else
                    echo -e "${RED}✗ Porta $port ainda está inativa após ação${NC}"
                    log_message "ERROR" "Porta $port ($service) não foi restaurada"
                fi
            fi
        fi
        
    done < "$CONFIG_FILE"
    
    # Resumo final
    echo ""
    echo -e "${BLUE}=== RESUMO ===${NC}"
    echo -e "Total de portas monitoradas: $total_ports"
    echo -e "${GREEN}Portas ativas: $active_ports${NC}"
    echo -e "${RED}Portas inativas: $inactive_ports${NC}"
    
    log_message "INFO" "Monitoramento concluído - Ativas: $active_ports, Inativas: $inactive_ports"
    
    # Código de saída baseado no status
    if [ $inactive_ports -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Função para validar dependências
check_dependencies() {
    local missing_deps=()
    
    if ! command -v ss >/dev/null 2>&1 && ! command -v netstat >/dev/null 2>&1; then
        echo -e "${YELLOW}Aviso: nem 'ss' nem 'netstat' estão disponíveis. Usando fallback.${NC}"
    fi
    
    if ! command -v timeout >/dev/null 2>&1; then
        echo -e "${YELLOW}Aviso: 'timeout' não está disponível. Ações podem não ter limite de tempo.${NC}"
    fi
}

# Função principal
main() {
    local verbose=false
    
    # Parse dos argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --setup)
                create_sample_config
                exit 0
                ;;
            *)
                echo "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verifica dependências
    check_dependencies
    
    # Inicia monitoramento
    monitor_ports "$verbose"
}

# Verifica se está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi