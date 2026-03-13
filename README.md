🗺️ Roadmap: Setup do Overleaf Local (ISEC)
Este guia explica como preparar e executar um ambiente local do Overleaf com todos os pacotes LaTeX (scheme-full) pré-instalados, utilizando WSL, 
Ansible e Docker. Ideal para compilar relatórios sem falhas de pacotes e sem depender da internet.

Fase 1: Pré-requisitos (Preparar o PC)
O projeto automatiza quase tudo, mas precisas do ambiente Linux base para correr os scripts.

Ativar o WSL (Ubuntu no Windows):

Abre o PowerShell como Administrador e executa: wsl --install

Reinicia o computador.

Editor de Código (Recomendado):

Instala o Visual Studio Code com a extensão "WSL" para gerires os ficheiros facilmente.

Fase 2: Instalação Automática (A Infraestrutura)
Toda a instalação do Docker, dependências e criação dos contentores é gerida automaticamente pelo nosso script e pelo Ansible.

Abre o terminal do Ubuntu (WSL).

Descarrega este repositório para o teu computador:

Bash
git clone https://github.com/TEU-USER/Overleaf-Docker-Setup.git
cd Overleaf-Docker-Setup
Dá permissão de execução ao gestor principal:

Bash
chmod +x gerir.sh
Inicia a instalação:

Executa ./gerir.sh

Seleciona a Opção 1 (Instalar / Criar do Zero).

Nota: O script vai instalar o Ansible, o Docker e fazer o build da imagem do Overleaf. Este processo pode demorar algum tempo, pois irá compilar a 
imagem com a instalação completa do LaTeX.

Fase 3: Acesso ao Overleaf
Com a infraestrutura a correr, o acesso é imediato.

Abre o teu browser e acede a: http://localhost (ou o porto que estiver definido no setup-overleaf.yml).

Faz o Login com as credenciais de Administrador fornecidas para este projeto.

O teu ambiente Overleaf privado está pronto a usar!

Fase 4: Importar o Template do ISEC
Para começares a trabalhar no teu relatório com as normas corretas da escola:

Acede ao portal/site do ISEC e descarrega o ficheiro .zip com o Template Oficial do Relatório.

No teu Overleaf local (http://localhost), clica em "New Project" -> "Upload Project".

Seleciona o ficheiro .zip que descarregaste.

O projeto será carregado e podes começar a escrever e a compilar instantaneamente.

🛠️ Como resolvemos o problema dos pacotes LaTeX? (O Dockerfile)
A grande vantagem deste projeto é a eliminação do erro crónico de "pacote não encontrado" (missing packages) ao compilar documentos complexos.

Em vez de usar a imagem base do Overleaf (que vem quase vazia), este projeto utiliza um Dockerfile customizado que é lido durante a Opção 1 do gerir.sh.

O que o Dockerfile faz:

Interceta a imagem base.

Liga-se ao repositório histórico oficial do TeX Live.

Instala o pacote nuclear scheme-full (cerca de 4GB de dependências).

"Congela" tudo numa nova imagem Docker local.

Assim, sempre que reinicias ou destróis o contentor, a compilação de PDFs no teu PC é instantânea, offline e à prova de falhas! Para gerires o estado do 
servidor no dia a dia, basta correr o ./gerir.sh e usar as opções de Iniciar (2) ou Parar (3).
