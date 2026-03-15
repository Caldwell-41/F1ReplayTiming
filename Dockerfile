# ---------- Builder ----------
FROM python:3.11-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl build-essential ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Copy source
COPY backend ./backend
COPY frontend ./frontend

# Backend deps
WORKDIR /app/backend
RUN pip install --upgrade pip \
 && pip install -r requirements.txt

# Frontend deps + build
WORKDIR /app/frontend
ENV NEXT_PUBLIC_API_URL=http://localhost:8000
RUN npm install && npm run build

# ---------- Runtime ----------
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install Node.js runtime + serve
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g serve

# Copy built artifacts
COPY --from=builder /app/backend ./backend
COPY --from=builder /app/frontend ./frontend

# Data directory
VOLUME ["/data"]

# Expose frontend on 32098 (external default)
EXPOSE 32098

# Start backend + frontend
CMD bash -lc "\
  cd /app/backend && uvicorn main:app --host 0.0.0.0 --port 8000 & \
  cd /app/frontend && npm run start -- -p 3000 \
"
