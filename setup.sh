#!/bin/bash
mkdir -p app/src/main/java/com/voicemouse/keyboard
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml
mkdir -p gradle/wrapper

cat << 'EOF' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.voicemouse.keyboard'
    compileSdk 34

    defaultConfig {
        applicationId "com.voicemouse.keyboard"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
}
EOF

cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>

    <application
        android:allowBackup="true"
        android:icon="@android:drawable/ic_btn_speak_now"
        android:label="VoiceMouse Keyboard"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">

        <service
            android:name=".VoiceInputMethodService"
            android:label="VoiceMouse Keyboard"
            android:permission="android.permission.BIND_INPUT_METHOD"
            android:exported="true">
            <intent-filter>
                <action android:name="android.view.InputMethod" />
            </intent-filter>
            <meta-data
                android:name="android.view.im"
                android:resource="@xml/method" />
        </service>
    </application>
</manifest>
EOF

cat << 'EOF' > app/src/main/res/xml/method.xml
<?xml version="1.0" encoding="utf-8"?>
<input-method xmlns:android="http://schemas.android.com/apk/res/android"
    android:settingsActivity="" />
EOF

cat << 'EOF' > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">VoiceMouse Keyboard</string>
</resources>
EOF

cat << 'EOF' > app/src/main/res/layout/keyboard_view.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:background="#1E1E2E"
    android:padding="8dp">

    <!-- Language Selector Row -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center"
        android:weightSum="4">

        <Button
            android:id="@+id/btn_lang_bn"
            android:layout_width="0dp"
            android:layout_height="40dp"
            android:layout_weight="1"
            android:text="বাংলা"
            android:textSize="12sp"
            android:textColor="#FFFFFF"
            android:backgroundTint="#313244" />

        <Button
            android:id="@+id/btn_lang_en"
            android:layout_width="0dp"
            android:layout_height="40dp"
            android:layout_weight="1"
            android:text="English"
            android:textSize="12sp"
            android:textColor="#FFFFFF"
            android:backgroundTint="#313244" />

        <Button
            android:id="@+id/btn_lang_ar"
            android:layout_width="0dp"
            android:layout_height="40dp"
            android:layout_weight="1"
            android:text="العربية"
            android:textSize="12sp"
            android:textColor="#FFFFFF"
            android:backgroundTint="#313244" />

        <Button
            android:id="@+id/btn_lang_hi"
            android:layout_width="0dp"
            android:layout_height="40dp"
            android:layout_weight="1"
            android:text="हिन्दी"
            android:textSize="12sp"
            android:textColor="#FFFFFF"
            android:backgroundTint="#313244" />
    </LinearLayout>

    <!-- Main Voice Button Row -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="100dp"
        android:gravity="center"
        android:orientation="vertical">

        <Button
            android:id="@+id/btn_mic"
            android:layout_width="160dp"
            android:layout_height="60dp"
            android:text="🎤"
            android:textSize="22sp"
            android:backgroundTint="#89B4FA"
            android:textColor="#1E1E2E" />
    </LinearLayout>

    <!-- Bottom Controls -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center"
        android:weightSum="4">

        <Button
            android:id="@+id/btn_space"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="2"
            android:text="Space"
            android:textColor="#FFFFFF"
            android:backgroundTint="#45475A" />

        <Button
            android:id="@+id/btn_backspace"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:text="⌫"
            android:textSize="16sp"
            android:textColor="#FFFFFF"
            android:backgroundTint="#45475A" />

        <Button
            android:id="@+id/btn_enter"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:text="↵"
            android:textSize="16sp"
            android:textColor="#FFFFFF"
            android:backgroundTint="#A6E3A1" />
    </LinearLayout>

</LinearLayout>
EOF

cat << 'EOF' > app/src/main/java/com/voicemouse/keyboard/VoiceInputMethodService.java
package com.voicemouse.keyboard;

import android.content.Intent;
import android.inputmethodservice.InputMethodService;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.InputConnection;
import android.widget.Button;
import android.widget.Toast;
import java.util.ArrayList;

public class VoiceInputMethodService extends InputMethodService {

    private SpeechRecognizer speechRecognizer;
    private String currentLanguage = "bn-BD";
    private Button btnMic;
    private boolean isListening = false;
    private Handler mainHandler;

