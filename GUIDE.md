# Guide interne — site pédagogique (repartir de zéro, v2)

Ce document explique comment fonctionne le site après la remise à zéro, pour que
tu puisses ajouter du contenu sans avoir à redemander l'architecture à chaque fois.

## 1. Structure générale

```
_quarto.yml              -> config globale : navbar, sidebar, thème
index.qmd                -> page d'accueil
seconde-maths/            -> niveau Seconde
premiere-maths/           -> niveau Première
terminale-maths/          -> niveau Terminale
  _metadata.yml            -> thème appliqué à tout le niveau
  index.qmd                 -> page de listing des chapitres du niveau
  <chapitre>/
    index.qmd                -> page de listing des notions du chapitre (auto, via "order")
    <notion>.qmd              -> une page de cours (order: N dans le front-matter)
assets/
  css/general.scss          -> thème général (navbar, sidebar, cartes)
  css/maths.css              -> les blocs def/thm/ex/rem/exo/demo
  css/pyodide-mkdocs.css     -> style de l'éditeur Python intégré
  js/pyodide-mkdocs.js        -> logique de l'éditeur Python intégré
  mathjax-macros.html         -> macros LaTeX (\R, \N, \ve{}, \lim, etc.)
  exercise-counter.lua        -> numérote automatiquement les "## Exercice"
  auto-nav.lua                -> génère automatiquement le prev/next en bas de page
code_python/               -> scripts .py utilisés dans les exercices interactifs
nouveau_chapitre.sh        -> génère le squelette d'un nouveau chapitre
mise_a_jour.sh             -> commit + push automatique vers GitHub
```

SNT a été entièrement retiré (navbar, sidebar, fichiers, CSS `snt.css`,
filtre `macros_logo.lua`). Le contenu de l'ancien Première/Terminale a été
archivé (voir section 5), pas supprimé définitivement.

## 2. Ajouter un chapitre — méthode recommandée

```bash
./nouveau_chapitre.sh seconde-maths fonctions "Généralités sur les fonctions" \
    definition variations tableau_signe exercices
```

Ça crée `seconde-maths/fonctions/` avec un `index.qmd` et un `.qmd` par notion,
déjà pré-remplis avec les blocs standards et un `order:` croissant.

Le script t'affiche ensuite le morceau de YAML à coller dans `_quarto.yml`
(sidebar) et dans `seconde-maths/index.qmd` (listing). Cette étape reste
manuelle (Quarto ne permet pas de générer la sidebar dynamiquement), mais
c'est un copier-coller de 30 secondes.

## 3. Les blocs de contenu (rappel)

```markdown
::: {.bloc .def}
<span class="bloc-titre">Définition : </span>
...
:::

::: {.bloc .thm}
<span class="bloc-titre">Propriété : </span>
...
:::

<details class="bloc demo"><summary>Démonstration : </summary>
...
</details>

::: {.bloc .ex}
<div class="bloc-titre">Exemple :<span class="exemp-extra"> précision optionnelle </span></div>
...
<details class="bloc cor"><summary>Afficher la correction :</summary>
...
</details>
:::

::: {.bloc .rem}
<span class="bloc-titre">Remarque : </span>
...
:::
```

Pour un exercice numéroté automatiquement, mets un titre `## Exercice`
juste avant :

```markdown
## Exercice

::: {.bloc .exo}
<span class="exo-num"></span><span class="exo-extra"> Étude par le quotient </span>

Énoncé...

<details class="bloc cor"><summary>Afficher la correction :</summary>
Correction...
</details>
:::
```

Le filtre `exercise-counter.lua` remplit automatiquement `exo-num` avec
"Exercice N :" (numérotation continue sur la page).

## 4. Navigation automatique (prev / next)

Tant que chaque `.qmd` d'un chapitre a un champ `order:` dans son
front-matter (ce que fait déjà `nouveau_chapitre.sh`), le filtre
`assets/auto-nav.lua` ajoute automatiquement les flèches précédent/suivant
en bas de page, dans le bon ordre. **Tu n'as plus jamais besoin d'écrire
`<div class="nav-pages">` toi-même.**

## 5. Éditeur Python interactif

Sur une page qui a besoin d'un éditeur Python exécutable dans le navigateur
(Pyodide), ajoute ceci dans le front-matter de la page :

```yaml
include-in-header:
  - text: |
      <link rel="stylesheet" href="../../assets/css/pyodide-mkdocs.css">
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.css">
      <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/python/python.js"></script>
      <script src="https://cdn.jsdelivr.net/pyodide/v0.26.4/full/pyodide.js"></script>
      <script src="../../assets/js/pyodide-mkdocs.js" defer></script>
```

(Adapte le nombre de `../` selon la profondeur du fichier.)

## 6. Ancien contenu archivé

L'ancien contenu de Première et Terminale (avant remise à zéro) est
conservé dans le dossier `_archive-ancien-programme/` (hors navigation,
non publié) pour que tu puisses réutiliser des textes, énoncés ou images
en les adaptant au nouveau programme. Tu peux le supprimer définitivement
quand tu n'en as plus besoin.

## 7. Mise en ligne

```bash
./mise_a_jour.sh "Message de commit"
```

Un seul workflow GitHub Actions (`quarto-gh-pages.yml`) construit et publie
le site sur `gh-pages` à chaque push sur `main`.
