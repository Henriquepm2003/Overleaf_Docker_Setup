Roadmap: Setup do Overleaf Local (ISEC)
Este guia explica como preparar e executar um ambiente local do Overleaf com todos os pacotes LaTeX (scheme-full) pré-instalados, 
utilizando WSL, Ansible e Docker. Ideal para compilar relatórios sem falhas de pacotes e sem depender da internet.


Fase 1: Pré-requisitos (Preparar o PC)
O projeto automatiza quase tudo, mas precisas do ambiente Linux base para correr os scripts.

1 - Ativar o WSL (Ubuntu no Windows):
    Abre o PowerShell como Administrador e executa: wsl --install
2 - Reinicia o computador.
3 - Editor de Código (Recomendado): Instala o Visual Studio Code com a extensão "WSL" para gerires os ficheiros facilmente.


Fase 2: Instalação Automática (A Infraestrutura)
Toda a instalação do Docker, dependências e criação dos contentores é gerida automaticamente pelo script e pelo Ansible.

1 - Abre o terminal do Ubuntu (WSL).
  Cria uma pasta nova para ter este projeto e todos os ficheiros (Ex: Overleaf_Docker_Setup)
2 - Descarrega este repositório para o teu computador:
  git clone https://github.com/Henriquepm2003/Overleaf_Docker_Setup
  cd Overleaf_Docker_Setup
3 - Dá permissão de execução ao gestor principal:
  chmod +x gerir.sh
4 - Inicia a instalação:
  Executa ./gerir.sh
  Seleciona a Opção 1 (Instalar / Criar do Zero).
  Nota: O script vai instalar o Ansible, o Docker e fazer o build da imagem do Overleaf. Este processo pode demorar algum tempo, pois irá compilar a 
  imagem com a instalação completa do LaTeX.

Fase 3: Acesso ao Overleaf
Com a infraestrutura a correr, o acesso é imediato.

1 - Abre o teu browser e acede a: http://localhost:8085 (ou o porto que estiver definido no setup-overleaf.yml).
2 - Faz o Login com as credenciais de Administrador fornecidas para este projeto. (Ver final da mensagem depois de correr o gerir.sh)
3 - O teu ambiente Overleaf privado está pronto a usar!

Fase 4: Importar o Template do ISEC
Para começares a trabalhar no teu relatório com as normas corretas da escola:

1 - Acede ao portal/site do ISEC e descarrega o ficheiro .zip com o Template Oficial do Relatório.
2 - No teu Overleaf local (http://localhost), clica em "New Project" -> "Upload Project".
3 - Seleciona o ficheiro .zip que descarregaste.
4 - O projeto será carregado e podes começar a escrever e a compilar instantaneamente.

Como resolvemos o problema dos pacotes LaTeX? (O Dockerfile)
O proposito deste ponto é a eliminação do erro crónico de "pacote não encontrado" (missing packages) ao compilar projetos overleaf.
Em vez de usar a imagem base do Overleaf (que vem quase vazia), este projeto utiliza um Dockerfile customizado que é lido durante a Opção 1 do gerir.sh.

O que o Dockerfile faz:
1 - Interceta a imagem base.
2 - Liga-se ao repositório histórico oficial do TeX Live.
3 - Instala o pacote nuclear scheme-full (cerca de 4GB de dependências).
4 - "Congela" tudo numa nova imagem Docker local.

Assim, sempre que reinicias ou destróis o contentor, a compilação de PDFs no teu PC é instantânea, offline e à prova de falhas! Para gerires o estado do 
servidor no dia a dia, basta correr o ./gerir.sh e usar as opções de Iniciar (2) ou Parar (3).

!!!CUIDADO!!! Ao correr a opção 4, o projeto está feito para resistir á opção 4, se escolher não eliminar a base de dados, se por alguma razão decidir eliminar a BD e ainda tiver projetos criticios e importantes dentro do projeto, boa sorte XD
