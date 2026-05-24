$sshDir = "$env:USERPROFILE\.ssh"

if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
    Write-Host "Carpeta .ssh creada"
}

$cuentas = @(
    @{ archivo = "id_ed25519_pablo"; email = "priverar2@miumg.edu.gt" },
    @{ archivo = "id_ed25519_marly"; email = "mramireze9@miumg.edu.gt" },
    @{ archivo = "id_ed25519_diego"; email = "diegoandreguerragarza@gmail.com" },
    @{ archivo = "id_ed25519_jose";  email = "jguerrat1@miumg.edu.gt" }
)

foreach ($cuenta in $cuentas) {
    $ruta = "$sshDir\$($cuenta.archivo)"
    if (Test-Path $ruta) {
        Write-Host "Ya existe: $($cuenta.archivo) - se omite"
    } else {
        cmd /c "echo. | ssh-keygen -t ed25519 -C ""$($cuenta.email)"" -f ""$ruta"" -q"
        if (Test-Path $ruta) {
            Write-Host "OK - Llave creada: $($cuenta.archivo)"
        } else {
            Write-Host "ERROR - No se pudo crear: $($cuenta.archivo)"
        }
    }
}

$configPath = "$sshDir\config"
$configContent = "# === Cuenta de Pablo (Autor principal) ===`n"
$configContent += "Host github-pablo`n"
$configContent += "    HostName github.com`n"
$configContent += "    User git`n"
$configContent += "    IdentityFile ~/.ssh/id_ed25519_pablo`n"
$configContent += "    IdentitiesOnly yes`n`n"
$configContent += "# === Cuenta de Marly ===`n"
$configContent += "Host github-marly`n"
$configContent += "    HostName github.com`n"
$configContent += "    User git`n"
$configContent += "    IdentityFile ~/.ssh/id_ed25519_marly`n"
$configContent += "    IdentitiesOnly yes`n`n"
$configContent += "# === Cuenta de Diego ===`n"
$configContent += "Host github-diego`n"
$configContent += "    HostName github.com`n"
$configContent += "    User git`n"
$configContent += "    IdentityFile ~/.ssh/id_ed25519_diego`n"
$configContent += "    IdentitiesOnly yes`n`n"
$configContent += "# === Cuenta de Jose ===`n"
$configContent += "Host github-jose`n"
$configContent += "    HostName github.com`n"
$configContent += "    User git`n"
$configContent += "    IdentityFile ~/.ssh/id_ed25519_jose`n"
$configContent += "    IdentitiesOnly yes`n"

Set-Content -Path $configPath -Value $configContent -Encoding UTF8
Write-Host "Archivo config creado en: $configPath"

Write-Host ""
Write-Host "======================================================"
Write-Host " LLAVES PUBLICAS - Copia cada una en su cuenta GitHub"
Write-Host " Settings > SSH and GPG keys > New SSH key"
Write-Host "======================================================"

$archivos = @("id_ed25519_pablo","id_ed25519_marly","id_ed25519_diego","id_ed25519_jose")
$usuarios  = @("PabloRiveraM","MarlyRamirez","Apioide","8jose-gt")

for ($i = 0; $i -lt $archivos.Count; $i++) {
    $pubFile = "$sshDir\$($archivos[$i]).pub"
    if (Test-Path $pubFile) {
        Write-Host ""
        Write-Host "--- $($usuarios[$i]) ---"
        Get-Content $pubFile
    }
}

Write-Host ""
Write-Host "======================================================"
Write-Host "PRUEBA CADA CONEXION CON:"
Write-Host "  ssh -T git@github-pablo"
Write-Host "  ssh -T git@github-marly"
Write-Host "  ssh -T git@github-diego"
Write-Host "  ssh -T git@github-jose"
Write-Host "======================================================"
