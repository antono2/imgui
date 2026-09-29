package io.antono2.vimgui.demo;

import android.app.NativeActivity;
import android.os.Bundle;
import android.widget.FrameLayout;
import io.antono2.imgui.ImGuiInputView;

/** NativeActivity host that supplies the focusable IME view missing upstream. */
public final class ImGuiActivity extends NativeActivity {
    private ImGuiInputView inputView;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        FrameLayout content = findViewById(android.R.id.content);
        inputView = new ImGuiInputView(this);
        inputView.setAlpha(0.0f);
        content.addView(inputView, new FrameLayout.LayoutParams(1, 1));
    }

    /** Called by the native render thread; UI work stays on the main thread. */
    public void setImGuiKeyboardVisible(final boolean visible) {
        runOnUiThread(() -> {
            if (inputView != null) {
                inputView.setKeyboardVisible(visible);
            }
        });
    }
}
