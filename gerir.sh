#!/bin/bash

DIRETORIA="/opt/overleaf-teste"
PLAYBOOK="setup-overleaf-teste.yml"

# ----------------------------------------------------------------------
# PROGRAMAÇÃO DEFENSIVA: Impedir a execução no disco do Windows (NTFS)
# ----------------------------------------------------------------------
if [[ "$PWD" == *"/mnt/c/"* ]] || [[ "$PWD" == *"/mnt/d/"* ]]; then
    clear
    echo "========================================================================"
    echo " [ERRO FATAL] DETETADA EXECUÇÃO NO DISCO DO WINDOWS"
    echo "========================================================================"
    echo " Estas a tentar correr o projeto dentro de $PWD."
    echo " O Docker e o MongoDB vao falhar porque o Windows nao suporta"
    echo " as permissoes estritas de ficheiros do Linux."
    echo ""
    echo " [SOLUCAO]:"
    echo " 1. Lê o manual"
    echo " 2. Escreve o comando: cd ~"
    echo " 3. Clona o repositorio novamente nessa pasta limpa."
    echo " 4. Corre o script a partir dai."
    echo "========================================================================"
    exit 1
fi

# Inicia o ciclo infinito
while true; do

    # Limpa o ecrã a cada nova iteração do menu para ficar organizado
    clear

    echo "========================================================================"
    echo "            GESTOR DO OVERLEAF LOCAL (WSL - DEBIAN)             "
    echo "========================================================================"
    echo "Selecione a operacao pretendida:"
    echo "1) Instalar / Criar do Zero (Executa o Ansible)"
    echo "2) Iniciar (Acorda os contentores adormecidos)"
    echo "3) Parar (Pausa os contentores, preservando o estado)"
    echo "4) Destruir (Remove contentores e/ou base de dados)"
    echo "0) Sair"
    echo "========================================================================="
    read -p "Opcao: " opcao

    case $opcao in
        1)
            # 1. Verifica se o Ansible está instalado
            VERSAO_MINIMA="2.13"
            PRECISA_INSTALAR=false
            
            if command -v ansible &> /dev/null; then
                VERSAO_ATUAL=$(ansible --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
                
                if [ "$(printf '%s\n' "$VERSAO_MINIMA" "$VERSAO_ATUAL" | sort -V | head -n1)" = "$VERSAO_MINIMA" ]; then
                    echo "[INFO] Ansible detetado com versao compativel ($VERSAO_ATUAL)."
                else
                    echo "[INFO] Ansible obsoleto. A forcar atualizacao..."
                    PRECISA_INSTALAR=true
                fi
            else
                echo "[INFO] Ferramentas base nao detetadas. A preparar instalacao..."
                PRECISA_INSTALAR=true
            fi

            # 2. Instalação Universal (Deteta a distribuição automaticamente)
            if [ "$PRECISA_INSTALAR" = true ]; then
                echo "[INFO] A detetar o gestor de pacotes do sistema..."
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y git curl ansible
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y git curl ansible
                elif command -v pacman &> /dev/null; then
                    sudo pacman -Sy --noconfirm git curl ansible
                else
                    echo "[ERRO] Sistema operativo nao suportado para instalacao automatica."
                    exit 1
                fi
            fi
            
            # 2.5. Garantir que a Role de automação do Docker está instalada
            if ! ansible-galaxy role list 2>/dev/null | grep -q "geerlingguy.docker"; then
                echo "[INFO] A descarregar a inteligência do Docker (geerlingguy.docker)..."
                ansible-galaxy install geerlingguy.docker
            fi
            
            # 3. Provisionamento do ambiente
            if [ -d "$DIRETORIA" ] && [ -n "$(cd "$DIRETORIA" 2>/dev/null && sudo docker compose ps -a -q 2>/dev/null)" ]; then
                echo "[AVISO] O ambiente ja se encontra criado e configurado."
                echo "[AVISO] Por favor, utilize a Opcao 2 para o iniciar."
            else
                if [ -f "$PLAYBOOK" ]; then
                    
                    echo ""
                    echo "[SEGURANCA] Vamos configurar a tua conta de Administrador."
                    ADMIN_EMAIL="admin@overleaf.pt"
                    
                    while true; do
                        read -s -p "🔑 Digita a password que desejas (invisivel): " ADMIN_PASS
                        echo ""
                        read -s -p "🔑 Confirma a password: " ADMIN_PASS_CONFIRM
                        echo ""
                        
                        if [ "$ADMIN_PASS" = "$ADMIN_PASS_CONFIRM" ] && [ -n "$ADMIN_PASS" ]; then
                            echo "[SUCESSO] Passwords coincidem!"
                            break
                        else
                            echo "[ERRO] As passwords nao coincidem. Tenta novamente."
                        fi
                    done

                    echo "[INFO] A iniciar a instalacao segura..."
                    
                    # Variável de ambiente (escondida de possíveis bisbilhoteiros no sistema)
                    export ADMIN_PASS_ENV="$ADMIN_PASS"
                    
                    # A flag -E no sudo permite passar a variável de ambiente para dentro da execução
                    if sudo -E ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook "$PLAYBOOK" --extra-vars "email_padrao=$ADMIN_EMAIL password_padrao=$ADMIN_PASS_ENV"; then
                        
                        echo "========================================================================"
                        echo " 🎉 OVERLEAF INSTALADO COM SUCESSO! 🎉"
                        echo "========================================================================"
                        echo " Link:     http://localhost:8085"
                        echo " Email:    $ADMIN_EMAIL"
                        echo " Password: [A que definiste no passo anterior]"
                        echo "========================================================================"
                        
                        # Limpa as variáveis da RAM por segurança
                        ADMIN_PASS=""
                        ADMIN_PASS_CONFIRM=""
                        export ADMIN_PASS_ENV=""
                    else
                        echo "[ERRO] A instalacao falhou. Verifica os logs."
                    fi
                else
                    echo "[ERRO] O ficheiro '$PLAYBOOK' nao foi encontrado!"
                fi
            fi
            ;;
        2)
            if [ -d "$DIRETORIA" ]; then
                cd "$DIRETORIA"
                if [ -n "$(sudo docker compose ps -a -q)" ]; then
                    echo "[INFO] A iniciar os contentores existentes..."
                    sudo docker compose start
                    echo "[SUCESSO] Ambiente online em: http://localhost:8085"
                else
                    echo "[AVISO] Os contentores nao existem. Execute a Opcao 1."
                fi
            else
                echo "[AVISO] Ambiente nao criado. Execute a Opcao 1."
            fi
            ;;
        3)
            if [ -d "$DIRETORIA" ] && [ -n "$(cd "$DIRETORIA" 2>/dev/null && sudo docker compose ps -a -q 2>/dev/null)" ]; then
                echo "[INFO] A parar os contentores. Dados preservados..."
                cd "$DIRETORIA" && sudo docker compose stop
                echo "[SUCESSO] Contentores parados. Use a Opcao 2 para retomar."
            else
                echo "[AVISO] Nao existem contentores ativos para parar."
            fi
            ;;
        4)
            if [ -d "$DIRETORIA" ]; then
                cd "$DIRETORIA"
                if [ -n "$(sudo docker compose ps -a -q 2>/dev/null)" ]; then
                    echo "[INFO] A remover contentores..."
                    sudo docker compose down
                else
                    echo "[INFO] Nao existem contentores a correr."
                fi
                
                if [ -d "data/" ]; then
                    read -p "Deseja apagar permanentemente a base de dados/projetos? (s/n): " resposta_apagar
                    if [[ "$resposta_apagar" =~ ^[sS]$ ]]; then
                        sudo rm -rf data/
                        echo "[SUCESSO] Tudo apagado. Sistema reposto a zero."
                    else
                        echo "[INFO] Dados preservados. Pode usar a Opcao 1 no futuro para reerguer."
                    fi
                else
                    echo "[AVISO] Base de dados ja apagada ou inexistente."
                fi
            else
                echo "[AVISO] Ambiente ja removido ou nunca criado."
            fi
            ;;
        0)
            echo "[INFO] A encerrar o gestor. Ate ja."
            exit 0
            ;;
        *)
            echo "[ERRO] Opcao invalida."
            ;;
    esac
    
    # Pausa para o utilizador conseguir ler os resultados antes do ecrã limpar
    echo ""
    read -p "Pressione [Enter] para voltar ao menu..."
done