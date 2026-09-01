FROM rocker/shiny:latest

# 1. Dependências do sistema Linux para o Shiny e leitura do Excel (libxml2, etc)
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalação dos pacotes R necessários (incluindo readxl)
RUN R -e "install.packages(c('shiny', 'bslib', 'jsonlite', 'httr', 'markdown', 'shinycssloaders', 'readxl'), repos='https://cloud.r-project.org/')"

# 3. Define pasta de trabalho e copia TODOS os arquivos (incluindo a planilha)
WORKDIR /app
COPY . /app

# 4. Configuração de porta e execução
EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/app/app.R', host = '0.0.0.0', port = 3838)"]
