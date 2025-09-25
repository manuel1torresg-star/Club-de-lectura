#!/usr/bin/env bash
# deploy_to_github.sh
# Usage: ./deploy_to_github.sh
# This script will initialize git (if needed), create a GitHub repo using gh if available,
# or push using HTTPS with a Personal Access Token (PAT). It prompts for required values.
set -e

echo "== Deploy automatizado a GitHub - Club de Lectura =="
# ensure inside project folder with index.html
if [ ! -f index.html ]; then
  echo "ERROR: no se encontró index.html en la carpeta actual. Ejecuta este script desde la carpeta del proyecto."
  exit 1
fi

# Initialize git if needed
if [ ! -d .git ]; then
  git init
  git add .
  git commit -m "Initial commit — PWA Club de Lectura"
  git branch -M main || true
  echo "Repositorio git inicializado y commit creado."
else
  echo "Repositorio git ya existe."
fi

read -p "Nombre del repo en GitHub (ej: club-de-lectura): " REPO_NAME
if [ -z "$REPO_NAME" ]; then
  echo "Nombre de repo vacio. Abortando."
  exit 1
fi

# prefer gh if available
if command -v gh >/dev/null 2>&1; then
  echo "gh CLI encontrada."
  # check authentication
  if gh auth status >/dev/null 2>&1; then
    echo "Autenticado con gh."
    # try to detect username
    GH_USER=$(gh api user --jq .login 2>/dev/null || true)
    if [ -z "$GH_USER" ]; then
      read -p "Usuario GitHub (si lo quieres especificar): " GH_USER
    fi
    VISIBILITY="public"
    read -p "Visibilidad (public/private) [public]: " VIS
    if [ "$VIS" = "private" ]; then VISIBILITY="private"; fi
    echo "Creando repo https://github.com/$GH_USER/$REPO_NAME ($VISIBILITY) ..."
    # create repo from current folder and push
    gh repo create "$GH_USER/$REPO_NAME" --"$VISIBILITY" --source=. --remote=origin --push || {
      echo "gh repo create falló. Revisa errores."
      exit 1
    }
    echo "Repo creado y push realizado."
    exit 0
  else
    echo "gh CLI instalada pero no has iniciado sesión (gh auth login). Intentaré usar gh pero te pedirá autenticar."
    gh auth login || true
    if gh auth status >/dev/null 2>&1; then
      echo "Ahora estás autenticado. Reejecuta el script si algo falla."
    fi
  fi
fi

# Fallback: usar HTTPS con PAT
echo "Usando método HTTPS con Personal Access Token (PAT)."
read -p "Tu usuario de GitHub (ej: tu-usuario): " GH_USER
if [ -z "$GH_USER" ]; then
  echo "Usuario no proporcionado. Abortando."
  exit 1
fi
read -s -p "Introduce tu Personal Access Token (PAT) de GitHub (se usará temporalmente para push): " GITHUB_PAT
echo
if [ -z "$GITHUB_PAT" ]; then
  echo "No introdujiste PAT. Abortando."
  exit 1
fi
VISIBILITY="public"
read -p "Visibilidad del repo (public/private) [public]: " VIS
if [ "$VIS" = "private" ]; then VISIBILITY="private"; fi

# Create repo via GitHub API
AUTH_HEADER="Authorization: token $GITHUB_PAT"
POST_DATA="{\"name\": \"$REPO_NAME\", \"private\": $( [ "$VISIBILITY" = "private" ] && echo true || echo false ) }"
echo "Creando repo en GitHub vía API..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "$AUTH_HEADER" -d "$POST_DATA" https://api.github.com/user/repos)
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "422" ]; then
  if [ "$RESPONSE" = "201" ]; then
    echo "Repositorio creado en GitHub."
  else
    echo "Respuesta 422: el repo probablemente ya existe."
  fi
else
  echo "Falló la creación del repo. Código HTTP: $RESPONSE"
  echo "Salida de ejemplo: intenta crear el repo manualmente desde GitHub."
  exit 1
fi

# set remote with token for initial push (this uses token in URL temporarily)
REMOTE_URL="https://$GH_USER:$GITHUB_PAT@github.com/$GH_USER/$REPO_NAME.git"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"
echo "Haciendo push a origin main ..."
git push -u origin main
echo "Push completado."
# unset sensitive variables (best effort)
unset GITHUB_PAT
echo "Listo. Abre: https://github.com/$GH_USER/$REPO_NAME"
