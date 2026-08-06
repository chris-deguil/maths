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
    // 1) Réinitialiser les tampons pour CETTE exécution
    pyodide.runPython(`
import sys, io
if not hasattr(sys, '_orig_stdout'):
    sys._orig_stdout = sys.stdout
if not hasattr(sys, '_orig_stderr'):
    sys._orig_stderr = sys.stderr
sys.stdout = io.StringIO()
sys.stderr = io.StringIO()
`);

    // 2) Exécuter le code
    await pyodide.runPythonAsync(code);

    // 3) Récupérer les sorties de CETTE exécution uniquement
    const outText = pyodide.runPython("sys.stdout.getvalue()");
    const errText = pyodide.runPython("sys.stderr.getvalue()");

    // 4) Afficher
    printToOut((errText ? (errText + "\n") : "") + (outText || "✓ Exécution terminée sans sortie."), !errText);

  }catch(err){
    printToOut(String(err));
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