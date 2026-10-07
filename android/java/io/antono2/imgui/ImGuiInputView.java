// Bridges Android input-method, clipboard and input events to the native ImGui host.
package io.antono2.imgui;

import android.content.Context;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.text.Editable;
import android.text.InputType;
import android.text.Selection;
import android.text.SpannableStringBuilder;

/** A focusable, transparent text bridge for a host Activity's ImGui surface. */
public final class ImGuiInputView extends View {
    static {
        System.loadLibrary("vimgui");
    }

    /** Base-font pixels per sp, including system text sizing; no settings are changed. */
    public static native float nativeUiScale(Context context);
    /** Notify the rendering backend when an input device disconnects. */
    public static native void notifyGamepadDisconnected(int deviceId);
    private static native void nativeCommitText(String text);
    private static native void nativeKey(int key, boolean down);
    private static native void nativeSetEditingState(String text, int start, int end, int serial, int generation);
    private static native TextState nativeGetEditingState();
    private static native int nativeGetEditingRevision();
    private static native void nativeDiscardPendingEdits();

    private static final class TextState {
        final String text;
        final int start;
        final int end;
        final int serial;
        final int generation;

        private TextState(String text, int start, int end, int serial, int generation) {
            this.text = text;
            this.start = start;
            this.end = end;
            this.serial = serial;
            this.generation = generation;
        }
    }

    private final Editable editable = new SpannableStringBuilder();
    private int sentSerial;
    private int generation;
    private int seenRevision;
    private volatile boolean stateful;
    private boolean keyboardVisible;
    private int batchDepth;
    private final Runnable syncWhileVisible = new Runnable() {
        @Override public void run() {
            synchronized (ImGuiInputView.this) {
                if (!keyboardVisible) return;
                syncFromNative();
            }
            postOnAnimation(this);
        }
    };

    public ImGuiInputView(Context context) {
        super(context);
        setFocusable(true);
        setFocusableInTouchMode(true);
    }

    @Override
    public boolean onCheckIsTextEditor() {
        return true;
    }

