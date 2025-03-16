#!/bin/bash

# Solicita o diretório ao usuário
read -p "Digite o caminho da pasta a ser processada: " DIR_ORIGEM

# Verifica se o diretório existe
if [ ! -d "$DIR_ORIGEM" ]; then
    echo "Erro: O diretório não existe!"
    exit 1
fi

DIR_PROCESADOS="$HOME/Arquivos_Processados"
IGNORE_LIST="$DIR_ORIGEM/.ignorelist"
ZIP_LIST="$DIR_ORIGEM/.ziplist"

# Função para criar a pasta de arquivos processados
criar_pasta_processados() {
    if [ ! -d "$DIR_PROCESADOS" ]; then
        echo "Criando pasta de arquivos processados..."
        mkdir -p "$DIR_PROCESADOS" || { echo "Erro ao criar a pasta."; exit 1; }
    fi
}

# Função para gerar um nome único para arquivos movidos
gerar_nome_unico_processados() {
    local ARQUIVO="$1"
    local BASE_NAME="${ARQUIVO##*/}"
    local EXTENSION="${BASE_NAME##*.}"
    local BASE_NAME="${BASE_NAME%.*}"
    local COUNTER=1
    local NOVO_ARQUIVO="$DIR_PROCESADOS/${BASE_NAME}_${COUNTER}.$EXTENSION"

    while [ -e "$NOVO_ARQUIVO" ]; do
        COUNTER=$((COUNTER + 1))
        NOVO_ARQUIVO="$DIR_PROCESADOS/${BASE_NAME}_${COUNTER}.$EXTENSION"
    done
    echo "$NOVO_ARQUIVO"
}

# Função para mover arquivos processados
mover_para_processados() {
    local ARQUIVO="$1"
    local NOVO_ARQUIVO
    NOVO_ARQUIVO=$(gerar_nome_unico_processados "$ARQUIVO")
    
    mv "$ARQUIVO" "$NOVO_ARQUIVO" && echo "Movido para: $NOVO_ARQUIVO" || echo "Erro ao mover: $ARQUIVO"
}

# Função para compactar uma pasta
compactar_pasta() {
    pasta="$1"
    zip_file="$pasta.zip"
    echo "Compactando a pasta $pasta para $zip_file..."
    zip -r "$zip_file" "$pasta"
    echo "Pasta compactada: $zip_file"
    echo "$zip_file"
}

# Função para criptografar arquivos ou pastas
criptografar() {
    read -sp "Digite a senha para criptografar: " SENHA
    echo

    criar_pasta_processados

    ignorados=()
    zipadas=()
    
    # Carregar as listas de ignorados e zipadas
    if [ -f "$IGNORE_LIST" ]; then
        while IFS= read -r linha; do
            [[ -n "$linha" && "$linha" != \#* ]] && ignorados+=("$linha")
        done < "$IGNORE_LIST"
    fi
    
    if [ -f "$ZIP_LIST" ]; then
        while IFS= read -r linha; do
            [[ -n "$linha" && "$linha" != \#* ]] && zipadas+=("$linha")
        done < "$ZIP_LIST"
    fi

    # Verifique se há algo na .ziplist e zipa as pastas primeiro
    for zip_pasta in "${zipadas[@]}"; do
        find "$DIR_ORIGEM" -type d -wholename "*$zip_pasta*" | while read -r pasta; do
            compactar_pasta "$pasta"  # Compacta a pasta antes de qualquer coisa
        done
    done

    # Iterar pelos arquivos e pastas
    find "$DIR_ORIGEM" -type f -wholename "*" | while read -r ARQUIVO; do
        IGNORADO=false
        for ignore in "${ignorados[@]}"; do
            if [[ "$ARQUIVO" == *"$ignore"* ]]; then
                IGNORADO=true
                break
            fi
        done

        if $IGNORADO; then
            continue
        fi

        # Criptografar o arquivo com GPG
        NOME_UNICO="$ARQUIVO.gpg"
        gpg --batch --yes --passphrase "$SENHA" --symmetric --output "$NOME_UNICO" "$ARQUIVO" && mover_para_processados "$ARQUIVO" || echo "Erro ao criptografar: $ARQUIVO"
    done
}

# Função para descriptografar arquivos
descriptografar() {
    read -sp "Digite a senha para descriptografar: " SENHA
    echo

    criar_pasta_processados

    # Iterar pelos arquivos criptografados
    find "$DIR_ORIGEM" -type f -name "*.gpg" | while read -r ARQUIVO; do
        NOME_UNICO="${ARQUIVO%.gpg}"  # Remover ".gpg"
        
        # Descriptografar o arquivo com GPG
        gpg --batch --yes --passphrase "$SENHA" --output "$NOME_UNICO" --decrypt "$ARQUIVO" && mover_para_processados "$ARQUIVO" || echo "Erro ao descriptografar: $ARQUIVO"
    done
}

# Função de menu
menu() {
    echo "Escolha uma opção:"
    echo "1 - Criptografar arquivos"
    echo "2 - Descriptografar arquivos"
    
    read -p "Digite o número da opção (1 ou 2): " OPCAO
    
    case $OPCAO in
        1) criptografar ;;
        2) descriptografar ;;
        *) echo "Opção inválida!" && exit 1 ;;
    esac
}

# Chama o menu
menu

echo "Operação concluída!"

