# https://github.com/andshrew/PlayStation-Entitlements
# Version: {{GIT_TAG_NAME}}/{{GIT_COMMIT_REF}}
#
# MIT License
# 2025 GPT4.1, andshrew

$datetime = Get-Date -Format "yyyy-MM-dd-HHmmss"
if ([Environment]::OSVersion.Platform -eq "Win32NT") {
  $defaultSavePath = Join-Path $env:USERPROFILE "psn-entitlements-$datetime.json"
}
else {
  $defaultSavePath = Join-Path $env:HOME "psn-entitlements-$datetime.json"
}

Write-Host "PlayStation Network Entitlements Downloader"
Write-Host "https://github.com/andshrew/PlayStation-Entitlements"
Write-Host "Version: {{GIT_TAG_NAME}}/{{GIT_COMMIT_REF}}"
Write-Host "OS: $([Environment]::OSVersion)"
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Host ""

Write-Host "Get your npsso token from https://ca.account.sony.com/api/v1/ssocookie"
Write-Host "Enter your npsso token (input hidden): " -NoNewline
# 5.1 does not support MaskInput on Read-Host
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $npsso = Read-Host -MaskInput
}
else {
  $secret = ""
  while ($true) {
      $key = [System.Console]::ReadKey($true)
      if ($key.Key -eq "Enter") { break }
      $secret += $key.KeyChar
  }
  $npsso = $secret
}
Write-Host ""

Write-Host "Enter the file path to save the entitlements JSON [default: $defaultSavePath]:"
$savePath = Read-Host
if ([string]::IsNullOrEmpty($savePath)) {
    $savePath = $defaultSavePath
}
else {
  $invalidPath = $false
  if (-not (Test-Path $savePath -IsValid)) { $invalidPath = $true }
  if ($savePath[-1] -eq [IO.Path]::DirectorySeparatorChar) {$invalidPath = $true}
  $parentPath = Split-Path $savePath -Parent
  if (-not ([string]::IsNullOrEmpty($parentPath))) {
    if (-not (Test-Path -path $parentPath -Type Container)) {
      Write-Host "Folder does not exist"
      $invalidPath = $true
    }
  }
  if ($invalidPath) {
    Write-Host "Entered value is not a valid file path."
    exit 1
  }
}

if (Test-Path $savePath) {
  Write-Host "File path already exists, Y to overwrite [default N]: " -NoNewline
  if ("Y" -ne (Read-Host).ToUpper()) {
    exit 1
  }
}

$auth_url    = "https://ca.account.sony.com/api/authz/v3/oauth/token"
$auth_header = "Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A="
$auth_body   = "token_format=jwt&grant_type=sso_token&npsso=$npsso&scope=psn:mobile.v2.core psn:clientapp"

Write-Host "Authenticating..."

try {
    $auth_response = Invoke-RestMethod -Method Post -Uri $auth_url `
        -Headers @{ "Authorization" = $auth_header } `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $auth_body
} catch {
    Write-Host "Error: Unable to obtain access token."
    Write-Host $_.Exception.Message
    exit 1
}

$access_token = $auth_response.access_token

if ([string]::IsNullOrEmpty($access_token)) {
    Write-Host "Error: Unable to obtain access token."
    Write-Host ($auth_response | ConvertTo-Json -Depth 5)
    exit 1
}

Write-Host "Authentication successful."

$limit = 500
$offset = 0
$page = 0
$fields = "fields=titleMeta,gameMeta,conceptMeta,rewardMeta,rewardMeta.retentionPolicy,drmdef,drmdef.contentType,skuMeta,productMeta,cloudMeta,metarev,entitlementAttributes"
$api_url_base = "https://m.np.playstation.com/api/entitlement/v2/users/me/internal/entitlements"

# Temp storage
$entitlementsList = @()
$meta = $null

Write-Host "Fetching entitlements (paging if required)..."

do {
    $query = "$api_url_base`?$fields&limit=$limit&offset=$offset"
    try {
      if ($PSVersionTable.PSVersion.Major -eq 5) {
        # Windows PowerShell has encoding issues...
        # Credit: https://www.reddit.com/r/PowerShell/comments/qzr74x/wrong_encoding_as_a_result_of_a_rest_call/kutec09/
        $api_response = [Text.Encoding]::UTF8.GetString((Invoke-WebRequest $query -Method 'GET' -Headers @{ "Authorization" = "Bearer $access_token" }).RawContentStream.ToArray())
        $api_response = $api_response | ConvertFrom-Json
      }
      else {
        $api_response = Invoke-RestMethod -Method Get -Uri $query -Headers @{ "Authorization" = "Bearer $access_token" }
      }
    } catch {
        Write-Host "Error fetching entitlements:"
        Write-Host $_.Exception.Message
        exit 1
    }

    if ($page -eq 0) {
        $meta = @{
            revisionId    = $api_response.revisionId
            metaRevisionId= $api_response.metaRevisionId
            start         = $api_response.start
            totalResults  = $api_response.totalResults
        }
    }

    if ($api_response.entitlements) {
        $entitlementsList += $api_response.entitlements
    }

    $total_results = $api_response.totalResults
    $offset += $limit
    $page += 1
} while ($offset -lt $total_results)

# Build final output object
$output = $meta
$output.entitlements = $entitlementsList

# Save output as formatted JSON
$output | ConvertTo-Json -Depth 100 | Out-File -Encoding UTF8 $savePath

Write-Host "All entitlements saved to: $savePath"