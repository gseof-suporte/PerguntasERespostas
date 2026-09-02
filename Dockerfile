FROM rocker/shiny:latest

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria e ativa ambiente virtual Python
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instala PyTorch e Sentence-Transformers
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir sentence-transformers

# Instala os pacotes R necessários
RUN R -e "install.packages(c('shiny', 'bslib', 'readxl', 'shinycssloaders', 'reticulate'), repos='https://cloud.r-project.org/')"

WORKDIR /app
COPY . /app

# Pré-baixa o modelo HuggingFace na compilação do container
RUN python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')"

# Porta padrão do Render
EXPOSE 10000

CMD ["Rscript", "app.R"]
