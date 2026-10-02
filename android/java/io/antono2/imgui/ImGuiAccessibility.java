package io.antono2.imgui;

import android.os.Handler;
import android.os.Looper;
import android.view.Choreographer;
import android.view.View;
import android.view.accessibility.AccessibilityEvent;
import android.util.Log;

/** Owns the UI-thread accessibility adapter for an application-rendered View.
 * The native context is retained before crossing threads. close() must be
 * called by the Activity before destroying its host View. */
public final class ImGuiAccessibility implements AutoCloseable {
    private final View host;
    private final Handler main = new Handler(Looper.getMainLooper());
    private volatile boolean closed;
    private volatile boolean failed;
    private long context;
    private int originalImportance;
    private final Choreographer.FrameCallback update = new Choreographer.FrameCallback() {
        @Override public void doFrame(long frameTimeNanos) {
            if (!closed && context != 0) {
                nativeUpdate(context);
                Choreographer.getInstance().postFrameCallback(this);
            }
        }
    };

    public ImGuiAccessibility(View host) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            throw new IllegalStateException("Create ImGuiAccessibility on the UI thread");
        }
        this.host = host;
    }

    /** May be called from the renderer while it owns a reference to address.
     * Passing zero detaches; nonzero must already contain a committed tree. */
    public void setContext(long address) {
        if (closed) return;
        if (address != 0) nativeRetain(address);
        if (!main.post(() -> replaceContext(address)) && address != 0) nativeRelease(address);
    }

    private void replaceContext(long address) {
        if (closed) {
            if (address != 0) nativeRelease(address);
            return;
        }
        if (context == address) {
            if (address != 0) nativeRelease(address);
            return;
        }
        detach();
        if (address == 0) return;
        if (!nativeAttach(address, host)) {
            nativeRelease(address);
            failed = true;
            Log.e("ImGuiAccessibility", "Could not attach native accessibility adapter");
            return;
        }
        failed = false;
        context = address;
        originalImportance = host.getImportantForAccessibility();
        host.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_YES);
        // AccessKit posts delegate installation. Invalidate any real-view tree
        // cached by a service before the native provider became available.
        host.post(() -> {
            if (!closed && context == address) {
                host.sendAccessibilityEvent(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
            }
        });
        Choreographer.getInstance().postFrameCallback(update);
    }

    private void detach() {
        Choreographer.getInstance().removeFrameCallback(update);
        if (context != 0) {
            nativeDetach(context);
            nativeRelease(context);
            context = 0;
            host.setImportantForAccessibility(originalImportance);
        }
    }

    @Override public void close() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            throw new IllegalStateException("Close ImGuiAccessibility on the UI thread");
        }
        closed = true;
        detach();
    }

    /** The host should report an attachment failure and offer a retry. */
    public boolean hasFailed() { return failed; }

    private static native void nativeRetain(long context);
    private static native void nativeRelease(long context);
    private static native boolean nativeAttach(long context, View host);
    private static native void nativeDetach(long context);
    private static native void nativeUpdate(long context);
}
