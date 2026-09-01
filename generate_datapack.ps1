param(
    [Parameter(Mandatory = $true)]
    [double]$StructureEssentialsMultiplier,

    [double]$VillageTargetMultiplier = 3.0,

    [string]$OutputDirectory = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($StructureEssentialsMultiplier -le 0) {
    throw "StructureEssentialsMultiplier must be greater than 0."
}

if ($VillageTargetMultiplier -le 0) {
    throw "VillageTargetMultiplier must be greater than 0."
}

function Invoke-JavaRound {
    param([double]$Value)
    return [int][Math]::Floor($Value + 0.5)
}

function Get-EffectiveValue {
    param(
        [int]$BaseValue,
        [double]$Multiplier,
        [int]$Minimum
    )

    $rounded = Invoke-JavaRound ($BaseValue * $Multiplier)
    return [Math]::Min(4095, [Math]::Max($Minimum, $rounded))
}

function Find-BestBaseValue {
    param(
        [int]$Target,
        [double]$Multiplier,
        [int]$MinimumBase,
        [int]$MinimumEffective
    )

    $bestBase = $MinimumBase
    $bestEffective = Get-EffectiveValue $bestBase $Multiplier $MinimumEffective
    $bestError = [Math]::Abs($bestEffective - $Target)
    $bestUnderTarget = if ($bestEffective -lt $Target) { 1 } else { 0 }

    for ($candidate = $MinimumBase; $candidate -le 4095; $candidate++) {
        $effective = Get-EffectiveValue $candidate $Multiplier $MinimumEffective
        $error = [Math]::Abs($effective - $Target)
        $underTarget = if ($effective -lt $Target) { 1 } else { 0 }

        $isBetter = ($error -lt $bestError) -or
            (($error -eq $bestError) -and ($underTarget -lt $bestUnderTarget))

        if ($isBetter) {
            $bestBase = $candidate
            $bestEffective = $effective
            $bestError = $error
            $bestUnderTarget = $underTarget
        }

        if (($bestError -eq 0) -and ($bestUnderTarget -eq 0)) {
            break
        }
    }

    return [PSCustomObject]@{
        Base = $bestBase
        Effective = $bestEffective
        Error = $bestError
    }
}

$targetSpacing = Invoke-JavaRound (34 * $VillageTargetMultiplier)
$targetSeparation = Invoke-JavaRound (8 * $VillageTargetMultiplier)

$spacingResult = Find-BestBaseValue $targetSpacing $StructureEssentialsMultiplier 1 1
$separationResult = Find-BestBaseValue $targetSeparation $StructureEssentialsMultiplier 0 0

if ($spacingResult.Base -le $separationResult.Base) {
    $adjustedSpacing = [Math]::Min(4095, $separationResult.Base + 1)
    $spacingResult = [PSCustomObject]@{
        Base = $adjustedSpacing
        Effective = Get-EffectiveValue $adjustedSpacing $StructureEssentialsMultiplier 1
        Error = [Math]::Abs((Get-EffectiveValue $adjustedSpacing $StructureEssentialsMultiplier 1) - $targetSpacing)
    }
}

$invariant = [Globalization.CultureInfo]::InvariantCulture
$seText = $StructureEssentialsMultiplier.ToString("0.####", $invariant)
$targetText = $VillageTargetMultiplier.ToString("0.####", $invariant)
$seToken = $seText.Replace(".", "_")
$targetToken = $targetText.Replace(".", "_")

$resolvedOutput = [IO.Path]::GetFullPath($OutputDirectory)
[IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null

$zipName = "village-distance-target-${targetToken}x-for-se-${seToken}-mc1.20.1.zip"
$zipPath = Join-Path $resolvedOutput $zipName
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("village-distance-" + [Guid]::NewGuid().ToString("N"))
$structureDirectory = Join-Path $tempRoot "data\minecraft\worldgen\structure_set"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

try {
    [IO.Directory]::CreateDirectory($structureDirectory) | Out-Null

    $packMeta = @"
{
  "pack": {
    "pack_format": 15,
    "description": "Village target ${targetText}x with Structure Essentials ${seText}x | MC 1.20.1"
  }
}
"@

    $villagesJson = @"
{
  "placement": {
    "type": "minecraft:random_spread",
    "salt": 10387312,
    "separation": $($separationResult.Base),
    "spacing": $($spacingResult.Base)
  },
  "structures": [
    {
      "structure": "minecraft:village_plains",
      "weight": 1
    },
    {
      "structure": "minecraft:village_desert",
      "weight": 1
    },
    {
      "structure": "minecraft:village_savanna",
      "weight": 1
    },
    {
      "structure": "minecraft:village_snowy",
      "weight": 1
    },
    {
      "structure": "minecraft:village_taiga",
      "weight": 1
    }
  ]
}
"@

    [IO.File]::WriteAllText((Join-Path $tempRoot "pack.mcmeta"), $packMeta, $utf8NoBom)
    [IO.File]::WriteAllText((Join-Path $structureDirectory "villages.json"), $villagesJson, $utf8NoBom)

    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Compress-Archive -Path (Join-Path $tempRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host "Created: $zipPath"
Write-Host "Datapack values: spacing=$($spacingResult.Base), separation=$($separationResult.Base)"
Write-Host "Effective after Structure Essentials: spacing=$($spacingResult.Effective), separation=$($separationResult.Effective)"
Write-Host "Target values: spacing=$targetSpacing, separation=$targetSeparation"
