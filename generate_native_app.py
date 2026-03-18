import os
import shutil

ROOT = r"C:\Users\DHANVESH\Documents\TuneBridgeNative"
WRAPPER_SOURCE = r"C:\Users\DHANVESH\Documents\TuneBridge\android"

files = {
    "settings.gradle": """
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "TuneBridgeNative"
include(":app")
""",
    "build.gradle": """
plugins {
    id 'com.android.application' version '8.2.2' apply false
}
""",
    "gradle.properties": """
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
""",
    "app/build.gradle": """
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.tunebridge.nativeapp'
    compileSdk 34

    defaultConfig {
        applicationId "com.tunebridge.nativeapp"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures {
        viewBinding true
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    packaging {
        resources {
            excludes += '/META-INF/{AL2.0,LGPL2.1}'
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'com.google.android.material:material:1.12.0'
    implementation 'androidx.fragment:fragment:1.8.2'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
""",
    "app/src/main/AndroidManifest.xml": """
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="TuneBridge Native"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.TuneBridgeNative">
        <activity
            android:name=".activities.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
""",
    "app/src/main/res/values/colors.xml": """
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="tb_black">#050505</color>
    <color name="tb_surface">#121216</color>
    <color name="tb_surface_alt">#1A1A1F</color>
    <color name="tb_text_primary">#F4F4F5</color>
    <color name="tb_text_secondary">#9B9BA4</color>
    <color name="tb_accent">#2AE6C9</color>
</resources>
""",
    "app/src/main/res/values/themes.xml": """
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.TuneBridgeNative" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="android:windowBackground">@color/tb_black</item>
        <item name="android:statusBarColor">@color/tb_black</item>
        <item name="android:navigationBarColor">@color/tb_surface</item>
        <item name="colorPrimary">@color/tb_accent</item>
        <item name="colorSecondary">@color/tb_accent</item>
        <item name="android:fontFamily">sans-serif-medium</item>
    </style>
</resources>
""",
    "app/src/main/res/menu/bottom_nav_menu.xml": """
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/nav_home"
        android:icon="@android:drawable/ic_menu_view"
        android:title="Home" />
    <item
        android:id="@+id/nav_search"
        android:icon="@android:drawable/ic_menu_search"
        android:title="Search" />
    <item
        android:id="@+id/nav_library"
        android:icon="@android:drawable/ic_menu_sort_by_size"
        android:title="Library" />
</menu>
""",
    "app/src/main/res/anim/fade_in.xml": """
<?xml version="1.0" encoding="utf-8"?>
<alpha xmlns:android="http://schemas.android.com/apk/res/android"
    android:duration="200"
    android:fromAlpha="0"
    android:toAlpha="1" />
""",
    "app/src/main/res/anim/fade_out.xml": """
<?xml version="1.0" encoding="utf-8"?>
<alpha xmlns:android="http://schemas.android.com/apk/res/android"
    android:duration="200"
    android:fromAlpha="1"
    android:toAlpha="0" />
""",
    "app/src/main/res/layout/activity_main.xml": """
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/tb_black">

    <FrameLayout
        android:id="@+id/content_host"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_marginBottom="124dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:background="@color/tb_surface"
        android:orientation="vertical">

        <include
            android:id="@+id/mini_player"
            layout="@layout/layout_mini_player" />

        <com.google.android.material.bottomnavigation.BottomNavigationView
            android:id="@+id/bottom_nav"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:background="@color/tb_surface"
            app:itemIconTint="@color/nav_colors"
            app:itemTextColor="@color/nav_colors"
            app:menu="@menu/bottom_nav_menu" />
    </LinearLayout>

    <FrameLayout
        android:id="@+id/player_host"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:visibility="gone" />

</FrameLayout>
""",
    "app/src/main/res/color/nav_colors.xml": """
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:color="@color/tb_accent" android:state_checked="true" />
    <item android:color="@color/tb_text_secondary" />
</selector>
""",
    "app/src/main/res/layout/layout_mini_player.xml": """
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="64dp"
    android:background="@color/tb_surface_alt"
    android:gravity="center_vertical"
    android:orientation="horizontal"
    android:paddingHorizontal="12dp">

    <ImageView
        android:id="@+id/img_mini_art"
        android:layout_width="42dp"
        android:layout_height="42dp"
        android:background="@color/tb_surface" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="12dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/txt_mini_title"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:text="No track selected"
            android:textColor="@color/tb_text_primary"
            android:textSize="14sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/txt_mini_artist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:text=""
            android:textColor="@color/tb_text_secondary"
            android:textSize="12sp" />
    </LinearLayout>

    <ImageView
        android:id="@+id/btn_mini_play"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:padding="8dp"
        android:src="@android:drawable/ic_media_play"
        android:tint="@color/tb_text_primary" />

</LinearLayout>
""",
    "app/src/main/res/layout/fragment_list.xml": """
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/tb_black">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical">

        <TextView
            android:id="@+id/txt_header"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:paddingHorizontal="16dp"
            android:paddingTop="16dp"
            android:paddingBottom="8dp"
            android:text="Header"
            android:textColor="@color/tb_text_primary"
            android:textSize="22sp"
            android:textStyle="bold" />

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/recycler_tracks"
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1"
            android:clipToPadding="false"
            android:paddingBottom="12dp" />
    </LinearLayout>

</FrameLayout>
""",
    "app/src/main/res/layout/item_track.xml": """
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="72dp"
    android:background="?android:attr/selectableItemBackground"
    android:gravity="center_vertical"
    android:orientation="horizontal"
    android:paddingHorizontal="16dp">

    <ImageView
        android:id="@+id/img_art"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:background="@color/tb_surface" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="12dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/txt_title"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textColor="@color/tb_text_primary"
            android:textSize="15sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/txt_artist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textColor="@color/tb_text_secondary"
            android:textSize="13sp" />
    </LinearLayout>

</LinearLayout>
""",
    "app/src/main/res/layout/fragment_full_player.xml": """
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/tb_black">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical"
        android:padding="20dp">

        <ImageView
            android:id="@+id/btn_close"
            android:layout_width="40dp"
            android:layout_height="40dp"
            android:padding="8dp"
            android:src="@android:drawable/ic_menu_close_clear_cancel"
            android:tint="@color/tb_text_primary" />

        <ImageView
            android:id="@+id/img_full_art"
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_marginTop="12dp"
            android:layout_weight="1"
            android:background="@color/tb_surface" />

        <TextView
            android:id="@+id/txt_full_title"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="18dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:textColor="@color/tb_text_primary"
            android:textSize="24sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/txt_full_artist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:textColor="@color/tb_text_secondary"
            android:textSize="14sp" />

        <SeekBar
            android:id="@+id/seek_bar"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="18dp"
            android:progressTint="@color/tb_accent"
            android:thumbTint="@color/tb_accent" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="72dp"
            android:layout_marginTop="16dp"
            android:gravity="center"
            android:orientation="horizontal">

            <ImageView
                android:id="@+id/btn_prev"
                android:layout_width="52dp"
                android:layout_height="52dp"
                android:padding="12dp"
                android:src="@android:drawable/ic_media_previous"
                android:tint="@color/tb_text_primary" />

            <ImageView
                android:id="@+id/btn_play"
                android:layout_width="64dp"
                android:layout_height="64dp"
                android:layout_marginHorizontal="24dp"
                android:padding="12dp"
                android:src="@android:drawable/ic_media_play"
                android:tint="@color/tb_accent" />

            <ImageView
                android:id="@+id/btn_next"
                android:layout_width="52dp"
                android:layout_height="52dp"
                android:padding="12dp"
                android:src="@android:drawable/ic_media_next"
                android:tint="@color/tb_text_primary" />
        </LinearLayout>
    </LinearLayout>

</FrameLayout>
""",
    "app/src/main/java/com/tunebridge/nativeapp/models/Track.java": """
package com.tunebridge.nativeapp.models;

public class Track {
    private final String id;
    private final String title;
    private final String artist;
    private final String artworkUrl;

    public Track(String id, String title, String artist, String artworkUrl) {
        this.id = id;
        this.title = title;
        this.artist = artist;
        this.artworkUrl = artworkUrl;
    }

    public String getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getArtist() {
        return artist;
    }

    public String getArtworkUrl() {
        return artworkUrl;
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/adapters/TrackAdapter.java": """
package com.tunebridge.nativeapp.adapters;

import android.view.LayoutInflater;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.tunebridge.nativeapp.databinding.ItemTrackBinding;
import com.tunebridge.nativeapp.models.Track;

import java.util.List;

public class TrackAdapter extends RecyclerView.Adapter<TrackAdapter.TrackViewHolder> {

    public interface OnTrackClickListener {
        void onTrackClick(Track track);
    }

    private final List<Track> tracks;
    private final OnTrackClickListener listener;

    public TrackAdapter(List<Track> tracks, OnTrackClickListener listener) {
        this.tracks = tracks;
        this.listener = listener;
    }

    @NonNull
    @Override
    public TrackViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        ItemTrackBinding binding = ItemTrackBinding.inflate(
                LayoutInflater.from(parent.getContext()), parent, false);
        return new TrackViewHolder(binding);
    }

    @Override
    public void onBindViewHolder(@NonNull TrackViewHolder holder, int position) {
        holder.bind(tracks.get(position), listener);
    }

    @Override
    public int getItemCount() {
        return tracks.size();
    }

    static class TrackViewHolder extends RecyclerView.ViewHolder {
        private final ItemTrackBinding binding;

        TrackViewHolder(ItemTrackBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
        }

        void bind(final Track track, final OnTrackClickListener listener) {
            binding.txtTitle.setText(track.getTitle());
            binding.txtArtist.setText(track.getArtist());
            Glide.with(binding.getRoot().getContext())
                    .load(track.getArtworkUrl())
                    .centerCrop()
                    .into(binding.imgArt);
            binding.getRoot().setOnClickListener(v -> listener.onTrackClick(track));
        }
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/fragments/BaseListFragment.java": """
package com.tunebridge.nativeapp.fragments;

import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.tunebridge.nativeapp.adapters.TrackAdapter;
import com.tunebridge.nativeapp.databinding.FragmentListBinding;
import com.tunebridge.nativeapp.models.Track;

import java.util.ArrayList;
import java.util.List;

public abstract class BaseListFragment extends Fragment {

    public interface Host {
        void onTrackSelected(Track track);
    }

    private FragmentListBinding binding;
    private Host host;

    protected abstract String header();
    protected abstract String prefix();

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (context instanceof Host) {
            host = (Host) context;
        }
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentListBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        binding.txtHeader.setText(header());
        binding.recyclerTracks.setHasFixedSize(true);
        binding.recyclerTracks.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.recyclerTracks.setNestedScrollingEnabled(false);

        TrackAdapter adapter = new TrackAdapter(mockTracks(), track -> {
            if (host != null) {
                host.onTrackSelected(track);
            }
        });
        binding.recyclerTracks.setAdapter(adapter);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding.recyclerTracks.setAdapter(null);
        binding = null;
    }

    private List<Track> mockTracks() {
        List<Track> list = new ArrayList<>();
        for (int i = 1; i <= 40; i++) {
            list.add(new Track(
                    prefix() + "_" + i,
                    prefix() + " Track " + i,
                    "Artist " + i,
                    "https://picsum.photos/200/200?random=" + (i + prefix().hashCode() % 100)
            ));
        }
        return list;
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/fragments/HomeFragment.java": """
package com.tunebridge.nativeapp.fragments;

public class HomeFragment extends BaseListFragment {
    @Override
    protected String header() {
        return "Home";
    }

    @Override
    protected String prefix() {
        return "Home";
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/fragments/SearchFragment.java": """
package com.tunebridge.nativeapp.fragments;

public class SearchFragment extends BaseListFragment {
    @Override
    protected String header() {
        return "Search";
    }

    @Override
    protected String prefix() {
        return "Search";
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/fragments/LibraryFragment.java": """
package com.tunebridge.nativeapp.fragments;

public class LibraryFragment extends BaseListFragment {
    @Override
    protected String header() {
        return "Library";
    }

    @Override
    protected String prefix() {
        return "Library";
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/fragments/FullPlayerFragment.java": """
package com.tunebridge.nativeapp.fragments;

import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.bumptech.glide.Glide;
import com.tunebridge.nativeapp.databinding.FragmentFullPlayerBinding;

public class FullPlayerFragment extends Fragment {

    public interface Callback {
        void onClosePlayer();
    }

    private static final String ARG_TITLE = "title";
    private static final String ARG_ARTIST = "artist";
    private static final String ARG_ART = "art";

    public static FullPlayerFragment newInstance(String title, String artist, String art) {
        Bundle args = new Bundle();
        args.putString(ARG_TITLE, title);
        args.putString(ARG_ARTIST, artist);
        args.putString(ARG_ART, art);
        FullPlayerFragment fragment = new FullPlayerFragment();
        fragment.setArguments(args);
        return fragment;
    }

    private FragmentFullPlayerBinding binding;
    private Callback callback;
    private boolean isPlaying = true;

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (context instanceof Callback) {
            callback = (Callback) context;
        }
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentFullPlayerBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        Bundle args = getArguments();
        if (args != null) {
            binding.txtFullTitle.setText(args.getString(ARG_TITLE, ""));
            binding.txtFullArtist.setText(args.getString(ARG_ARTIST, ""));
            Glide.with(this).load(args.getString(ARG_ART, "")).centerCrop().into(binding.imgFullArt);
        }

        binding.btnClose.setOnClickListener(v -> {
            if (callback != null) {
                callback.onClosePlayer();
            }
        });

        binding.btnPlay.setOnClickListener(v -> {
            isPlaying = !isPlaying;
            binding.btnPlay.setImageResource(
                    isPlaying ? android.R.drawable.ic_media_pause : android.R.drawable.ic_media_play);
            binding.btnPlay.animate().scaleX(0.92f).scaleY(0.92f).setDuration(120)
                    .withEndAction(() -> binding.btnPlay.animate().scaleX(1f).scaleY(1f).setDuration(120).start())
                    .start();
        });

        binding.btnPrev.setOnClickListener(v ->
                v.animate().translationX(-8f).setDuration(120)
                        .withEndAction(() -> v.animate().translationX(0f).setDuration(120).start())
                        .start());

        binding.btnNext.setOnClickListener(v ->
                v.animate().translationX(8f).setDuration(120)
                        .withEndAction(() -> v.animate().translationX(0f).setDuration(120).start())
                        .start());
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
""",
    "app/src/main/java/com/tunebridge/nativeapp/activities/MainActivity.java": """
package com.tunebridge.nativeapp.activities;

import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.bumptech.glide.Glide;
import com.tunebridge.nativeapp.R;
import com.tunebridge.nativeapp.databinding.ActivityMainBinding;
import com.tunebridge.nativeapp.fragments.BaseListFragment;
import com.tunebridge.nativeapp.fragments.FullPlayerFragment;
import com.tunebridge.nativeapp.fragments.HomeFragment;
import com.tunebridge.nativeapp.fragments.LibraryFragment;
import com.tunebridge.nativeapp.fragments.SearchFragment;
import com.tunebridge.nativeapp.models.Track;

public class MainActivity extends AppCompatActivity
        implements BaseListFragment.Host, FullPlayerFragment.Callback {

    private ActivityMainBinding binding;
    private Track currentTrack;
    private boolean isPlaying;
    private boolean playerVisible;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        bindMiniPlayer();
        setupBottomNavigation();

        if (savedInstanceState == null) {
            switchContent(new HomeFragment());
        }
    }

    private void setupBottomNavigation() {
        binding.bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                switchContent(new HomeFragment());
                return true;
            }
            if (id == R.id.nav_search) {
                switchContent(new SearchFragment());
                return true;
            }
            if (id == R.id.nav_library) {
                switchContent(new LibraryFragment());
                return true;
            }
            return false;
        });
    }

    private void bindMiniPlayer() {
        binding.miniPlayer.btnMiniPlay.setOnClickListener(v -> {
            isPlaying = !isPlaying;
            binding.miniPlayer.btnMiniPlay.setImageResource(
                    isPlaying ? android.R.drawable.ic_media_pause : android.R.drawable.ic_media_play);
        });

        binding.miniPlayer.getRoot().setOnClickListener(v -> {
            if (currentTrack != null) {
                showFullPlayer(currentTrack);
            }
        });
    }

    private void switchContent(@NonNull Fragment fragment) {
        getSupportFragmentManager().beginTransaction()
                .setCustomAnimations(R.anim.fade_in, R.anim.fade_out)
                .replace(R.id.content_host, fragment)
                .commit();
    }

    @Override
    public void onTrackSelected(Track track) {
        currentTrack = track;
        isPlaying = true;

        binding.miniPlayer.txtMiniTitle.setText(track.getTitle());
        binding.miniPlayer.txtMiniArtist.setText(track.getArtist());
        binding.miniPlayer.btnMiniPlay.setImageResource(android.R.drawable.ic_media_pause);

        Glide.with(this)
                .load(track.getArtworkUrl())
                .centerCrop()
                .into(binding.miniPlayer.imgMiniArt);
    }

    private void showFullPlayer(@NonNull Track track) {
        if (playerVisible) {
            return;
        }
        playerVisible = true;
        binding.playerHost.setVisibility(View.VISIBLE);
        binding.playerHost.setAlpha(0f);
        binding.playerHost.setTranslationY(90f);

        getSupportFragmentManager().beginTransaction()
                .replace(R.id.player_host,
                        FullPlayerFragment.newInstance(track.getTitle(), track.getArtist(), track.getArtworkUrl()))
                .commitNow();

        binding.playerHost.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(220)
                .start();
    }

    @Override
    public void onClosePlayer() {
        if (!playerVisible) {
            return;
        }
        playerVisible = false;
        binding.playerHost.animate()
                .alpha(0f)
                .translationY(90f)
                .setDuration(200)
                .withEndAction(() -> {
                    getSupportFragmentManager().beginTransaction()
                            .remove(getSupportFragmentManager().findFragmentById(R.id.player_host))
                            .commitAllowingStateLoss();
                    binding.playerHost.setVisibility(View.GONE);
                })
                .start();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        binding = null;
    }
}
""",
}

shutil.rmtree(ROOT, ignore_errors=True)

for relative_path, content in files.items():
    absolute_path = os.path.join(ROOT, relative_path.replace("/", os.sep))
    os.makedirs(os.path.dirname(absolute_path), exist_ok=True)
    with open(absolute_path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")

gradlew_src = os.path.join(WRAPPER_SOURCE, "gradlew")
gradlew_bat_src = os.path.join(WRAPPER_SOURCE, "gradlew.bat")
wrapper_src = os.path.join(WRAPPER_SOURCE, "gradle", "wrapper")

if os.path.exists(gradlew_src):
    shutil.copy2(gradlew_src, os.path.join(ROOT, "gradlew"))

if os.path.exists(gradlew_bat_src):
    shutil.copy2(gradlew_bat_src, os.path.join(ROOT, "gradlew.bat"))

if os.path.exists(wrapper_src):
    shutil.copytree(wrapper_src, os.path.join(ROOT, "gradle", "wrapper"), dirs_exist_ok=True)

print(f"Generated project at: {ROOT}")
