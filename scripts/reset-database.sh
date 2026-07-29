#!/usr/bin/env bash
set -euo pipefail

echo 'Deleting database'

docker compose down -v
docker compose up -d --wait postgres

npm run db:migrate
npm run db:seed

echo 'Database reset'
