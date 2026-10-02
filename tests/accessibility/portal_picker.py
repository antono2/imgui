#!/usr/bin/env python3
"""Exercise the real NFD portal client against a private, controlled portal.

Run with dbus-run-session; this does not open or operate the user's chooser.
"""
import ctypes
from pathlib import Path
import sys
import tempfile
import threading
from gi.repository import Gio, GLib

xml = '''<node><interface name="org.freedesktop.portal.FileChooser">
<method name="OpenFile"><arg type="s" direction="in"/><arg type="s" direction="in"/>
<arg type="a{sv}" direction="in"/><arg type="o" direction="out"/></method>
<property name="version" type="u" access="read"/>
</interface></node>'''
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
bus.call_sync('org.freedesktop.DBus', '/org/freedesktop/DBus',
              'org.freedesktop.DBus', 'RequestName',
              GLib.Variant('(su)', ('org.freedesktop.portal.Desktop', 0)),
              GLib.VariantType('(u)'), Gio.DBusCallFlags.NONE, 5000, None)
responses = [0, 1, 2]
requests = []
with tempfile.TemporaryDirectory(prefix='imgui-picker-') as directory:
    chosen = Path(directory) / 'photos café #1'
    chosen.mkdir()

    def method(connection, sender, path, interface, name, parameters, invocation):
        parent, title, options = parameters.unpack()
        requests.append(options)
        handle = '/org/freedesktop/portal/desktop/request/' + sender[1:].replace('.', '_') + '/' + options['handle_token']
        code = responses.pop(0)
        invocation.return_value(GLib.Variant('(o)', (handle,)))

        def respond():
            results = {'uris': GLib.Variant('as', [chosen.as_uri()])} if code == 0 else {}
            connection.emit_signal(sender, handle, 'org.freedesktop.portal.Request',
                                   'Response', GLib.Variant('(ua{sv})', (code, results)))
            return False
        GLib.timeout_add(25, respond)

    info = Gio.DBusNodeInfo.new_for_xml(xml)
    registration = bus.register_object('/org/freedesktop/portal/desktop', info.interfaces[0],
        method, lambda *args: GLib.Variant('u', 4), None)
    loop = GLib.MainLoop()
    worker = threading.Thread(target=loop.run, daemon=True)
    worker.start()
    try:
        library = ctypes.CDLL(sys.argv[1])
        pick = library.vimgui_app_pick_folder
        pick.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p)]
        pick.restype = ctypes.c_char_p
        error = ctypes.c_char_p()
        result = pick(directory.encode(), ctypes.byref(error))
        assert result.decode() == str(chosen), (result, error.value)
        assert error.value is None
        assert pick(directory.encode(), ctypes.byref(error)) is None
        assert error.value is None, 'Cancellation must not be reported as failure'
        assert pick(directory.encode(), ctypes.byref(error)) is None
        assert error.value, 'Portal failure must be reported'
        assert len(requests) == 3 and all(r.get('directory') for r in requests)
        assert bytes(requests[0]['current_folder']).rstrip(b'\0').decode() == directory
        print('Portal picker: UTF-8 folder selection, initial folder, cancellation, and errors passed.')
    finally:
        loop.quit()
        worker.join(timeout=5)
        bus.unregister_object(registration)
