#!/bin/bash

DIRETORIA="/opt/overleaf-teste"
PLAYBOOK="setup-overleaf-teste.yml"

# Inicia o ciclo infinito
while true; do

# Limpa o ecrã a cada nova iteração do menu

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
                VERSAO_ATUAL=$(ansible --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
                
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
            
            # 3. Provisionamento do ambiente e Injeção de Segurança
            if [ -d "$DIRETORIA" ] && [ -n "$(cd "$DIRETORIA" 2>/dev/null && sudo docker compose ps -a -q 2>/dev/null)" ]; then
                echo "[AVISO] O ambiente ja se encontra criado e configurado."
                echo "[AVISO] Por favor, utilize a Opcao 2 para o iniciar."
            else
                if [ -f "$PLAYBOOK" ]; then
                    
                    # ---------------------------------------------------------
                    # MAGIA DA SEGURANÇA: Pedir a password ao utilizador
                    # ---------------------------------------------------------
                    echo ""
                    echo "[SEGURANCA] Vamos configurar a tua conta de Administrador."
                    ADMIN_EMAIL="admin@overleaf.pt"
                    
                    # O loop garante que a pessoa não se engana a escrever às cegas
                    while true; do
                        read -s -p "🔑 Digita a password que desejas (nao vai aparecer no ecra): " ADMIN_PASS
                        echo ""
                        read -s -p "🔑 Confirma a password: " ADMIN_PASS_CONFIRM
                        echo ""
                        
                        if [ "$ADMIN_PASS" = "$ADMIN_PASS_CONFIRM" ] && [ -n "$ADMIN_PASS" ]; then
                            echo "[SUCESSO] Passwords coincidem!"
                            break
                        else
                            echo "[ERRO] As passwords nao coincidem ou estao vazias. Tenta novamente."
                        fi
                    done
                    # ---------------------------------------------------------

                    echo "[INFO] A iniciar a instalacao e a encriptar as tuas credenciais..."
                    if sudo ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook "$PLAYBOOK" --extra-vars "email_padrao=$ADMIN_EMAIL password_padrao=$ADMIN_PASS"; then
                        
                        clear
                        echo "========================================================================"
                        echo " 🎉 OVERLEAF INSTALADO COM SUCESSO! 🎉"
                        echo "========================================================================"
                        echo " O teu ambiente esta pronto e totalmente seguro."
                        echo ""
                        echo " DADOS DE ACESSO:"
                        echo " Link:     http://localhost:8085"
                        echo " Email:    $ADMIN_EMAIL"
                        echo " Password: [A que definiste no passo anterior]"
                        echo "========================================================================"
                        
                        # Limpa a variável da memória RAM por precaução
                        ADMIN_PASS=""
                        ADMIN_PASS_CONFIRM=""
                    else
                        echo "[ERRO] A instalacao do Ansible falhou. Verifica os logs acima."
                    fi
                else
                    echo "[ERRO] O ficheiro '$PLAYBOOK' nao foi encontrado na diretoria atual."
                fi
            fi
            break;
            ;;
        2)
            if [ -d "$DIRETORIA" ]; then
                cd "$DIRETORIA"
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
                if [ -n "$(sudo docker compose ps -a -q 2>/dev/null)" ]; then
                    echo "[INFO] A remover os contentores do sistema..."
                    sudo docker compose down
                else
                    echo "[INFO] Nao existem contentores a correr para remover."
                fi
                
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
            echo "[ERRO] Opcao invalida. Por favor, selecione uma opcao de 0 a 4,."
            ;;
    esac
done