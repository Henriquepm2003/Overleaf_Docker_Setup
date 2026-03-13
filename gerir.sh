#!/bin/bash

DIRETORIA="/opt/overleaf-teste"
PLAYBOOK="setup-overleaf-teste.yml"



# Inicia o ciclo infinito
while true; do

# Limpa o ecrã a cada nova iteração do menu
clear

    echo "========================================================================"
    echo "          GESTOR DO OVERLEAF LOCAL (WSL)             "
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
            # 1. Verifica se o Ansible esta instalado e valida a versao
            VERSAO_MINIMA="2.13"
            PRECISA_INSTALAR=false
            
            if command -v ansible &> /dev/null; then
                # Extrai apenas os primeiros dois digitos da versao (ex: 2.15)
                VERSAO_ATUAL=$(ansible --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
                
                # Compara as versoes de forma inteligente
                if [ "$(printf '%s\n' "$VERSAO_MINIMA" "$VERSAO_ATUAL" | sort -V | head -n1)" = "$VERSAO_MINIMA" ]; then
                    echo "[INFO] Ansible detetado com versao compativel ($VERSAO_ATUAL). A saltar instalacao..."
                else
                    echo "[AVISO] A versao do Ansible detetada ($VERSAO_ATUAL) e obsoleta (Minimo exigido: $VERSAO_MINIMA)."
                    echo "[INFO] A forcar a atualizacao do Ansible..."
                    PRECISA_INSTALAR=true
                fi
            else
                echo "[INFO] Ansible nao detetado no sistema. A preparar instalacao..."
                PRECISA_INSTALAR=true
            fi

            # 2. Corre a instalacao/atualizacao apenas se for necessario
            if [ "$PRECISA_INSTALAR" = true ]; then
                sudo apt update && sudo apt install -y software-properties-common git curl
                sudo apt-add-repository --yes --update ppa:ansible/ansible
                sudo apt install -y ansible
            fi
            
            # 3. Verifica se o ambiente ja existe para nao correr o playbook desnecessariamente
            # Corrigido: movido o bloco para garantir que o Ansible só é chamado se necessário
            if [ -d "$DIRETORIA" ] && [ -n "$(cd "$DIRETORIA" 2>/dev/null && sudo docker compose ps -a -q 2>/dev/null)" ]; then
                echo "[AVISO] O ambiente ja se encontra criado e configurado."
                echo "[AVISO] Por favor, utilize a Opcao 2 para o iniciar."
            else
                echo "[INFO] A iniciar o provisionamento do ambiente..."
                if [ -f "$PLAYBOOK" ]; then
                    # Executa o playbook com o formato de output limpo (debug)
                    sudo ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook "$PLAYBOOK"
                else
                    echo "[ERRO] O ficheiro '$PLAYBOOK' nao foi encontrado na diretoria atual."
                fi
            fi
            ;;
        2)
            if [ -d "$DIRETORIA" ]; then
                cd "$DIRETORIA"
                # Verifica se existem contentores criados (mesmo que parados) para este projeto
                if [ -n "$(sudo docker compose ps -a -q)" ]; then
                    echo "[INFO] A iniciar os contentores existentes..."
                    sudo docker compose start
                    echo "[SUCESSO] Ambiente online e disponivel em: http://localhost:8085"
                else
                    echo "[AVISO] Os contentores nao existem ou foram destruidos."
                    echo "[AVISO] Por favor, execute a Opcao 1 para reinstalar o ambiente."
                fi
            else
                echo "[AVISO] O ambiente ainda nao foi criado. Por favor, execute a Opcao 1."
            fi
            ;;
        3)
            # Verifica se a diretoria existe E se os contentores existem
            if [ -d "$DIRETORIA" ] && [ -n "$(cd "$DIRETORIA" 2>/dev/null && sudo docker compose ps -a -q 2>/dev/null)" ]; then
                echo "[INFO] A parar os contentores. Os dados serao preservados..."
                cd "$DIRETORIA" && sudo docker compose stop
                echo "[SUCESSO] Contentores parados com sucesso. Use a Opcao 2 para retomar."
            else
                echo "[AVISO] Nao existem contentores ativos ou criados para parar."
            fi
            ;;
        4)
            if [ -d "$DIRETORIA" ]; then
                cd "$DIRETORIA"
                
                # Verifica se há contentores para destruir
                if [ -n "$(sudo docker compose ps -a -q 2>/dev/null)" ]; then
                    echo "[INFO] A remover os contentores do sistema..."
                    sudo docker compose down
                else
                    echo "[INFO] Nao existem contentores a correr para remover."
                fi
                
                # Verifica se existe base de dados para perguntar se quer apagar
                if [ -d "data/" ]; then
                    read -p "[PERGUNTA] Deseja apagar permanentemente a base de dados e os projetos? (s/n): " resposta_apagar
                    if [[ "$resposta_apagar" =~ ^[sS]$ ]]; then
                        sudo rm -rf data/
                        echo "[SUCESSO] Base de dados e ficheiros apagados. O ambiente foi reposto a estaca zero."
                        echo "[INFO] Para voltar a utilizar o sistema, tera de executar a Opcao 1."
                    else
                        echo "[INFO] Os contentores foram removidos, mas os dados e projetos foram preservados."
                        echo "[INFO] Pode usar a Opcao 1 novamente no futuro para reerguer o sistema mantendo os dados."
                    fi
                else
                    echo "[AVISO] A base de dados ja se encontra apagada ou nao existe."
                fi
            else
                echo "[AVISO] O ambiente ja se encontra removido ou nunca foi criado."
            fi
            ;;
        0)
            echo "[INFO] A encerrar o gestor. Até já."
            exit 0
            ;;
        *)
            echo "[ERRO] Opcao invalida. Por favor, selecione uma opcao de 0 a 4, ou escreva 'sair'."
            ;;
    esac

    # Pausa antes de limpar o ecrã e voltar ao início do ciclo
    echo ""
    read -p "Pressione [ENTER] para voltar ao menu..."
done