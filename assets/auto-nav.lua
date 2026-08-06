-- assets/auto-nav.lua
--
-- Génère automatiquement le bloc de navigation "page précédente / page suivante"
-- en bas de chaque page d'un chapitre, à partir de l'ordre déclaré dans le champ
-- "order:" du front-matter de chaque .qmd (le même champ utilisé par le listing
-- de l'index.qmd du chapitre).
--
-- Fini le <a class="prev" href="historique.html"> codé en dur : si tu renommes,
-- réordonnes ou insères une page, la navigation se met à jour toute seule au
-- prochain "quarto render".
--
-- Fonctionnement :
--   1) Au premier passage (Meta), on lit le dossier du fichier courant, on liste
--      tous les .qmd du même dossier (hors index.qmd), on les trie par leur champ
--      "order" (front-matter YAML), et on trouve la position du fichier courant.
--   2) On insère en fin de document un <div class="nav-pages"> avec les liens
--      vers les fichiers .html précédent / suivant (mêmes noms de base que les .qmd).
--
-- Prérequis : chaque .qmd d'un chapitre doit avoir un champ "order: N" dans son
-- front-matter (comme c'est déjà le cas dans le chapitre suite1 existant).

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Lit le champ "order:" et le "title:" dans le front-matter YAML d'un fichier .qmd
local function read_front_matter(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()

  local yaml = content:match("^%-%-%-\n(.-)\n%-%-%-")
  if not yaml then return nil end

  local order = yaml:match("\norder:%s*(%-?%d+)") or yaml:match("^order:%s*(%-?%d+)")
  local title = yaml:match("\ntitle:%s*[\"'](.-)[\"']") or yaml:match("^title:%s*[\"'](.-)[\"']")

  return {
    order = order and tonumber(order) or nil,
    title = title or ""
  }
end

-- Liste les fichiers .qmd du dossier (hors index.qmd), triés par "order"
local function list_chapter_files(dir)
  local files = {}
  local p = io.popen('ls "' .. dir .. '" 2>/dev/null')
  if not p then return files end
  for name in p:lines() do
    if name:match("%.qmd$") and name ~= "index.qmd" then
      local fm = read_front_matter(dir .. "/" .. name)
      if fm and fm.order then
        table.insert(files, { name = name, order = fm.order, title = fm.title })
      end
    end
  end
  p:close()
  table.sort(files, function(a, b) return a.order < b.order end)
  return files
end

local input_path = nil

function Meta(meta)
  -- PANDOC_STATE.input_files donne le chemin du fichier .qmd en cours de traitement
  if PANDOC_STATE and PANDOC_STATE.input_files and PANDOC_STATE.input_files[1] then
    input_path = PANDOC_STATE.input_files[1]
  end
  return meta
end

function Pandoc(doc)
  if not input_path then return doc end

  local dir = input_path:match("^(.*)/[^/]+$") or "."
  local current_name = input_path:match("([^/]+)$")

  local files = list_chapter_files(dir)
  if #files < 2 then return doc end

  local current_index = nil
  for i, f in ipairs(files) do
    if f.name == current_name then
      current_index = i
      break
    end
  end
  if not current_index then return doc end

  local prev = files[current_index - 1]
  local nextf = files[current_index + 1]

  local function html_name(qmd_name)
    return qmd_name:gsub("%.qmd$", ".html")
  end

  local prev_link = prev
    and ('<a class="prev" href="' .. html_name(prev.name) .. '" title="' .. prev.title .. '">⬅️</a>')
    or ""
  local next_link = nextf
    and ('<a class="next" href="' .. html_name(nextf.name) .. '" title="' .. nextf.title .. '">➡️</a>')
    or ""

  local nav_html = '<div class="nav-pages">' .. prev_link .. next_link .. "</div>"

  table.insert(doc.blocks, pandoc.RawBlock("html", nav_html))
  return doc
end
