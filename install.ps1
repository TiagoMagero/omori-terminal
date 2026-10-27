#requires -Version 5.1
[CmdletBinding()]
param(
    [Alias('ArchivePath')] [string] $MotionArchivePath,
    [Alias('InstallRoot')] [string] $MotionInstallRoot = (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'OmoriMotionTerminal'),
    [Alias('DocumentsDirectory')] [string] $MotionDocumentsDirectory = [Environment]::GetFolderPath('MyDocuments')
)
& {
param($ArchivePath, $InstallRoot, $DocumentsDirectory)
$ErrorActionPreference = 'Stop'
$motionExpectedHash = 'c269dcda32c3fd97e92fcfb4f0a62a683f87db0b6bba79cebdc2c824b5fb6d2f'
$motionPackageUrl = 'https://raw.githubusercontent.com/TiagoMagero/omori-terminal/main/Omori-Motion-Terminal.zip'
$motionVersionRoot = Join-Path $InstallRoot ('packages\' + $motionExpectedHash.Substring(0, 16))
$motionPackageRoot = Join-Path $motionVersionRoot 'motion-portable'
$motionRenderer = Join-Path $motionPackageRoot 'motion.ps1'
if (-not (Test-Path -LiteralPath $motionRenderer -PathType Leaf)) {
    [void][IO.Directory]::CreateDirectory($InstallRoot)
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path $InstallRoot ('banner-' + [Guid]::NewGuid().ToString('N') + '.zip')
        $motionOriginalTls = [Net.ServicePointManager]::SecurityProtocol
        try {
            [Net.ServicePointManager]::SecurityProtocol = $motionOriginalTls -bor [Net.SecurityProtocolType]::Tls12
            Write-Host 'Baixando o banner Omori Motion...'
            Invoke-WebRequest -UseBasicParsing -Uri $motionPackageUrl -OutFile $ArchivePath
        } finally {
            [Net.ServicePointManager]::SecurityProtocol = $motionOriginalTls
        }
    }
    $motionHasher = [Security.Cryptography.SHA256]::Create()
    $motionArchiveStream = [IO.File]::OpenRead($ArchivePath)
    try {
        $motionActualHash = [BitConverter]::ToString($motionHasher.ComputeHash($motionArchiveStream)).Replace('-', '')
    } finally {
        $motionArchiveStream.Dispose()
        $motionHasher.Dispose()
    }
    if ($motionActualHash -ne $motionExpectedHash) { throw 'O pacote nao corresponde ao SHA-256 esperado. Instalacao interrompida.' }
    if (Test-Path -LiteralPath $motionVersionRoot) { throw 'A pasta desta versao ja existe mas esta incompleta; os arquivos foram preservados.' }
    [void][IO.Directory]::CreateDirectory($motionVersionRoot)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($ArchivePath, $motionVersionRoot)
}
$motionConfigure = Join-Path $motionPackageRoot 'instalar-windows.ps1'
if (-not (Test-Path -LiteralPath $motionConfigure -PathType Leaf)) { throw 'Instalador de perfil ausente no pacote.' }
& $motionConfigure -DocumentsDirectory $DocumentsDirectory
if (-not [Console]::IsOutputRedirected) { & $motionRenderer -Animate }
} $MotionArchivePath $MotionInstallRoot $MotionDocumentsDirectory