    private void syncFromNative() {
        if (batchDepth != 0) return;
        int revision = nativeGetEditingRevision();
        if (revision == seenRevision) return;
        TextState snapshot = nativeGetEditingState();
        seenRevision = revision;
        if (snapshot == null) return;
        if (snapshot.generation != generation) {
            generation = snapshot.generation;
            sentSerial = 0;
        }
        if (snapshot.serial < sentSerial) return;
        stateful = true;
        if (!editable.toString().equals(snapshot.text)) {
            editable.replace(0, editable.length(), snapshot.text);
        }
        int start = Math.max(0, Math.min(snapshot.start, editable.length()));
        int end = Math.max(0, Math.min(snapshot.end, editable.length()));
        if (Selection.getSelectionStart(editable) != start ||
                Selection.getSelectionEnd(editable) != end) {
            Selection.setSelection(editable, start, end);
            InputMethodManager imm = (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.updateSelection(this, start, end, -1, -1);
        }
    }

    private void publishEditingState() {
        if (!stateful || batchDepth != 0) return;
        int start = Math.max(0, Selection.getSelectionStart(editable));
        int end = Math.max(0, Selection.getSelectionEnd(editable));
        nativeSetEditingState(editable.toString(), start, end, ++sentSerial, generation);
        InputMethodManager imm = (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.updateSelection(this, start, end, -1, -1);
    }

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        synchronized (this) { syncFromNative(); }
        outAttrs.inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE;
        outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_EXTRACT_UI;
        return new BaseInputConnection(this, true) {
            @Override
            public Editable getEditable() {
                return editable;
            }

            @Override
            public boolean commitText(CharSequence text, int newCursorPosition) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    if (stateful) {
                        boolean result = super.commitText(text, newCursorPosition);
                        publishEditingState();
                        return result;
                    }
                    if (text != null && text.length() > 0) nativeCommitText(text.toString());
                    return true;
                }
            }

            @Override
            public boolean deleteSurroundingText(int beforeLength, int afterLength) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    if (stateful) {
                        boolean result = super.deleteSurroundingText(beforeLength, afterLength);
                        publishEditingState();
                        return result;
                    }
                }
                for (int i = 0; i < beforeLength; i++) {
                    nativeKey(1, true);
                    nativeKey(1, false);
                }
                for (int i = 0; i < afterLength; i++) {
                    nativeKey(4, true);
                    nativeKey(4, false);
                }
                return true;
            }

            @Override
            public boolean deleteSurroundingTextInCodePoints(int beforeLength, int afterLength) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    if (stateful) {
                        boolean result = super.deleteSurroundingTextInCodePoints(beforeLength, afterLength);
                        publishEditingState();
                        return result;
                    }
                }
                return deleteSurroundingText(beforeLength, afterLength);
            }

            @Override
            public boolean setSelection(int start, int end) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    boolean result = super.setSelection(start, end);
                    publishEditingState();
                    return result;
                }
            }

            @Override
            public boolean setComposingText(CharSequence text, int newCursorPosition) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    boolean result = super.setComposingText(text, newCursorPosition);
                    publishEditingState();
                    return result;
                }
            }

            @Override
            public boolean finishComposingText() {
                synchronized (ImGuiInputView.this) {
                    boolean result = super.finishComposingText();
                    publishEditingState();
                    return result;
                }
            }

            @Override
            public CharSequence getTextBeforeCursor(int length, int flags) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    return super.getTextBeforeCursor(length, flags);
                }
            }

            @Override
            public CharSequence getTextAfterCursor(int length, int flags) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    return super.getTextAfterCursor(length, flags);
                }
            }

            @Override
            public CharSequence getSelectedText(int flags) {
                synchronized (ImGuiInputView.this) {
                    syncFromNative();
                    return super.getSelectedText(flags);
                }
            }

            @Override
            public boolean beginBatchEdit() {
                synchronized (ImGuiInputView.this) { batchDepth++; }
                return true;
            }

            @Override
            public boolean endBatchEdit() {
                synchronized (ImGuiInputView.this) {
                    if (batchDepth > 0) batchDepth--;
                    publishEditingState();
                }
                return true;
            }

            @Override
            public boolean sendKeyEvent(KeyEvent event) {
                // Numeric IMEs may send digit keys instead of commitText.
                // Forwarding them to the native key queue does not insert text.
                // Use the same editing/selection protocol as committed text,
                // and consume the release so each press inserts exactly once.
                int code = event.getKeyCode();
                int digit = code >= KeyEvent.KEYCODE_0 && code <= KeyEvent.KEYCODE_9
                        ? code - KeyEvent.KEYCODE_0
                        : code >= KeyEvent.KEYCODE_NUMPAD_0 && code <= KeyEvent.KEYCODE_NUMPAD_9
                        ? code - KeyEvent.KEYCODE_NUMPAD_0 : -1;
                if (digit >= 0 && !event.isCtrlPressed() && !event.isAltPressed()
                        && !event.isMetaPressed() && !event.isShiftPressed()) {
                    if (event.getAction() == KeyEvent.ACTION_DOWN)
                        return commitText(Integer.toString(digit), 1);
                    if (event.getAction() == KeyEvent.ACTION_UP) return true;
                }
                int key;
                switch (event.getKeyCode()) {
                    case KeyEvent.KEYCODE_DEL: key = 1; break;
                    case KeyEvent.KEYCODE_ENTER: key = 2; break;
                    case KeyEvent.KEYCODE_TAB: key = 3; break;
                    case KeyEvent.KEYCODE_FORWARD_DEL: key = 4; break;
                    default: return super.sendKeyEvent(event);
                }
                if (stateful && event.getAction() == KeyEvent.ACTION_DOWN &&
                        (key == 1 || key == 4)) {
                    synchronized (ImGuiInputView.this) {
                        syncFromNative();
                        int start = Selection.getSelectionStart(editable);
                        int end = Selection.getSelectionEnd(editable);
                        if (start != end && start >= 0 && end >= 0) {
                            int from = Math.min(start, end);
                            editable.delete(from, Math.max(start, end));
                            Selection.setSelection(editable, from);
                            publishEditingState();
                        } else {
                            deleteSurroundingTextInCodePoints(key == 1 ? 1 : 0, key == 4 ? 1 : 0);
                        }
                    }
                    return true;
                }
                if (stateful && event.getAction() == KeyEvent.ACTION_UP && (key == 1 || key == 4)) return true;
                nativeKey(key, event.getAction() == KeyEvent.ACTION_DOWN);
                return true;
            }
        };
    }

    /** Call on the UI thread when ImGuiIO.WantTextInput changes. */
    public void setKeyboardVisible(boolean visible) {
        InputMethodManager imm = (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        if (visible) {
            synchronized (this) {
                syncFromNative();
                if (!keyboardVisible) {
                    keyboardVisible = true;
                    postOnAnimation(syncWhileVisible);
                }
            }
            requestFocus();
            imm.showSoftInput(this, InputMethodManager.SHOW_IMPLICIT);
        } else {
            synchronized (this) {
                keyboardVisible = false;
                removeCallbacks(syncWhileVisible);
                stateful = false;
                sentSerial = 0;
                batchDepth = 0;
                nativeDiscardPendingEdits();
            }
            imm.hideSoftInputFromWindow(getWindowToken(), 0);
            clearFocus();
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        synchronized (this) {
            keyboardVisible = false;
            removeCallbacks(syncWhileVisible);
            stateful = false;
            sentSerial = 0;
            seenRevision = 0;
            batchDepth = 0;
        }
        super.onDetachedFromWindow();
    }
}
