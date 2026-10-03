package io.antono2.imgui;

import android.os.Handler;
import android.os.Looper;
import android.view.Choreographer;
import android.view.View;
import android.view.accessibility.AccessibilityEvent;
import android.util.Log;
import android.graphics.Rect;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityNodeProvider;

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
    private final android.util.LongSparseArray<Integer> virtualIds = new android.util.LongSparseArray<>();
    private final android.util.SparseArray<org.json.JSONObject> nodes = new android.util.SparseArray<>();
    private int nextVirtualId=1, rootId=-1, inputFocus=-1, accessibilityFocus=-1;
    private long revision=-1;
    private int virtualId(long id) {
        Integer existing=virtualIds.get(id);if(existing!=null)return existing;
        int allocated=nextVirtualId++;virtualIds.put(id,allocated);return allocated;
    }
    private Rect bounds(org.json.JSONObject node) {
        return new Rect((int)Math.floor(node.optDouble("x")),(int)Math.floor(node.optDouble("y")),
            (int)Math.ceil(node.optDouble("x")+node.optDouble("width")),
            (int)Math.ceil(node.optDouble("y")+node.optDouble("height")));
    }
    private void event(int id,int type) {
        org.json.JSONObject node=nodes.get(id);if(node==null||host.getParent()==null)return;
        AccessibilityEvent event=AccessibilityEvent.obtain(type);
        event.setSource(host,id);event.setPackageName(host.getContext().getPackageName());
        event.setClassName(className(node.optInt("role")));
        event.setContentDescription(node.optString("label"));
        event.setEnabled((node.optInt("flags")&1)==0);event.setChecked((node.optInt("flags")&4)!=0);
        if(type==AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED)event.setContentChangeTypes(AccessibilityEvent.CONTENT_CHANGE_TYPE_SUBTREE);
        if(node.optInt("role")==5){String text=node.optString("value");event.getText().add(text);event.setItemCount(text.length());
            event.setFromIndex(utf16Offset(text,node.optInt("anchor")));event.setToIndex(utf16Offset(text,node.optInt("focus")));}
        host.getParent().requestSendAccessibilityEvent(host,event);
    }
    private String className(int role) {
        switch(role) {
            case 2:return "android.widget.Button";
            case 3:return "android.widget.CheckBox";
            case 4:return "android.widget.RadioButton";
            case 5:return "android.widget.EditText";
            case 7:return "android.widget.ListView";
            case 8:return "android.widget.TextView";
            case 9:return "android.widget.ProgressBar";
            default:return "android.view.View";
        }
    }
    private int utf16Offset(String text,int codepoints) {
        return text.offsetByCodePoints(0,Math.max(0,Math.min(codepoints,text.codePointCount(0,text.length()))));
    }
    private void refresh() {
        String snapshot=nativeSnapshot(context,revision);if(snapshot==null)return;
        try {
            org.json.JSONObject tree=new org.json.JSONObject(snapshot);
            int previousFocus=inputFocus;
            android.util.SparseArray<org.json.JSONObject> previous=nodes.clone();
            nodes.clear();revision=tree.getLong("revision");
            rootId=virtualId(tree.getLong("root"));inputFocus=virtualId(tree.getLong("focus"));
            org.json.JSONArray items=tree.getJSONArray("nodes");
            for(int i=0;i<items.length();i++) {
                org.json.JSONObject item=items.getJSONObject(i);int id=virtualId(item.getLong("id"));nodes.put(id,item);
            }
            if(accessibilityFocus!=-1 && nodes.get(accessibilityFocus)==null)accessibilityFocus=-1;
            if(previousFocus!=inputFocus)event(inputFocus,AccessibilityEvent.TYPE_VIEW_FOCUSED);
            for(int i=0;i<nodes.size();i++) {
                int id=nodes.keyAt(i);org.json.JSONObject now=nodes.valueAt(i),old=previous.get(id);
                if(old!=null && now.optInt("role")==5 && !old.optString("value").equals(now.optString("value")))
                    event(id,AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED);
                if(old!=null && now.optInt("role")==5 && (old.optInt("anchor")!=now.optInt("anchor") || old.optInt("focus")!=now.optInt("focus")))
                    event(id,AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED);
            }
            event(rootId,AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
        } catch(org.json.JSONException error) {failed=true;Log.e("ImGuiAccessibility","Invalid native snapshot",error);}
    }
    private final AccessibilityNodeProvider provider=new AccessibilityNodeProvider() {
        @Override public AccessibilityNodeInfo createAccessibilityNodeInfo(int id) {
            if(closed||context==0)return null;
            if(id==View.NO_ID) {
                AccessibilityNodeInfo info=AccessibilityNodeInfo.obtain(host);host.onInitializeAccessibilityNodeInfo(info);
                if(nodes.get(rootId)!=null)info.addChild(host,rootId);return info;
            }
            org.json.JSONObject node=nodes.get(id);if(node==null)return null;
            AccessibilityNodeInfo info=AccessibilityNodeInfo.obtain();info.setSource(host,id);
            info.setPackageName(host.getContext().getPackageName());int role=node.optInt("role"),flags=node.optInt("flags"),actions=node.optInt("actions");
            info.setClassName(className(role));info.setImportantForAccessibility(true);
            long parent=node.optLong("parent");if(parent==0)info.setParent(host);else info.setParent(host,virtualId(parent));
            org.json.JSONArray children=node.optJSONArray("children");
            if(children!=null)for(int i=0;i<children.length();i++)info.addChild(host,virtualId(children.optLong(i)));
            String label=node.optString("label"),text=node.optString("value");
            info.setContentDescription(label);
            if(role==5) {info.setText(text);info.setEditable((flags&16)==0);info.setInputType(android.text.InputType.TYPE_CLASS_TEXT);
                info.setTextSelection(utf16Offset(text,node.optInt("anchor")),utf16Offset(text,node.optInt("focus")));}
            else if(role==6)info.setText(label);
            else if(!text.isEmpty() && role!=9)info.setText(text);
            if(role==3||role==4){info.setCheckable(true);info.setChecked((flags&4)!=0);}
            info.setSelected((flags&2)!=0);info.setEnabled((flags&1)==0);
            info.setFocusable((actions&1)!=0);info.setFocused(id==inputFocus);info.setAccessibilityFocused(id==accessibilityFocus);
            info.setClickable((actions&2)!=0 || role==5);info.setScrollable(node.optDouble("scrollMax")>0);
            if((flags&8)!=0)info.setLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
            if(role==9 && (flags&32)==0)info.setRangeInfo(AccessibilityNodeInfo.RangeInfo.obtain(
                AccessibilityNodeInfo.RangeInfo.RANGE_TYPE_FLOAT,(float)node.optDouble("min"),(float)node.optDouble("max"),(float)node.optDouble("number")));
            Rect rectangle=bounds(node),parentRect=new Rect(rectangle);
            if(parent!=0){org.json.JSONObject p=nodes.get(virtualId(parent));if(p!=null){Rect pb=bounds(p);parentRect.offset(-pb.left,-pb.top);}}
            info.setBoundsInParent(parentRect);
            Rect clipped=new Rect(rectangle);boolean visible=clipped.intersect(0,0,host.getWidth(),host.getHeight());
            long ancestor=parent;
            while(ancestor!=0){org.json.JSONObject p=nodes.get(virtualId(ancestor));if(p==null)break;
                if(p.optInt("role")==7)visible=clipped.intersect(bounds(p))&&visible;ancestor=p.optLong("parent");}
            int[] origin=new int[2];host.getLocationOnScreen(origin);rectangle.offset(origin[0],origin[1]);info.setBoundsInScreen(rectangle);
            info.setVisibleToUser(visible&&host.isShown());
            if((actions&1)!=0)info.addAction(AccessibilityNodeInfo.ACTION_FOCUS);
            if((actions&2)!=0 || role==5)info.addAction(AccessibilityNodeInfo.ACTION_CLICK);
            if((actions&4)!=0)info.addAction(AccessibilityNodeInfo.ACTION_SET_TEXT);
            if((actions&16)!=0)info.addAction(AccessibilityNodeInfo.ACTION_SET_SELECTION);
            if((actions&8)!=0)info.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SHOW_ON_SCREEN);
            if((actions&32)!=0)info.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
            if((actions&64)!=0)info.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
            info.addAction(id==accessibilityFocus?AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS:AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS);
            return info;
        }
        @Override public AccessibilityNodeInfo findFocus(int focus) {
            return createAccessibilityNodeInfo(focus==AccessibilityNodeInfo.FOCUS_ACCESSIBILITY?accessibilityFocus:inputFocus);
        }
        @Override public boolean performAction(int id,int action,android.os.Bundle arguments) {
            org.json.JSONObject node=nodes.get(id);if(node==null||closed||context==0)return false;
            if(action==AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS) {
                if(accessibilityFocus==id)return false;
                if(accessibilityFocus!=-1)event(accessibilityFocus,AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
                accessibilityFocus=id;event(id,AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED);
                nativeAction(context,node.optLong("id"),8,null,0,0);return true;
            }
            if(action==AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS) {
                if(accessibilityFocus!=id)return false;accessibilityFocus=-1;event(id,AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);return true;
            }
            int nativeAction=0,anchor=0,focus=0;String value=null;
            switch(action) {
                case AccessibilityNodeInfo.ACTION_FOCUS:nativeAction=1;break;
                case AccessibilityNodeInfo.ACTION_CLICK:nativeAction=node.optInt("role")==5?1:2;break;
                case AccessibilityNodeInfo.ACTION_SET_TEXT:
                    if(arguments==null)return false;
                    CharSequence requested=arguments.getCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE);
                    value=requested==null?"":requested.toString();nativeAction=4;break;
                case AccessibilityNodeInfo.ACTION_SET_SELECTION:
                    if(arguments==null)return false;
                    String text=node.optString("value");
                    int start=arguments.getInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT,-1),end=arguments.getInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT,-1);
                    if(start<0||end<0||start>text.length()||end>text.length())return false;
                    if((start>0 && start<text.length() && Character.isLowSurrogate(text.charAt(start))) ||
                       (end>0 && end<text.length() && Character.isLowSurrogate(text.charAt(end))))return false;
                    anchor=text.codePointCount(0,start);focus=text.codePointCount(0,end);nativeAction=16;break;
                case AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD:nativeAction=32;break;
                case AccessibilityNodeInfo.ACTION_SCROLL_FORWARD:nativeAction=64;break;
                default:if(action==AccessibilityNodeInfo.AccessibilityAction.ACTION_SHOW_ON_SCREEN.getId())nativeAction=8;
            }
            return nativeAction!=0 && ImGuiAccessibility.nativeAction(context,node.optLong("id"),nativeAction,value,anchor,focus);
        }
    };
    private void updateVisualFocus() {
        AccessibilityManager manager = (AccessibilityManager) host.getContext().getSystemService(android.content.Context.ACCESSIBILITY_SERVICE);
        AccessibilityNodeProvider provider = host.getAccessibilityNodeProvider();
        AccessibilityNodeInfo focused = manager != null && manager.isTouchExplorationEnabled() && provider != null
                ? provider.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY) : null;
        Rect bounds = new Rect();
        if (focused != null) {
            focused.getBoundsInScreen(bounds);
            int[] location = new int[2]; host.getLocationOnScreen(location);
            bounds.offset(-location[0], -location[1]);
            if (!bounds.intersect(0, 0, host.getWidth(), host.getHeight())) bounds.setEmpty();
            focused.recycle();
        }
        nativeVisualFocus(context, !bounds.isEmpty(), bounds.left, bounds.top, bounds.width(), bounds.height());
    }
    private final Choreographer.FrameCallback update = new Choreographer.FrameCallback() {
        @Override public void doFrame(long frameTimeNanos) {
            if (!closed && context != 0) {
                refresh();
                updateVisualFocus();
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
        revision=-1;virtualIds.clear();nodes.clear();nextVirtualId=1;accessibilityFocus=-1;
        host.setAccessibilityDelegate(new View.AccessibilityDelegate() {
            @Override public AccessibilityNodeProvider getAccessibilityNodeProvider(View view) {return provider;}
        });
        host.setOnHoverListener(new View.OnHoverListener() {
            private int hovered=-1;
            @Override public boolean onHover(View view,android.view.MotionEvent motion) {
                AccessibilityManager manager=(AccessibilityManager)host.getContext().getSystemService(android.content.Context.ACCESSIBILITY_SERVICE);
                if(manager==null||!manager.isTouchExplorationEnabled())return false;
                int hit=-1;long area=Long.MAX_VALUE;
                if(motion.getAction()!=android.view.MotionEvent.ACTION_HOVER_EXIT) {
                    for(int i=0;i<nodes.size();i++) {
                        org.json.JSONObject item=nodes.valueAt(i);Rect rectangle=bounds(item);
                        if(!rectangle.intersect(0,0,host.getWidth(),host.getHeight()))continue;
                        boolean visible=true;long ancestor=item.optLong("parent");
                        while(ancestor!=0){org.json.JSONObject parent=nodes.get(virtualId(ancestor));if(parent==null)break;
                            if(parent.optInt("role")==7 && !rectangle.intersect(bounds(parent))){visible=false;break;}
                            ancestor=parent.optLong("parent");}
                        if(!visible)continue;
                        long size=(long)rectangle.width()*rectangle.height();
                        if(rectangle.contains((int)motion.getX(),(int)motion.getY())&&size>0&&size<area){hit=nodes.keyAt(i);area=size;}
                    }
                }
                if(hit!=hovered){if(hit!=-1)event(hit,AccessibilityEvent.TYPE_VIEW_HOVER_ENTER);
                    if(hovered!=-1)event(hovered,AccessibilityEvent.TYPE_VIEW_HOVER_EXIT);hovered=hit;}
                return true;
            }
        });
        refresh();
        host.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_YES);
        // Invalidate the real-view tree after installing the native provider.
        host.post(() -> {
            if (!closed && context == address) {
                event(rootId,AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
            }
        });
        Choreographer.getInstance().postFrameCallback(update);
    }

    private void detach() {
        Choreographer.getInstance().removeFrameCallback(update);
        if (context != 0) {
            nativeVisualFocus(context, false, 0, 0, 0, 0);
            nativeDetach(context);
            nativeRelease(context);
            context = 0;
            host.setAccessibilityDelegate(null);host.setOnHoverListener(null);nodes.clear();virtualIds.clear();revision=-1;
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
    private static native String nativeSnapshot(long context,long revision);
    private static native boolean nativeAction(long context,long id,int action,String value,int anchor,int focus);
    private static native void nativeVisualFocus(long context, boolean visible, int x, int y, int width, int height);
}
