package io.antono2.imgui;

import android.content.Context;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.text.InputType;

/** A focusable, transparent text bridge for a host Activity's ImGui surface. */
public final class ImGuiInputView extends View {
    static {
        System.loadLibrary("vimgui");
    }

    private static native void nativeCommitText(String text);
    private static native void nativeKey(int key, boolean down);

    public ImGuiInputView(Context context) {
        super(context);
        setFocusable(true);
        setFocusableInTouchMode(true);
    }

    @Override
    public boolean onCheckIsTextEditor() {
        return true;
    }

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        outAttrs.inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE;
        outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_EXTRACT_UI;
        return new BaseInputConnection(this, false) {
            @Override
            public boolean commitText(CharSequence text, int newCursorPosition) {
                if (text != null && text.length() > 0) {
                    nativeCommitText(text.toString());
                }
                return true;
            }

            @Override
            public boolean deleteSurroundingText(int beforeLength, int afterLength) {
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
            public boolean sendKeyEvent(KeyEvent event) {
                int key;
                switch (event.getKeyCode()) {
                    case KeyEvent.KEYCODE_DEL: key = 1; break;
                    case KeyEvent.KEYCODE_ENTER: key = 2; break;
                    case KeyEvent.KEYCODE_TAB: key = 3; break;
                    case KeyEvent.KEYCODE_FORWARD_DEL: key = 4; break;
                    default: return super.sendKeyEvent(event);
                }
                nativeKey(key, event.getAction() == KeyEvent.ACTION_DOWN);
                return true;
            }
        };
    }

    /** Call on the UI thread when ImGuiIO.WantTextInput changes. */
    public void setKeyboardVisible(boolean visible) {
        InputMethodManager imm = (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        if (visible) {
            requestFocus();
            imm.showSoftInput(this, InputMethodManager.SHOW_IMPLICIT);
        } else {
            imm.hideSoftInputFromWindow(getWindowToken(), 0);
            clearFocus();
        }
    }
}
