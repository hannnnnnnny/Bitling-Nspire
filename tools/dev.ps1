param(
    [ValidateSet('install','test','build','play','gallery','benchmark')]
    [string]$Task = 'play',
    [string]$Luna = ''
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$bundledPython = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$venvPython = Join-Path $taskRoot '.venv/Scripts/python.exe'
if (Test-Path -LiteralPath $venvPython) { $taskPython = $venvPython }
elseif (Test-Path -LiteralPath $bundledPython) { $taskPython = $bundledPython }
else { $taskPython = (Get-Command python -ErrorAction Stop).Source }
Push-Location -LiteralPath $taskRoot
try {
    if ($Task -eq 'install') {
        & $taskPython -m pip install --target .devdeps -r requirements-dev.txt
    } elseif ($Task -eq 'build' -and $Luna) {
        & $taskPython tools/build.py --luna $Luna
    } else {
        $script = @{test='test.py';build='build.py';play='simulate.py';
                    gallery='gallery.py';benchmark='benchmark.py'}[$Task]
        & $taskPython (Join-Path 'tools' $script)
    }
    if ($LASTEXITCODE -ne 0) { throw "Bitling $Task failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
