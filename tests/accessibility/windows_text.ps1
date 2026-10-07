# Builds and runs Windows UI Automation text-provider checks.
param([Parameter(Mandatory)] [string] $Executable, [switch] $SystemControl, [switch] $LegacySelection)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class TextTestWindow {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr FindWindow(string className, string title);
}
'@
$ProviderArgument = if ($SystemControl) { '--system-control' } else { '--provider' }
$Process = Start-Process -FilePath $Executable -ArgumentList $ProviderArgument -PassThru
try {
    $Deadline = [DateTime]::UtcNow.AddSeconds(10)
    do { $Process.Refresh(); if ($Process.HasExited) { throw 'Provider exited' }; $Handle = [TextTestWindow]::FindWindow('VImGuiTextTest', "Native text regression $($Process.Id)"); if ($Handle -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 50 } } while ($Handle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $Deadline)
    if ($Handle -eq [IntPtr]::Zero) { throw 'No provider window' }
    $Root = [System.Windows.Automation.AutomationElement]::FromHandle($Handle)
    $Condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, 'Name')
    if ($SystemControl) { $Condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::IsTextPatternAvailableProperty, $true) }
    do { $Field = $Root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $Condition); if (-not $Field) { Start-Sleep -Milliseconds 50 } } while (-not $Field -and [DateTime]::UtcNow -lt $Deadline)
    if (-not $Field) { throw 'No text provider field' }
    $Text = $Field.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
    $Camera = [string][char]0xd83d + [char]0xdcf7
    $Expected = 'A' + $Camera + 'e' + [char]0x0301 + 'Z'
    $DocumentText = $Text.DocumentRange.GetText(-1).TrimEnd([char[]] "`r`n")
    if ($DocumentText -ne $Expected) { throw "Document text mismatch (length $($DocumentText.Length))" }
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
    # The native client regression covers selected-range reads. Opt in to this
    # legacy-wrapper diagnostic, which also crashes against system RichEdit on
    # affected Windows versions: https://github.com/microsoft/Microsoft-UI-UIAutomation/issues/100
    if (-not $LegacySelection) { return }
    for ($Attempt = 0; $Attempt -lt 50; $Attempt++) {
        $Selection = $Text.GetSelection()
        if ($Selection.Count -ne 1 -or $Selection[0].GetText(-1) -ne $Camera) { throw 'Selected text mismatch' }
    }
    Write-Output "PASS: managed selection range GetText ($([Threading.Thread]::CurrentThread.GetApartmentState()))"
} finally { if (-not $Process.HasExited) { Stop-Process -Id $Process.Id -Force } }
