#!/usr/bin/env python3
"""Run inside a private D-Bus session/Xvfb, never against the user's desktop.

dbus-run-session -- xvfb-run -a /usr/bin/python3 tests/accessibility/atspi_smoke.py build/accessible-review
"""
import os
import subprocess
import sys
import time
import gi

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi, Gio, GLib


def wait_for(probe, message, seconds=30):
    deadline = time.monotonic() + seconds
    last = None
    while time.monotonic() < deadline:
        context = GLib.MainContext.default()
        for _ in range(100):
            if not context.pending(): break
            context.iteration(False)
        try:
            result = probe()
            if result:
                return result
        except GLib.Error as error:
            last = error
        time.sleep(0.1)
    raise AssertionError(f"{message}: {last}")


def children(node):
    node.clear_cache()
    return [node.get_child_at_index(i) for i in range(node.get_child_count())]


def named(node, name):
    return next((child for child in children(node) if child and child.get_name() == name), None)


bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
for key in ("IsEnabled", "ScreenReaderEnabled"):
    bus.call_sync("org.a11y.Bus", "/org/a11y/bus", "org.freedesktop.DBus.Properties", "Set",
                  GLib.Variant("(ssv)", ("org.a11y.Status", key, GLib.Variant("b", True))),
                  None, Gio.DBusCallFlags.NONE, 5000, None)

environment = dict(os.environ)
environment["VK_ICD_FILENAMES"] = "/usr/share/vulkan/icd.d/lvp_icd.json"
process = subprocess.Popen([sys.argv[1]], env=environment, stdout=subprocess.DEVNULL,
                           stderr=subprocess.PIPE, text=True)
try:
    desktop = Atspi.get_desktop(0)
    def find_app():
        apps = children(desktop)
        return next((a for a in apps if a and a.get_process_id() == process.pid), None)
    app = wait_for(find_app, "Application did not register")
    app.set_cache_mask(Atspi.Cache.NONE)
    window = wait_for(lambda: app.get_child_at_index(0) if app.get_child_count() else None, "No accessible window")
    files = wait_for(lambda: named(window, "Files"), "No accessible file list")
    assert 0 < files.get_child_count() < 100000, files.get_child_count()
    # The retained tree has 100,000 rows. Native adapters expose the viewport
    # and neighboring rows, with scroll actions and total/position metadata.
    jump = named(window, "Focus last file")
    assert jump.get_action_iface().do_action(0)
    last = wait_for(lambda: next((row for row in children(files) if row and "Photo 099999.jpg" in row.get_name()), None), "Jumping to the final retained row failed")
    assert "Photo 099999.jpg" in last.get_name(), last.get_name()
    action = last.get_action_iface()
    assert action is not None, "Off-screen row has no action interface"
    assert action.do_action(0), "Off-screen row action failed"
    wait_for(lambda: last.get_state_set().contains(Atspi.StateType.SELECTED), "Off-screen row was not selected")
    assert last.get_component_iface().grab_focus(), "Off-screen focus request failed"
    def last_is_visible():
        row = last.get_component_iface().get_extents(Atspi.CoordType.SCREEN)
        bounds = files.get_component_iface().get_extents(Atspi.CoordType.SCREEN)
        return row.height > 0 and row.y >= bounds.y and row.y + row.height <= bounds.y + bounds.height
    wait_for(last_is_visible, "Focused row geometry did not move into the list viewport")
    keep = named(window, "Keep selected")
    assert keep.get_action_iface().do_action(0)
    wait_for(lambda: named(window, "Keeper saved: Photo 099999.jpg"), "Selected off-screen row did not reach the application")
    search = named(window, "Search files")
    assert search.get_editable_text_iface().set_text_contents("099999")
    wait_for(lambda: files.get_child_count() == 1, "Accessible search did not filter the list")
    assert "099999" in files.get_child_at_index(0).get_name()
    print("AT-SPI: 100,000 retained rows, virtualized navigation, scrolled geometry, keeper action, and editable search passed.")
finally:
    process.terminate()
    try:
        _, errors = process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        _, errors = process.communicate()
    if errors:
        print(errors, file=sys.stderr)
