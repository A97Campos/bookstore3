# `python-base` configura todas as nossas variáveis de ambiente compartilhadas
# Usando a imagem base Python 3.10-slim para compatibilidade.
FROM python:3.10-slim AS python-base 
# Corrigi o uso de "AS" para maiúsculas

# Variáveis de ambiente relacionadas ao Python
ENV PYTHONUNBUFFERED=1 \
    # Impede que o Python crie arquivos .pyc
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # Variáveis de ambiente para o pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # Variáveis de ambiente para o Poetry
    # POETRY_HOME é onde Poetry armazena arquivos internos, não necessariamente seu executável.
    POETRY_HOME="/opt/poetry" \
    # Faz com que o Poetry crie o ambiente virtual na raiz do projeto, nomeado como `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # Não faz perguntas interativas durante a instalação/operação do Poetry
    POETRY_NO_INTERACTION=1 \
    \
    # Caminhos para o setup do ambiente e o ambiente virtual
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Atualiza os pacotes do sistema e instala as dependências necessárias
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        build-essential \
        libpq-dev \
        curl \
    && rm -rf /var/lib/apt/lists/* 
    # Limpa o cache do apt para reduzir o tamanho da imagem

# Instala pipx (a ferramenta recomendada para instalar o Poetry de forma isolada)
RUN pip install pipx

# Garante que o diretório de binários do pipx (/root/.local/bin) esteja no PATH.
# Isso é crucial para que o comando 'poetry' seja encontrado após a instalação.
ENV PATH="/root/.local/bin:$PATH"

# Instala o Poetry usando pipx, FORÇANDO A VERSÃO 1.8.2 (ou a mais recente estável, como 1.8.x).
# Esta versão garante que o "--no-dev" seja suportado.
RUN pipx install poetry==1.8.2

# Adiciona o diretório POETRY_HOME/bin ao PATH também, apenas para segurança,
# caso Poetry use esse caminho para outros executáveis internos.
ENV PATH="$POETRY_HOME/bin:$PATH"

# Copia os arquivos de requisitos do projeto para garantir que sejam cacheados.
WORKDIR /opt/pysetup
COPY poetry.lock pyproject.toml ./

# Instala as dependências de runtime do projeto usando Poetry.
# Com Poetry 1.8.2, a opção --only main funcionará.
RUN poetry install

WORKDIR /app

COPY . /app/

# Expõe a porta que a aplicação Django usará
EXPOSE 8000

# Comando para iniciar o servidor Django quando o contêiner for executado
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
