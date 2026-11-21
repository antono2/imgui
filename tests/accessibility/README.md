# Accessibility checks

## Linux application host

Run the same build and checks as the Linux workflow with V, TinyCC, Xvfb,
D-Bus, and Mesa Lavapipe installed.

```sh
v run scripts/build_appui.vsh
v run scripts/check_appui.vsh startup build/appui/startup-check
v run scripts/check_appui.vsh render
```

The startup check saves its probe binaries and logs in the directory you
provide. The render check exercises the application host under software Vulkan
in an isolated X11 and D-Bus session.

## Windows text checks

`accessibility_windows_text_test` reads document and selected ranges through
the native `IUIAutomation` client in a separate process. It repeats selected
Unicode range reads 50 times, with and without COM initialization in the provider.
The managed MTA and STA checks also exercise document cloning, endpoint movement,
text retrieval and selection actions.

The legacy .NET `TextPattern.GetSelection()[0].GetText()` path crashes in
`UIAutomationCore` on the Windows Server 2022 runner. The same diagnostic crashes
against Windows' built-in RichEdit control after its document, cloned and moved
ranges pass. This matches [Microsoft's tracked issue](https://github.com/microsoft/Microsoft-UI-UIAutomation/issues/100).
Selected-text release checks therefore use the native client API.

To reproduce the legacy wrapper problem outside the normal checks:

```powershell
powershell.exe -Mta -NoProfile -File tests/accessibility/windows_text.ps1 -Executable build/accessibility/Release/accessibility_windows_text_test.exe -LegacySelection
powershell.exe -Mta -NoProfile -File tests/accessibility/windows_text.ps1 -Executable build/accessibility/Release/accessibility_windows_text_test.exe -SystemControl -LegacySelection
```
