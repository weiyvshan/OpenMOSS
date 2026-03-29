FROM node:22-bookworm-slim AS frontend-builder
WORKDIR /build
COPY webui/package*.json ./webui/
WORKDIR /build/webui
RUN npm ci
WORKDIR /build
COPY webui ./webui
RUN npm --prefix webui run build

FROM python:3.11-slim AS runtime
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY skills ./skills
COPY prompts ./prompts
COPY rules ./rules
COPY config.example.yaml ./config.example.yaml
COPY --from=frontend-builder /build/static ./static
RUN mkdir -p /data/config /workspace /app/data
ENV OPENMOSS_CONFIG=/data/config/config.yaml
EXPOSE 6565
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "6565"]
