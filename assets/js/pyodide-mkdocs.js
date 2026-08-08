// assets/python/pyodide-mkdocs-multi.js
// Supporte N éditeurs sur la même page en les scopant par .editor-shell

window.addEventListener('DOMContentLoaded', () => {
  // Charge Pyodide UNE fois et partage l'instance
  const pyodideReady = (async () => {
    try {
      return await loadPyodide({ indexURL: "https://cdn.jsdelivr.net/pyodide/v0.26.4/full/" });
    } catch (e) {
      console.error("Pyodide load error:", e);
      return null;
    }
  })();

  // Initialise un éditeur dans un conteneur donné
  function initEditorShell(shell) {
    // 0) Récupération SCOPÉE (dans `shell` uniquement)
    const ta        = shell.querySelector('#code');
    const outBox    = shell.querySelector('#out');           // <div id="out"><pre></pre></div>
    const btnRun    = shell.querySelector('#run');
    const btnCheck  = shell.querySelector('#check');
    const btnDl     = shell.querySelector('#download');
    const btnReset  = shell.querySelector('#reset');
    const btnClear  = shell.querySelector('#clear');
    const btnSave   = shell.querySelector('#save');          // optionnel

    // 1) Éditeur (CodeMirror si présent)
    let cm = null;
    if (window.CodeMirror && ta) {
      cm = CodeMirror.fromTextArea(ta, {
        mode: "python",
        lineNumbers: true,
        indentUnit: 4,
        tabSize: 4,
        indentWithTabs: false
      });
    }
    const getCode = () => cm ? cm.getValue() : (ta ? ta.value : "");
    const setCode = (v) => cm ? cm.setValue(v) : (ta ? (ta.value = v) : null);

    // 2) Utilitaires UI (scopés)
    const setBusy = (b) => [btnRun, btnCheck, btnReset, btnDl, btnClear, btnSave]
      .filter(Boolean).forEach(el => el.disabled = b);

    const printToOut = (text, ok=false) => {
      if (!outBox) return;
      const pre = outBox.querySelector('pre') || outBox;
      pre.textContent = text;
      if (pre.style) pre.style.color = ok ? "#065f46" : "#111827";
    };

    const showImage = (base64png) => {
      if (!outBox) return;
      // Retire une éventuelle image précédente
      const old = outBox.querySelector('img.pyodide-figure');
      if (old) old.remove();
      if (!base64png) return;
      const img = document.createElement('img');
      img.className = 'pyodide-figure';
      img.src = 'data:image/png;base64,' + base64png;
      img.style.maxWidth = '100%';
      img.style.display = 'block';
      img.style.marginTop = '8px';
      outBox.appendChild(img);
    };

    // 3) Quand Pyodide est prêt, activer les boutons d'exécution de CE shell
    pyodideReady.then((pyodide) => {
      if (!pyodide) { printToOut("Échec de chargement de Pyodide."); return; }
      if (btnRun)   btnRun.disabled = false;
      if (btnCheck) btnCheck.disabled = false;
    });

    // 4) Exécution Python (utilise l'instance partagée)
   async function runPython(code){
  const pyodide = await pyodideReady;
  if (!pyodide){ printToOut("Pyodide indisponible."); return; }

  setBusy(true); printToOut("… exécution en cours …");
  try{
    // 0) Charger automatiquement les paquets utilisés par le code (matplotlib, numpy, sympy...)
    await pyodide.loadPackagesFromImports(code);

    // 1) Réinitialiser les tampons pour CETTE exécution + préparer matplotlib en mode "image"
    pyodide.runPython(`
import sys, io
if not hasattr(sys, '_orig_stdout'):
    sys._orig_stdout = sys.stdout
if not hasattr(sys, '_orig_stderr'):
    sys._orig_stderr = sys.stderr
sys.stdout = io.StringIO()
sys.stderr = io.StringIO()

if "matplotlib" in sys.modules or "matplotlib.pyplot" in sys.modules:
    import matplotlib
    matplotlib.use("Agg")
`);

    // 2) Exécuter le code
    await pyodide.runPythonAsync(code);

    // 3) Récupérer les sorties de CETTE exécution uniquement
    const outText = pyodide.runPython("sys.stdout.getvalue()");
    const errText = pyodide.runPython("sys.stderr.getvalue()");

    // 3bis) Capturer une éventuelle figure matplotlib créée par le code, sans exiger plt.show()
    const imgB64 = pyodide.runPython(`
def _capture_figure():
    try:
        import base64, io as _io
        import matplotlib.pyplot as plt
        if not plt.get_fignums():
            return None
        buf = _io.BytesIO()
        plt.savefig(buf, format="png", bbox_inches="tight", dpi=110)
        plt.close("all")
        buf.seek(0)
        return base64.b64encode(buf.read()).decode("ascii")
    except Exception:
        return None
_capture_figure()
`);

    // 4) Afficher texte + image
    printToOut((errText ? (errText + "\n") : "") + (outText || (imgB64 ? "" : "✓ Exécution terminée sans sortie.")), !errText);
    showImage(imgB64);

  }catch(err){
    printToOut(String(err && err.message ? err.message : err));
    showImage(null);
  }finally{
    // 5) Restaurer stdout/stderr d’origine (important si plusieurs blocs partagent la même instance)
    try{
      pyodide.runPython("import sys; sys.stdout = sys._orig_stdout; sys.stderr = sys._orig_stderr");
    }catch(_){/* ignore */}
    setBusy(false);
  }
}

    // 5) Écouteurs (scopés)
    if (btnRun)   btnRun.addEventListener('click', async () => { await runPython(getCode()); });
    if (btnCheck) btnCheck.addEventListener('click', async () => { await runPython(getCode()); });

    if (btnReset) btnReset.addEventListener('click', () => {
  setCode("");
  printToOut("► Code réinitialisé.");
});
    if (btnClear) btnClear.addEventListener('click', () => printToOut(""));

    if (btnDl) btnDl.addEventListener('click', () => {
      const blob = new Blob([getCode()], { type: "text/x-python" });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = "exercice.py";
      a.click();
      URL.revokeObjectURL(a.href);
    });

    if (btnSave) btnSave.addEventListener('click', () => {
      try {
        // Clé distincte par shell pour ne pas écraser d'autres blocs
        const key = (shell.id ? `exo_pyodide_code_${shell.id}` : "exo_pyodide_code");
        localStorage.setItem(key, getCode());
        printToOut("✔ Code sauvegardé localement.", true);
      } catch (e) {
        printToOut("Impossible de sauvegarder.");
      }
    });

    // 6) Raccourci clavier (Ctrl/Cmd + Enter) — uniquement quand le focus est dans CE shell
    shell.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        e.preventDefault();
        if (btnRun && !btnRun.disabled) btnRun.click();
      }
    }, true);
  }

  // Initialiser TOUS les blocs présents sur la page
  document.querySelectorAll('.editor-shell').forEach(initEditorShell);
});