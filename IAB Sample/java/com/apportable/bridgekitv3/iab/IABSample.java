package com.apportable.bridgekitv3.iab;

import android.app.Activity;
import android.os.Bundle;
import com.apportable.RuntimeService;
import android.view.View;
import android.content.Intent;

public class IABSample extends Activity {
    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        new RuntimeService(this).loadLibraries();
        run();
    }

    public native void run();

    public native void onDriveButtonClicked(View view);

    public native void onBuyGasButtonClicked(View view);

    public native void onUpgradeAppButtonClicked(View view);

    public native void onInfiniteGasButtonClicked(View view);

    @Override
    protected native void onActivityResult(int requestCode, int resultCode, Intent data);
}