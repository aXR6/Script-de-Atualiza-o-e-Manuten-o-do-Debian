#!/bin/bash

# Define cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem Cor

# Função para exibir mensagens de erro
error() {
    echo -e "${RED}[ERRO]${NC} $1" 1>&2
}

# Função para exibir mensagens de sucesso
success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

# Função para exibir informações
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Função para exibir títulos
title() {
    echo -e "${YELLOW}== $1 ==${NC}"
}

# Função para corrigir a chave expirada
fix_expired_key() {
    local expired_key=$1
    echo "Corrigindo a chave expirada: $expired_key"

    # Atualiza a chave expirada
    sudo apt-key adv --keyserver keys.gnupg.net --recv-keys $expired_key
}

# Atualiza a lista de pacotes e verifica se há erros de chave expirada
title "Atualizando a lista de pacotes"
output=$(sudo apt update 2>&1)
if echo "$output" | grep -q "EXPKEYSIG"; then
    # Extrai todas as chaves expiradas da saída e as corrige uma a uma
    echo "$output" | grep "EXPKEYSIG" | while read -r line ; do
        expired_key=$(echo $line | sed -n 's/.*EXPKEYSIG \([A-F0-9]\+\).*/\1/p')
        fix_expired_key $expired_key
    done
    success "Lista de pacotes atualizada com sucesso."
else
    success "Lista de pacotes atualizada com sucesso."
fi

# Lista pacotes que podem ser atualizados
title "Pacotes disponíveis para atualização"
apt list --upgradable

# Corrige dependências quebradas, se houver
title "Corrigindo dependências quebradas"
if apt --fix-broken install -y; then
    success "Dependências quebradas corrigidas."
else
    error "Falha ao corrigir dependências quebradas."
    exit 1
fi

# Atualiza todos os pacotes para as últimas versões
title "Atualizando todos os pacotes para as últimas versões"
if apt dist-upgrade -y; then
    success "Todos os pacotes foram atualizados para as últimas versões."
else
    error "Falha ao atualizar os pacotes."
    exit 1
fi

# Remove pacotes que não são mais necessários
title "Removendo pacotes desnecessários"
if apt autoremove -y; then
    success "Pacotes desnecessários removidos."
else
    error "Falha ao remover pacotes desnecessários."
    exit 1
fi

# Limpa o cache de pacotes
title "Limpando o cache de pacotes"
if apt autoclean; then
    success "Cache de pacotes limpo com sucesso."
else
    error "Falha ao limpar o cache de pacotes."
    exit 1
fi

if apt clean; then
    success "Diretório de pacotes baixados limpo."
else
    error "Falha ao limpar o diretório de pacotes baixados."
    exit 1
fi

info "Atualização e limpeza concluídas com sucesso."