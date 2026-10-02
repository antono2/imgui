package io.antono2.vimgui.demo;

import android.app.NativeActivity;
import android.content.Context;
import android.hardware.input.InputManager;
import android.os.Bundle;
import android.widget.FrameLayout;
import io.antono2.imgui.ImGuiInputView;
import io.antono2.imgui.ImGuiAccessibility;

/** NativeActivity host that supplies the focusable IME view missing upstream. */
public final class ImGuiActivity extends NativeActivity implements InputManager.InputDeviceListener {
    private ImGuiInputView inputView;
    private InputManager inputManager;
    private volatile ImGuiAccessibility accessibility;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        FrameLayout content = findViewById(android.R.id.content);
        accessibility = new ImGuiAccessibility(content);
        inputView = new ImGuiInputView(this);
        inputView.setAlpha(0.0f);
        content.addView(inputView, new FrameLayout.LayoutParams(1, 1));
        inputManager = (InputManager) getSystemService(Context.INPUT_SERVICE);
        if (inputManager != null) {
            inputManager.registerInputDeviceListener(this, null);
        }
    }

    @Override public void onInputDeviceAdded(int deviceId) {}
    @Override public void onInputDeviceChanged(int deviceId) {}
    @Override public void onInputDeviceRemoved(int deviceId) {
        ImGuiInputView.notifyGamepadDisconnected(deviceId);
    }

    @Override protected void onDestroy() {
        if (accessibility != null) accessibility.close();
        if (inputManager != null) {
            inputManager.unregisterInputDeviceListener(this);
        }
        super.onDestroy();
    }

    public void setImGuiAccessibilityContext(long context) {
        ImGuiAccessibility current = accessibility;
        if (current != null) current.setContext(context);
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