    @Override
    public View onCreateInputView() {
        mainHandler = new Handler(Looper.getMainLooper());
        View view = getLayoutInflater().inflate(R.layout.keyboard_view, null);

        btnMic = view.findViewById(R.id.btn_mic);
        Button btnSpace = view.findViewById(R.id.btn_space);
        Button btnBackspace = view.findViewById(R.id.btn_backspace);
        Button btnEnter = view.findViewById(R.id.btn_enter);

        Button btnBn = view.findViewById(R.id.btn_lang_bn);
        Button btnEn = view.findViewById(R.id.btn_lang_en);
        Button btnAr = view.findViewById(R.id.btn_lang_ar);
        Button btnHi = view.findViewById(R.id.btn_lang_hi);

        btnBn.setOnClickListener(v -> { currentLanguage = "bn-BD"; Toast.makeText(this, "বাংলা সিলেক্ট করা হয়েছে", Toast.LENGTH_SHORT).show(); });
        btnEn.setOnClickListener(v -> { currentLanguage = "en-US"; Toast.makeText(this, "English selected", Toast.LENGTH_SHORT).show(); });
        btnAr.setOnClickListener(v -> { currentLanguage = "ar-SA"; Toast.makeText(this, "العربية", Toast.LENGTH_SHORT).show(); });
        btnHi.setOnClickListener(v -> { currentLanguage = "hi-IN"; Toast.makeText(this, "हिन्दी", Toast.LENGTH_SHORT).show(); });

        btnSpace.setOnClickListener(v -> {
            InputConnection ic = getCurrentInputConnection();
            if (ic != null) ic.commitText(" ", 1);
        });

        btnBackspace.setOnClickListener(v -> {
            InputConnection ic = getCurrentInputConnection();
            if (ic != null) ic.deleteSurroundingText(1, 0);
        });

        btnEnter.setOnClickListener(v -> {
            InputConnection ic = getCurrentInputConnection();
            if (ic != null) {
                ic.sendKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER));
                ic.sendKeyEvent(new KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER));
            }
        });

        btnMic.setOnClickListener(v -> {
            if (isListening) {
                stopListening();
            } else {
                startVoiceRecognition();
            }
        });

        return view;
    }

    private void startVoiceRecognition() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Toast.makeText(this, "Speech recognition not available", Toast.LENGTH_SHORT).show();
            return;
        }

        if (speechRecognizer != null) {
            speechRecognizer.destroy();
        }

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this);
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLanguage);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, currentLanguage);
        intent.putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, currentLanguage);

        speechRecognizer.setRecognitionListener(new RecognitionListener() {
            @Override
            public void onReadyForSpeech(Bundle params) {
                isListening = true;
                if (btnMic != null) btnMic.setText("🔴 শুনছি...");
            }

            @Override
            public void onBeginningOfSpeech() {}

            @Override
            public void onRmsChanged(float rmsdB) {}

            @Override
            public void onBufferReceived(byte[] buffer) {}

            @Override
            public void onEndOfSpeech() {
                isListening = false;
                if (btnMic != null) btnMic.setText("🎤");
            }

            @Override
            public void onError(int error) {
                isListening = false;
                if (btnMic != null) btnMic.setText("🎤");
                String errorMsg = "ত্রুটি কোড: " + error;
                if (error == SpeechRecognizer.ERROR_NO_MATCH) errorMsg = "কিছু শুনতে পায়নি, আবার চেষ্টা করুন";
                else if (error == SpeechRecognizer.ERROR_NETWORK || error == SpeechRecognizer.ERROR_NETWORK_TIMEOUT) errorMsg = "ইন্টারনেট সংযোগ চেক করুন";
                Toast.makeText(VoiceInputMethodService.this, errorMsg, Toast.LENGTH_SHORT).show();
            }

            @Override
            public void onResults(Bundle results) {
                isListening = false;
                if (btnMic != null) btnMic.setText("🎤");
                ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (matches != null && !matches.isEmpty()) {
                    String recognizedText = matches.get(0);
                    InputConnection ic = getCurrentInputConnection();
                    if (ic != null) {
                        ic.commitText(recognizedText + " ", 1);
                    }
                }
            }

            @Override
            public void onPartialResults(Bundle partialResults) {}

            @Override
            public void onEvent(int eventType, Bundle params) {}
        });

        mainHandler.post(() -> speechRecognizer.startListening(intent));
    }

    private void stopListening() {
        if (speechRecognizer != null) {
            speechRecognizer.stopListening();
        }
        isListening = false;
        if (btnMic != null) btnMic.setText("🎤");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (speechRecognizer != null) {
            speechRecognizer.destroy();
            speechRecognizer = null;
        }
    }
}
EOF
