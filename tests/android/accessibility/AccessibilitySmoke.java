package io.antono2.vimgui.accessible.test;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.Intent;
import android.graphics.Rect;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.View;
import android.view.MotionEvent;
import android.view.InputDevice;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import java.util.ArrayDeque;
import java.util.function.Supplier;
import java.util.concurrent.atomic.AtomicReference;

/** Exercises the native Android accessibility provider without changing the
 * user's configured accessibility services. Touch coordinates come from the app's list bounds. */
public final class AccessibilitySmoke extends Instrumentation {
    private UiAutomation automation;
    private String lastTree="";

    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); start(); }

    private <T> T await(Supplier<T> probe, String message) {
        long deadline=SystemClock.uptimeMillis()+30000;
        do {
            T value=probe.get();
            if (value!=null) return value;
            SystemClock.sleep(100);
        } while (SystemClock.uptimeMillis()<deadline);
        throw new AssertionError(message+"; "+lastTree);
    }

    private AccessibilityNodeInfo find(String label) {
        ArrayDeque<AccessibilityNodeInfo> queue=new ArrayDeque<>();
        StringBuilder trace=new StringBuilder();
        for (AccessibilityWindowInfo window:automation.getWindows()) {
            AccessibilityNodeInfo root=window.getRoot();
            trace.append("window=").append(window.getId()).append(" package=").append(root==null?"null":root.getPackageName()).append(';');
            if (root!=null && "io.antono2.vimgui.accessible".contentEquals(root.getPackageName()==null?"":root.getPackageName())) queue.add(root);
        }
        while (!queue.isEmpty()) {
            AccessibilityNodeInfo node=queue.removeFirst();
            if (trace.length()<4000) trace.append(node.getClassName()).append(':').append(node.getContentDescription()).append(':').append(node.getText()).append(" children=").append(node.getChildCount()).append(';');
            if (label.contentEquals(node.getContentDescription()==null?"":node.getContentDescription()) ||
                label.contentEquals(node.getText()==null?"":node.getText())) return node;
            for (int i=0;i<node.getChildCount();++i) {
                AccessibilityNodeInfo child=node.getChild(i);
                if (child!=null) queue.add(child);
            }
        }
        lastTree=trace.toString();
        return null;
    }

    private AccessibilityNodeInfo node(String label) { return await(() -> find(label),"Missing accessible control: "+label); }
    private void click(String label) {
        if (!node(label).performAction(AccessibilityNodeInfo.ACTION_CLICK)) throw new AssertionError("Click rejected: "+label);
    }
    private View inputView(View root) {
        if (root.getClass().getName().equals("io.antono2.imgui.ImGuiInputView")) return root;
        if (root instanceof ViewGroup) {
            ViewGroup group=(ViewGroup)root;
            for (int i=0;i<group.getChildCount();++i) {
                View result=inputView(group.getChildAt(i));
                if (result!=null) return result;
            }
        }
        return null;
    }

    private void drag(float x, float from, float to) {
        long down=SystemClock.uptimeMillis();
        for (int i=0;i<=21;++i) {
            int action=i==0?MotionEvent.ACTION_DOWN:(i==21?MotionEvent.ACTION_UP:MotionEvent.ACTION_MOVE);
            float y=from+(to-from)*Math.min(i,20)/20;
            MotionEvent event=MotionEvent.obtain(down,SystemClock.uptimeMillis(),action,x,y,0);
            event.setSource(InputDevice.SOURCE_TOUCHSCREEN);
            if (!automation.injectInputEvent(event,true)) throw new AssertionError("Touch injection rejected");
            event.recycle();
            SystemClock.sleep(30);
        }
    }

    private void touchScrolling() {
        Rect viewport=new Rect(); node("Files").getBoundsInScreen(viewport);
        float density=getTargetContext().getResources().getDisplayMetrics().density;
        float gutter=48*density;
        // Start inside the minimum-size thumb, then drag to the very end of the track.
        drag(viewport.right-gutter/2,viewport.top+gutter/2,viewport.bottom-4);
        node("Photo 0999.jpg - 3 copies");
        drag(viewport.right-gutter/2,viewport.bottom-gutter/2,viewport.top+4);
        node("Photo 0000.jpg - 3 copies");
        Rect beforeSwipe=new Rect();node("Photo 0000.jpg - 3 copies").getBoundsInScreen(beforeSwipe);
        drag(viewport.centerX(),viewport.bottom-30,viewport.top+30);
        await(() -> {
            AccessibilityNodeInfo first=find("Photo 0000.jpg - 3 copies");
            if(first==null)return Boolean.TRUE;
            Rect after=new Rect();first.getBoundsInScreen(after);
            return after.top<beforeSwipe.top-10 || after.bottom<beforeSwipe.bottom-10?Boolean.TRUE:null;
        },"Content swipe did not move row geometry");
        ArrayDeque<AccessibilityNodeInfo> rows=new ArrayDeque<>();
        rows.add(node("Files"));
        while (!rows.isEmpty()) {
            AccessibilityNodeInfo row=rows.removeFirst();
            if (row.isSelected()) throw new AssertionError("A scrolling gesture selected a file");
            for (int i=0;i<row.getChildCount();++i) {
                AccessibilityNodeInfo child=row.getChild(i);
                if (child!=null) rows.add(child);
            }
        }
    }

    @Override public void onStart() {
        Bundle result=new Bundle();
        try {
            automation=getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            AccessibilityServiceInfo info=automation.getServiceInfo();
            info.flags|=AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS | AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;
            automation.setServiceInfo(info);
            Intent intent=new Intent().setClassName("io.antono2.vimgui.accessible","io.antono2.vimgui.demo.ImGuiActivity")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            Activity activity=startActivitySync(intent);
            runOnMainSync(() -> activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON));
            node("Search files");
            runOnMainSync(()->((android.hardware.input.InputManager.InputDeviceListener)activity).onInputDeviceRemoved(-1234));
            // Test isolated Context configurations, preserving device settings.
            java.lang.reflect.Method scaleMethod=activity.getClassLoader().loadClass("io.antono2.imgui.ImGuiInputView").getMethod("nativeUiScale",android.content.Context.class);
            float savedFontScale=activity.getResources().getConfiguration().fontScale;
            float normal=0, enlarged=0;
            for(float preference:new float[]{1.0f,1.75f}) {
                android.content.res.Configuration configuration=new android.content.res.Configuration(activity.getResources().getConfiguration());
                configuration.fontScale=preference;
                android.content.Context configured=activity.createConfigurationContext(configuration);
                float actual=(Float)scaleMethod.invoke(null,configured);
                float expected=android.util.TypedValue.applyDimension(android.util.TypedValue.COMPLEX_UNIT_SP,16,configured.getResources().getDisplayMetrics())/16;
                if(Math.abs(actual-expected)>0.001f)throw new AssertionError("Native system font scale differs from Android SP conversion");
                if(preference==1)normal=actual;else enlarged=actual;
            }
            if(activity.getResources().getConfiguration().fontScale!=savedFontScale)throw new AssertionError("Isolated font contexts changed activity configuration");
            if(enlarged<=normal)throw new AssertionError("System font preference was ignored");
            if((Float)scaleMethod.invoke(null,new Object[]{null})!=1)throw new AssertionError("Null context scale fallback failed");
            AccessibilityNodeInfo.RangeInfo range=node("Known progress").getRangeInfo();
            if(range==null || Math.abs(range.getCurrent()-0.4f)>0.001f || range.getMin()!=0 || range.getMax()!=1)throw new AssertionError("Determinate progress range missing");
            if(node("Unknown progress").getRangeInfo()!=null)throw new AssertionError("Unknown progress falsely exposes a numeric range");
            touchScrolling();
            click("Last file");
            AccessibilityNodeInfo last=node("Photo 0999.jpg - 3 copies");
            await(() -> {
                AccessibilityNodeInfo row=find("Photo 0999.jpg - 3 copies"),list=find("Files");
                if (row==null || list==null) return null;
                Rect bounds=new Rect(),viewport=new Rect(); row.getBoundsInScreen(bounds); list.getBoundsInScreen(viewport);
                return !bounds.isEmpty() && viewport.contains(bounds)?Boolean.TRUE:null;
            },"Last row geometry is outside the viewport");
            if (!last.performAction(AccessibilityNodeInfo.ACTION_CLICK)) throw new AssertionError("Last row click rejected");
            click("Keep selected"); node("Keeper actions: 1");

            Bundle unicode=new Bundle();
            unicode.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,"A📷e\u0301Z");
            if(!node("Search files").performAction(AccessibilityNodeInfo.ACTION_SET_TEXT,unicode))throw new AssertionError("Unicode text rejected");
            await(()->{AccessibilityNodeInfo field=find("Search files");return field!=null && "A📷e\u0301Z".contentEquals(field.getText()==null?"":field.getText())?Boolean.TRUE:null;},"Unicode text damaged");
            Bundle unicodeSelection=new Bundle();
            unicodeSelection.putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT,3);
            unicodeSelection.putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT,5);
            if(!node("Search files").performAction(AccessibilityNodeInfo.ACTION_SET_SELECTION,unicodeSelection))throw new AssertionError("Unicode selection rejected");
            await(()->{AccessibilityNodeInfo field=find("Search files");return field!=null && field.getTextSelectionStart()==3 && field.getTextSelectionEnd()==5?Boolean.TRUE:null;},"UTF-16 selection did not round-trip across emoji and combining text");
            Bundle text=new Bundle(); text.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,"0007");
            if (!node("Search files").performAction(AccessibilityNodeInfo.ACTION_SET_TEXT,text)) throw new AssertionError("Set text rejected");
            await(()->{AccessibilityNodeInfo field=find("Search files");return field!=null && "0007".contentEquals(field.getText()==null?"":field.getText())?Boolean.TRUE:null;},"Filtered text did not settle after Unicode selection");
            node("Files").performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SHOW_ON_SCREEN.getId());
            node("Photo 0007.jpg - 3 copies");
            Bundle selection=new Bundle();
            selection.putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT,1);
            selection.putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT,3);
            if (!node("Search files").performAction(AccessibilityNodeInfo.ACTION_SET_SELECTION,selection)) throw new AssertionError("Selection rejected");
            await(() -> { AccessibilityNodeInfo input=find("Search files"); return input!=null && input.getTextSelectionStart()==1 && input.getTextSelectionEnd()==3?Boolean.TRUE:null; },"Text selection did not reach the widget");

            runOnMainSync(() -> {
                View input=inputView(activity.getWindow().getDecorView());
                if (input==null) throw new AssertionError("IME view missing");
                InputConnection connection=input.onCreateInputConnection(new EditorInfo());
                if (connection==null) throw new AssertionError("IME connection missing");
                connection.setSelection(0,4);
                connection.commitText("0008",1);
            });
            await(() -> { AccessibilityNodeInfo input=find("Search files"); return input!=null && "0008".contentEquals(input.getText()==null?"":input.getText())?Boolean.TRUE:null; },"IME edit did not reach the native widget");
            AtomicReference<InputConnection> editor=new AtomicReference<>();
            runOnMainSync(() -> {
                InputConnection connection=inputView(activity.getWindow().getDecorView()).onCreateInputConnection(new EditorInfo());
                editor.set(connection);
                connection.setSelection(0,4);
                char[] oversized=new char[512]; java.util.Arrays.fill(oversized,'x');
                connection.commitText(new String(oversized),1);
            });
            await(() -> {
                AtomicReference<CharSequence> value=new AtomicReference<>();
                runOnMainSync(() -> value.set(editor.get().getTextBeforeCursor(1024,0)));
                return "0008".contentEquals(value.get()==null?"":value.get())?Boolean.TRUE:null;
            },"Rejected oversized IME edit did not restore the existing text");
            click("High contrast");
            await(() -> { AccessibilityNodeInfo item=find("High contrast"); return item!=null && item.isChecked()?Boolean.TRUE:null; },"High contrast did not toggle");
            click("200% text");
            await(() -> { AccessibilityNodeInfo item=find("200% text"); return item!=null && item.isChecked()?Boolean.TRUE:null; },"Text scaling did not toggle");
            runOnMainSync(activity::recreate);
            SystemClock.sleep(1000);
            node("Search files");
            result.putString("result","PASS: touch scrollbar and content swipes, Android accessibility actions, list geometry, text selection, IME, oversized-edit rejection, contrast, system font-size conversion, input-device disconnect routing, scaling, and activity recreation");
            finish(Activity.RESULT_OK,result);
        } catch (Throwable error) {
            result.putString("result","FAIL: "+error+"; cause="+error.getCause());
            finish(Activity.RESULT_CANCELED,result);
        }
    }
}
