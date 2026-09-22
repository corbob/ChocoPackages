function Invoke-GitHubApi {
    param(
        [Parameter(Mandatory)]
        [string]$Uri
    )

    $headers = @{
        Accept                 = 'application/vnd.github+json'
        'User-Agent'           = 'ChocoPackages-Updater'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $headers.Authorization = 'Bearer ' + $env:GITHUB_TOKEN
    }

    Invoke-RestMethod -Uri $Uri -Headers $headers
}
