\
    # PowerShell deploy_to_github.ps1
    # Run in PowerShell as Administrator or normal user:
    # .\deploy_to_github.ps1
    Param()
    Write-Host "== Deploy automatizado a GitHub - Club de Lectura =="
    if (-not (Test-Path -Path ".\index.html")) {
      Write-Host "ERROR: no se encontró index.html en la carpeta actual. Ejecuta este script desde la carpeta del proyecto." -ForegroundColor Red
      exit 1
    }
    if (-not (Test-Path -Path ".git")) {
      git init
      git add .
      git commit -m "Initial commit — PWA Club de Lectura"
      git branch -M main 2>$null
      Write-Host "Repositorio git inicializado y commit creado."
    } else {
      Write-Host "Repositorio git ya existe."
    }
    $repoName = Read-Host "Nombre del repo en GitHub (ej: club-de-lectura)"
    if ([string]::IsNullOrWhiteSpace($repoName)) {
      Write-Host "Nombre de repo vacio. Abortando." -ForegroundColor Red; exit 1
    }
    # Try gh CLI
    if (Get-Command gh -ErrorAction SilentlyContinue) {
      Write-Host "gh CLI encontrada."
      try {
        gh auth status -t | Out-Null
        $ghUser = gh api user --jq .login
        if (-not $ghUser) { $ghUser = Read-Host "Usuario GitHub (si lo quieres especificar)" }
        $vis = Read-Host "Visibilidad (public/private) [public]"
        if ($vis -eq "private") { $visibility = "private" } else { $visibility = "public" }
        gh repo create "$ghUser/$repoName" --$visibility --source=. --remote=origin --push
        Write-Host "Repo creado y push realizado."
        exit 0
      } catch {
        Write-Host "gh falla o no autenticado. Continuando con método PAT." -ForegroundColor Yellow
      }
    }

    $ghUser = Read-Host "Tu usuario de GitHub (ej: tu-usuario)"
    if ([string]::IsNullOrWhiteSpace($ghUser)) { Write-Host "Usuario no proporcionado. Abortando." -ForegroundColor Red; exit 1 }
    $pat = Read-Host "Introduce tu Personal Access Token (PAT) de GitHub (se usará temporalmente para push)" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pat)
    $unsecure = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $vis = Read-Host "Visibilidad del repo (public/private) [public]"
    if ($vis -eq "private") { $priv = $true } else { $priv = $false }
    $body = @{ name = $repoName; private = $priv } | ConvertTo-Json
    $authHeader = @{ Authorization = "token $unsecure" }
    Write-Host "Creando repo en GitHub via API..."
    $resp = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $authHeader -Method Post -Body $body -ErrorAction SilentlyContinue
    if ($resp -ne $null) {
      Write-Host "Repositorio creado."
    } else {
      Write-Host "Probablemente el repo ya existe o hubo un error. Revisa manualmente en GitHub." -ForegroundColor Yellow
    }
    $remoteUrl = "https://$ghUser:$unsecure@github.com/$ghUser/$repoName.git"
    git remote remove origin 2>$null
    git remote add origin $remoteUrl
    git push -u origin main
    Write-Host "Push completado. Abre: https://github.com/$ghUser/$repoName"
    # clear variables
    $unsecure = $null
