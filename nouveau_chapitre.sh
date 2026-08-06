#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# nouveau_chapitre.sh — Génère le squelette d'un nouveau chapitre de cours
#
# Usage :
#   ./nouveau_chapitre.sh <niveau> <dossier_chapitre> "Titre du chapitre" note1 note2 note3 ...
#
# Exemple :
#   ./nouveau_chapitre.sh seconde-maths fonctions "Généralités sur les fonctions" \
#       definition variations tableau_signe exercices
#
# Ça crée :
#   seconde-maths/fonctions/index.qmd
#   seconde-maths/fonctions/definition.qmd      (order: 1)
#   seconde-maths/fonctions/variations.qmd      (order: 2)
#   seconde-maths/fonctions/tableau_signe.qmd   (order: 3)
#   seconde-maths/fonctions/exercices.qmd       (order: 4)
#
# Chaque fichier de notion est pré-rempli avec les blocs standards
# (définition, propriété/démonstration, exemple/correction, exercice),
# prêts à être complétés. La navigation prev/next est automatique
# (voir assets/auto-nav.lua) : pas besoin d'éditer les liens.
# ============================================================================

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <niveau> <dossier_chapitre> \"Titre du chapitre\" [note1 note2 ...]"
  echo "Exemple: $0 seconde-maths fonctions \"Généralités sur les fonctions\" definition variations exercices"
  exit 1
fi

NIVEAU="$1"
DOSSIER="$2"
TITRE_CHAPITRE="$3"
shift 3
NOTIONS=("$@")

if [[ ! -d "$NIVEAU" ]]; then
  echo "Erreur : le dossier de niveau '$NIVEAU' n'existe pas (seconde-maths / premiere-maths / terminale-maths ?)."
  exit 1
fi

CHEMIN="$NIVEAU/$DOSSIER"

if [[ -d "$CHEMIN" ]]; then
  echo "Erreur : $CHEMIN existe déjà. Choisis un autre nom ou supprime-le d'abord."
  exit 1
fi

mkdir -p "$CHEMIN"

# ---- index.qmd du chapitre ----
cat > "$CHEMIN/index.qmd" << EOF
---
title: "$TITRE_CHAPITRE"
description: "À compléter"
listing:
  type: table
  fields: [title, description]
  filter-ui: false
  sort: "order"
  contents:
    - "*.qmd"
  exclude:
    - path: index.qmd
---




::: {.bloc .rem}
<span class="bloc-titre">Attendus et savoir-faire :</span>

- À compléter
:::
EOF

echo "Créé : $CHEMIN/index.qmd"

# ---- une page par notion ----
ordre=1
for notion in "${NOTIONS[@]}"; do
  fichier="$CHEMIN/${notion}.qmd"
  titre_notion="$(echo "$notion" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')"

  cat > "$fichier" << EOF
---
title: "$titre_notion"
format:
  html:
    toc: true
    number-sections: false
description: "À compléter"
order: $ordre
---




## $titre_notion

::: {.bloc .def}
<span class="bloc-titre">Définition : </span>



:::

::: {.bloc .rem}
<span class="bloc-titre">Remarque : </span>



:::

::: {.bloc .thm}
<span class="bloc-titre">Propriété : </span>



:::

<details class="bloc demo"><summary>Démonstration : </summary>



</details>

::: {.bloc .ex}
<div class="bloc-titre">Exemple :<span class="exemp-extra"> </span></div>

<details class="bloc cor"><summary>Afficher la correction :</summary>



</details>
:::

## Exercice

::: {.bloc .exo}
<span class="exo-num"></span><span class="exo-extra"> </span>



<details class="bloc cor"><summary>Afficher la correction :</summary>



</details>
:::
EOF

  echo "Créé : $fichier (order: $ordre)"
  ordre=$((ordre + 1))
done

# ---- mise à jour de _quarto.yml : rappel manuel ----
echo ""
echo "✅ Squelette créé pour le chapitre '$TITRE_CHAPITRE' dans $CHEMIN/"
echo ""
echo "⚠️  N'oublie pas d'ajouter ces lignes dans _quarto.yml, section sidebar > $NIVEAU > contents :"
echo ""
echo "        - section: \"$TITRE_CHAPITRE\""
echo "          contents:"
echo "            - $CHEMIN/index.qmd"
for notion in "${NOTIONS[@]}"; do
  echo "            - $CHEMIN/${notion}.qmd"
done
echo ""
echo "Et dans $NIVEAU/index.qmd, ajoute \"$DOSSIER/index.qmd\" à la liste \"contents:\" du listing."
