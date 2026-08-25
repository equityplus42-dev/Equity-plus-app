#!/bin/bash
echo "Setting remote URL..."
git remote set-url origin https://github.com/equityplus42-dev/Equity-plus-app.git
echo "Pulling latest changes..."
git pull origin main
