-- exercise-counter.lua
-- Affiche dans le bloc : "Exercice N : " + texte optionnel (si présent)
-- Affiche dans la sidebar (H2) : "Exercice N" uniquement
-- Numérotation continue (pas de reset)

local exo_count = 0

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function has_class(el, cls)
  if not el or not el.classes then return false end
  for _, c in ipairs(el.classes) do if c == cls then return true end end
  return false
end

function Pandoc(doc)
  local out = {}
  local i = 1
  while i <= #doc.blocks do
    local b = doc.blocks[i]

    -- Cherche un H2 exactement "Exercice"
    if b.t == "Header" and b.level == 2 then
      local title = trim(pandoc.utils.stringify(b.content))
      if title == "Exercice" then
        exo_count = exo_count + 1

        -- 1) Met le H2 (et donc la sidebar) à "Exercice N" SANS suffixe ni ":"
        b.content = { pandoc.Str("Exercice"), pandoc.Space(), pandoc.Str(tostring(exo_count)) }
        table.insert(out, b)

        -- 2) Si un bloc .bloc.exo suit immédiatement, remplir l'en-tête du bloc
        local nextb = doc.blocks[i + 1]
        if nextb and nextb.t == "Div" and has_class(nextb, "bloc") and has_class(nextb, "exo") then
          local function span_handler(s)
            -- Remplit <span class="exo-num"></span> avec "Exercice N : "
            if s.t == "Span" and has_class(s, "exo-num") then
              return pandoc.Span({ pandoc.Strong({ pandoc.Str("Exercice " .. tostring(exo_count) .. " : ") }) }, s.attr)
            end
            -- Laisse <span class="exo-extra">...</span> tel quel (pas de " : " ajouté ici)
            return s
          end
          nextb = pandoc.walk_block(nextb, { Span = span_handler })
          table.insert(out, nextb)
          i = i + 2
        else
          i = i + 1
        end

      else
        table.insert(out, b)
        i = i + 1
      end

    else
      table.insert(out, b)
      i = i + 1
    end
  end

  return pandoc.Pandoc(out, doc.meta)
end
