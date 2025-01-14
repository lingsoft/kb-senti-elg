# Build venv
FROM python:3.8-slim as venv-build
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt load_model.py /app/
RUN pip install --no-cache-dir -r requirements.txt && mkdir local_kb_bert_senti && python load_model.py

# Install basic deps
FROM python:3.8-slim
WORKDIR /elg

RUN apt-get update && apt-get -y install --no-install-recommends tini \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid 1001 "elg" && adduser --disabled-password --gecos "ELG User,,," --home /elg --ingroup elg --uid 1001 elg && chmod +x /usr/bin/tini
COPY --chown=elg:elg --from=venv-build /opt/venv /opt/venv
COPY --chown=elg:elg --from=venv-build /app/local_kb_bert_senti /elg/local_kb_bert_senti

USER elg:elg
COPY --chown=elg:elg app.py utils.py docker-entrypoint.sh /elg/

ENV PATH="/opt/venv/bin:$PATH"
ENV WORKERS=2
ENV TIMEOUT=240
ENV WORKER_CLASS=sync
ENV LOGURU_LEVEL=INFO
ENV PYTHON_PATH="/opt/venv/bin"

RUN chmod +x /elg/docker-entrypoint.sh
ENTRYPOINT ["/elg/docker-entrypoint.sh"]