param([Parameter(Mandatory)] [string] $Executable, [switch] $SystemControl)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$ProviderArgument = if ($SystemControl) { '--system-control' } else { '--provider' }
$Process = Start-Process -FilePath $Executable -ArgumentList $ProviderArgument -PassThru
try {
    $Deadline = [DateTime]::UtcNow.AddSeconds(10)
    do { $Process.Refresh(); if ($Process.HasExited) { throw 'Provider exited' }; Start-Sleep -Milliseconds 50 } while ($Process.MainWindowHandle -eq 0 -and [DateTime]::UtcNow -lt $Deadline)
    if ($Process.MainWindowHandle -eq 0) { throw 'No provider window' }
    $Root = [System.Windows.Automation.AutomationElement]::FromHandle($Process.MainWindowHandle)
    $Condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, 'Name')
    if ($SystemControl) { $Condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::IsTextPatternAvailableProperty, $true) }
    do { $Field = $Root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $Condition); if (-not $Field) { Start-Sleep -Milliseconds 50 } } while (-not $Field -and [DateTime]::UtcNow -lt $Deadline)
    if (-not $Field) { throw 'No text provider field' }
    $Text = $Field.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
    $Camera = [string][char]0xd83d + [char]0xdcf7
    $Expected = 'A' + $Camera + 'e' + [char]0x0301 + 'Z'
    if ($Text.DocumentRange.GetText(-1).TrimEnd([char[]] "`r`n") -ne $Expected) { throw 'Document text mismatch' }
    Write-Output 'PASS: managed document range GetText'
    $Range = $Text.DocumentRange.Clone()
    if ($Range.GetText(-1).TrimEnd([char[]] "`r`n") -ne $Expected) { throw 'Cloned document text mismatch' }
    Write-Output 'PASS: managed cloned document GetText'
    $Range.MoveEndpointByRange([System.Windows.Automation.Text.TextPatternRangeEndpoint]::End, $Range, [System.Windows.Automation.Text.TextPatternRangeEndpoint]::Start)
    $null = $Range.MoveEndpointByUnit([System.Windows.Automation.Text.TextPatternRangeEndpoint]::Start, [System.Windows.Automation.Text.TextUnit]::Character, 1)
    $null = $Range.MoveEndpointByUnit([System.Windows.Automation.Text.TextPatternRangeEndpoint]::End, [System.Windows.Automation.Text.TextUnit]::Character, 1)
    if ($Range.GetText(-1) -ne $Camera) { throw 'Moved range text mismatch' }
    $Range.Select()
    Write-Output 'PASS: managed moved range GetText and Select'
    for ($Attempt = 0; $Attempt -lt 50; $Attempt++) {
        $Selection = $Text.GetSelection()
        if ($Selection.Count -ne 1 -or $Selection[0].GetText(-1) -ne $Camera) { throw 'Selected text mismatch' }
    }
    Write-Output "PASS: managed selection range GetText ($([Threading.Thread]::CurrentThread.GetApartmentState()))"
} finally { if (-not $Process.HasExited) { Stop-Process -Id $Process.Id -Force } }
