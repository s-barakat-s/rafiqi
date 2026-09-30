package flutter.overlay.window.flutter_overlay_window;

import android.app.Activity;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationManagerCompat;

import java.util.Map;

import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class FlutterOverlayWindowPlugin implements
        FlutterPlugin, ActivityAware, BasicMessageChannel.MessageHandler, MethodCallHandler,
        PluginRegistry.ActivityResultListener {

    private MethodChannel channel;
    private Context context;
    private Activity mActivity;
    private BasicMessageChannel<Object> messenger;
    /**
     * Pending reply of the in-flight permission request, if any.
     * Kept separate from unrelated method-call results so that any other
     * method call can never overwrite or swallow a permission result.
     */
    private Result pendingPermissionResult;
    private ActivityPluginBinding activityBinding;
    final int REQUEST_CODE_FOR_OVERLAY_PERMISSION = 1248;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), OverlayConstants.CHANNEL_TAG);
        channel.setMethodCallHandler(this);

        messenger = new BasicMessageChannel(flutterPluginBinding.getBinaryMessenger(), OverlayConstants.MESSENGER_TAG,
                JSONMessageCodec.INSTANCE);
        messenger.setMessageHandler(this);

    }

    /**
     * Permission-request handling kept separate from unrelated method calls.
     * <p>
     * - A repeated request while one is outstanding resolves only the newest
     *   pending reply; the superseded one completes with an explicit error so
     *   no accepted request is ever left unresolved.
     * - On permission return the ACTUAL permission state is checked rather
     *   than trusting the activity result code.
     */
    private void handlePermissionRequest(@NonNull Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true);
            return;
        }
        if (mActivity == null) {
            result.error("NO_ACTIVITY", "overlay permission requires a foreground activity", null);
            return;
        }
        if (checkOverlayPermission()) {
            // Already granted; short-circuit without opening settings.
            result.success(true);
            return;
        }
        if (pendingPermissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "an overlay permission request is already pending", null);
            return;
        }
        pendingPermissionResult = result;
        try {
            Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION);
            intent.setData(Uri.parse("package:" + mActivity.getPackageName()));
            mActivity.startActivityForResult(intent, REQUEST_CODE_FOR_OVERLAY_PERMISSION);
        } catch (Exception exception) {
            pendingPermissionResult = null;
            result.error("START_FAILED", "could not open overlay permission settings", exception);
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("checkPermission")) {
            result.success(checkOverlayPermission());
        } else if (call.method.equals("requestPermission")) {
            handlePermissionRequest(result);
        } else if (call.method.equals("showOverlay")) {
            if (!checkOverlayPermission()) {
                result.error("PERMISSION", "overlay permission is not enabled", null);
                return;
            }
            Integer height = call.argument("height");
            Integer width = call.argument("width");
            String alignment = call.argument("alignment");
            String flag = call.argument("flag");
            String overlayTitle = call.argument("overlayTitle");
            String overlayContent = call.argument("overlayContent");
            String notificationVisibility = call.argument("notificationVisibility");
            boolean enableDrag = call.argument("enableDrag");
            String positionGravity = call.argument("positionGravity");
            Map<String, Integer> startPosition = call.argument("startPosition");
            int startX = startPosition != null ? startPosition.getOrDefault("x", OverlayConstants.DEFAULT_XY) : OverlayConstants.DEFAULT_XY;
            int startY = startPosition != null ? startPosition.getOrDefault("y", OverlayConstants.DEFAULT_XY) : OverlayConstants.DEFAULT_XY;


            WindowSetup.width = width != null ? width : -1;
            WindowSetup.height = height != null ? height : -1;
            WindowSetup.enableDrag = enableDrag;
            WindowSetup.setGravityFromAlignment(alignment != null ? alignment : "center");
            WindowSetup.setFlag(flag != null ? flag : "flagNotFocusable");
            WindowSetup.overlayTitle = overlayTitle;
            WindowSetup.overlayContent = overlayContent == null ? "" : overlayContent;
            WindowSetup.positionGravity = positionGravity;
            WindowSetup.setNotificationVisibility(notificationVisibility);

            final Intent intent = new Intent(context, OverlayService.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
            intent.putExtra("startX", startX);
            intent.putExtra("startY", startY);
            context.startService(intent);
            result.success(null);
        } else if (call.method.equals("isOverlayActive")) {
            result.success(OverlayService.isRunning);
            return;
        } else if (call.method.equals("moveOverlay")) {
            int x = call.argument("x");
            int y = call.argument("y");
            result.success(OverlayService.moveOverlay(x, y));
        } else if (call.method.equals("updateOverlayLayout")) {
            Integer width = call.argument("width");
            Integer height = call.argument("height");
            Integer x = call.argument("x");
            Integer y = call.argument("y");
            Boolean enableDrag = call.argument("enableDrag");
            String alignment = call.argument("alignment");
            boolean updated = OverlayService.updateOverlayLayout(width, height, x, y, enableDrag, alignment);
            Log.d("OverlayPlugin", "updateOverlayLayout result: " + updated);
            result.success(updated);
        } else if (call.method.equals("updateSystemGestureExclusion")) {
            Boolean enabled = call.argument("enabled");
            Integer width = call.argument("width");
            Integer height = call.argument("height");
            boolean updated = OverlayService.updateSystemGestureExclusion(enabled != null && enabled, width, height);
            Log.d("OverlayPlugin", "updateSystemGestureExclusion result: " + updated);
            result.success(updated);
        } else if (call.method.equals("getOverlayPosition")) {
            result.success(OverlayService.getCurrentPosition());
        } else if (call.method.equals("closeOverlay")) {
            // Closing an already-stopped overlay completes predictably
            // instead of leaving the Dart await hanging forever.
            if (OverlayService.isRunning) {
                final Intent i = new Intent(context, OverlayService.class);
                context.stopService(i);
                result.success(true);
            } else {
                result.success(false);
            }
            return;
        } else {
            result.notImplemented();
        }

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (pendingPermissionResult != null) {
            pendingPermissionResult.error("ENGINE_DETACHED", "plugin detached before permission completed", null);
            pendingPermissionResult = null;
        }
        if (channel != null) channel.setMethodCallHandler(null);
        if (messenger != null) messenger.setMessageHandler(null);
        if (WindowSetup.messenger == messenger) WindowSetup.messenger = null;
        channel = null;
        messenger = null;
        context = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
        activityBinding = binding;
        // Only the activity-backed (main) engine is the overlay operation
        // authority. The headless overlay engine must never replace it.
        WindowSetup.messenger = messenger;
        // Register (once per binding) so the permission flow can complete
        // after returning from the system settings screen. Re-attachment
        // after configuration changes restores the listener as well.
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        detachActivityBinding(false);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        detachActivityBinding(true);
    }

    private void detachActivityBinding(boolean terminal) {
        if (activityBinding != null) {
            activityBinding.removeActivityResultListener(this);
            activityBinding = null;
        }
        mActivity = null;
        if (terminal && pendingPermissionResult != null) {
            pendingPermissionResult.error("ACTIVITY_DETACHED", "activity detached before permission completed", null);
            pendingPermissionResult = null;
        }
    }

    @Override
    public void onMessage(@Nullable Object message, @NonNull BasicMessageChannel.Reply reply) {
        final io.flutter.embedding.engine.FlutterEngine overlayEngine =
                FlutterEngineCache.getInstance().get(OverlayConstants.CACHED_TAG);
        if (overlayEngine == null) {
            reply.reply(java.util.Collections.singletonMap("error", "OVERLAY_ENGINE_UNAVAILABLE"));
            return;
        }
        try {
            BasicMessageChannel<Object> overlayMessageChannel = new BasicMessageChannel<>(
                    overlayEngine.getDartExecutor(),
                    OverlayConstants.MESSENGER_TAG, JSONMessageCodec.INSTANCE);
            overlayMessageChannel.send(message, reply);
        } catch (RuntimeException exception) {
            reply.reply(java.util.Collections.singletonMap("error", "OVERLAY_FORWARD_FAILED"));
        }
    }

    private boolean checkOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.canDrawOverlays(context);
        }
        return true;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQUEST_CODE_FOR_OVERLAY_PERMISSION) {
            return false;
        }
        if (pendingPermissionResult != null) {
            // Check the ACTUAL permission state, not the result code.
            pendingPermissionResult.success(checkOverlayPermission());
            pendingPermissionResult = null;
        }
        return true;
    }

}
