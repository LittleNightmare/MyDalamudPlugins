$pluginsOut = @()

$pluginList = Get-Content '.\plugins.json' | ConvertFrom-Json

foreach ($plugin in $pluginList) {
  # Get values from the object
  $username = $plugin.username
  $repo = $plugin.repo
  $branch = $plugin.branch
  $configFolder = $plugin.configFolder

  # Fetch the release data from the Gibhub API
  $data = Invoke-WebRequest -Uri "https://api.github.com/repos/$($username)/$($repo)/releases/latest"
  $json = ConvertFrom-Json $data.content

  # Get data from the api request.
  $count = $json.assets[0].download_count
  $download = $json.assets[0].browser_download_url
  # Get timestamp for the release.
  $time = [Int](New-TimeSpan -Start (Get-Date "01/01/1970") -End ([DateTime]$json.published_at)).TotalSeconds

  # Get the config data from the repo.
  $url = "https://raw.githubusercontent.com/$($username)/$($repo)/$($branch)/$($configFolder)/$($repo).json"
  $configData = Invoke-WebRequest -ContentType "application/json; charset=utf-8" $url
  $config = ConvertFrom-Json $configData.Content

  # Ensure that config is converted properly.
  if ($null -eq $config) {
    Write-Error "Config for plugin $($plugin) is null!"
    ExitWithCode(1)
  }

  # Add additional properties to the config.
  $config | Add-Member -Name "IsHide" -MemberType NoteProperty -Value "False"
  $config | Add-Member -Name "IsTestingExclusive" -MemberType NoteProperty -Value "False"
  $config | Add-Member -Name "LastUpdated" -MemberType NoteProperty -Value $time
  $config | Add-Member -Name "DownloadCount" -MemberType NoteProperty -Value $count
  $config | Add-Member -Name "DownloadLinkInstall" -MemberType NoteProperty -Value $download
  $config | Add-Member -Name "DownloadLinkTesting" -MemberType NoteProperty -Value $download
  $config | Add-Member -Name "DownloadLinkUpdate" -MemberType NoteProperty -Value $download
  # $config | Add-Member -Name "IconUrl" -MemberType NoteProperty -Value "https://raw.githubusercontent.com/$($username)/$($repo)/$($branch)/icon.png"

  # Add to the plugin array.
  $pluginsOut += $config
}

# Convert plugins to JSON and Save repo to file
$pluginsOut | ConvertTo-Json | Out-File "repo.json"

# Function to exit with a specific code.
function ExitWithCode($code) {
  $host.SetShouldExit($code)
  exit $code
}
