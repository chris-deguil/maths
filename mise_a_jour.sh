#!/usr/bin/env bash
set -euo pipefail

# Usage: ./mise_a_jour.sh "Message de commit"
MSG="${1:-Mise à jour automatique $(date '+%Y-%m-%d %H:%M:%S')}"

# 0) Vérifs de base
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Erreur: ce dossier n'est pas un dépôt git."
  exit 1
}

# 1) Assainir .gitignore (éviter de versionner le site généré et les installeurs)
ensure_ignore() {
  local pattern="$1"
  grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >> .gitignore
}
touch .gitignore
ensure_ignore "_site/"
ensure_ignore ".quarto/"
ensure_ignore "*.deb"
ensure_ignore "*.msi"
ensure_ignore "*.pkg"
ensure_ignore "*.exe"

# 2) Retirer de l'index tout fichier déjà suivi qui ne doit pas l'être
#    (ex: _site/* et *.deb si jamais ils ont été ajoutés)
#    -> sans supprimer tes fichiers locaux
mapfile -d '' TRACKED_BAD < <(git ls-files -z -- '_site/*' '.quarto/*' '*.deb' '*.msi' '*.pkg' '*.exe' || true)
if (( ${#TRACKED_BAD[@]} )); then
  git rm -r --cached --quiet -- "${TRACKED_BAD[@]}"
  echo "Nettoyage: suppression de l'index des éléments générés/installeurs."
fi

# 3) Garde-fou: refuser de committer des fichiers > 95 Mo
check_large_staged() {
  local too_big=0
  # Lister ce qui est prêt à être committé après 'git add'
  while IFS= read -r -d '' path; do
    # Ignorer les suppressions
    if [[ -f "$path" ]]; then
      size_bytes=$(wc -c < "$path")
      if (( size_bytes > 95*1024*1024 )); then
        echo "❌ Fichier trop volumineux (>95 Mo) détecté: $path"
        too_big=1
      fi
    fi
  done < <(git diff --cached --name-only -z)
  return $too_big
}

# 4) Ajouter et committer
git add -A

# Empêcher l'ajout d'un gros fichier par erreur
if ! check_large_staged; then
  echo "Astuce: ajoute ces gros fichiers à .gitignore ou déplace-les hors du dépôt."
  exit 1
fi

# Rien à committer ?
if git diff --cached --quiet; then
  echo "Rien à committer (aucune modification indexée)."
  exit 0
fi

# Commit
git commit -m "$MSG"

# 5) Push
git push
echo "✅ Modifications envoyées. La publication automatique va se lancer sur GitHub."
