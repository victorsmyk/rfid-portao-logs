#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
node src/clear.js
printf "Pressione Enter para sair..."
read _
echo