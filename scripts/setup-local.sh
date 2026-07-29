#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
find "$script_dir" -type f -name "*.sh" -exec chmod +x {} +

if [[ ! -f .env ]]; then
    cp .env.example .env
    echo 'env vars set'
fi

npm ci

echo 'Seting up db'

docker compose up -d --wait postgres

npm run db:migrate
npm run db:seed

echo 'local development setup'
