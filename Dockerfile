# 1. Partir da imagem original e vazia
FROM sharelatex/sharelatex:latest

# 2. Apontar para o servidor histórico fiável (Universidade do Utah)
RUN tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2025/tlnet-final

# 3. Desligar a segurança restrita e instalar a "Bomba Atómica" (os 4GB)
RUN tlmgr --verify-repo=none install scheme-full