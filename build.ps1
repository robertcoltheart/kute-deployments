#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Install-LatestTool {
    param (
        $repo
    )

    $url = "https://api.github.com/repos/$repo/releases/latest"
    $releases = Invoke-RestMethod -Uri $url

    $release = $releases | Where-Object { $_.name -Match ".*windows[_-]amd64.*tar.gz" }

    Write-Output "Downloading $($release.name)"

    Invoke-WebRequest $release.browser_download_url -OutFile ".tools\$($asset.name)"
}

function Install-Tool {
    param (
        $repo
    )

    $url = "https://api.github.com/repos/$repo/releases"
    $releases = Invoke-RestMethod -Uri $url

    $release = $releases | Where-Object { $_.name -Match ".*windows[_-]amd64.*tar.gz" }
}

function Install-YamlTools {
    New-Item -Path ".tools" -Force

    if (! (Test-Path ".tools/kustomize.exe")) {
        Install-Tool "kubernetes-sigs/kustomize"
    }

    if (! (Test-Path ".tools/kubeconform.exe")) {
        Install-LatestTool "yannh/kubeconform"
    }

    if (! (Test-Path ".tools/yq.exe")) {
        Install-LatestTool "mikefarah/yq"
    }
}

function Test-YamlSchema {
    
}

Push-Location (Split-Path $MyInvocation.MyCommand.Definition)

try {
    Install-YamlTools
}
finally {
    Pop-Location
}
