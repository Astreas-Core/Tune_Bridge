import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'dart:async';

import 'package:tune_bridge/core/models/playlist_model.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _log = Logger();
  
  bool _isSyncing = false;
  StreamSubscription? _likesSubscription;
  StreamSubscription? _playlistsSubscription;

  void startSync() {
    if (_auth.currentUser == null) return;
    _isSyncing = true;
    _log.i("Firebase sync started for user: ${_auth.currentUser!.uid}");
    
    // Listen for changes from Cloud and update LocalLibraryService
    _likesSubscription?.cancel();
    _likesSubscription = _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('likes')
        .snapshots()
        .listen((snapshot) {
      final localLib = getIt<LocalLibraryService>();
      final Set<String> cloudIds = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        cloudIds.add(doc.id);
        
        final track = TrackModel(
          id: doc.id,
          title: data['title'] ?? 'Unknown',
          artist: data['artist'] ?? 'Unknown',
          albumName: data['albumName'] ?? 'Unknown',
          albumArtUrl: data['thumb'],
          durationMs: data['durationMs'] ?? 0,
          youtubeVideoId: data['id'],
        );
        
        // Add to local library if not already liked, or just forcefully update
        if (!localLib.isLiked(doc.id)) {
          localLib.addLikedSong(track, syncToCloud: false);
        }
      }
      
      // Handle deletions from cloud
      final localLikes = localLib.getLikedSongs();
      for (final local in localLikes) {
        if (!cloudIds.contains(local.id)) {
          localLib.removeLikedSong(local.id, syncToCloud: false);
        }
      }
    });

    // Listen for playlists from Cloud
    _playlistsSubscription?.cancel();
    _playlistsSubscription = _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('playlists')
        .snapshots()
        .listen((snapshot) async {
      final localLib = getIt<LocalLibraryService>();
      final Set<String> cloudPlaylistIds = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        cloudPlaylistIds.add(doc.id);
        
        final tracksData = data['tracks'] as List<dynamic>? ?? [];
        final tracks = tracksData.map((t) => TrackModel(
          id: t['id'],
          title: t['title'] ?? 'Unknown',
          artist: t['artist'] ?? 'Unknown',
          albumName: t['albumName'] ?? 'Unknown',
          albumArtUrl: t['thumb'],
          durationMs: t['durationMs'] ?? 0,
          youtubeVideoId: t['id'],
        )).toList();
        
        final playlist = PlaylistModel(
          id: doc.id,
          name: data['name'] ?? 'Untitled',
          imageUrl: data['coverUrl'],
          trackCount: tracks.length,
          ownerName: _auth.currentUser?.displayName ?? 'You',
        );
        
        // Save/Update locally
        await localLib.savePlaylist(playlist, tracks, syncToCloud: false);
      }
      
      // Handle deletions from cloud
      final localPlaylists = localLib.getPlaylists();
      for (final local in localPlaylists) {
        if (!cloudPlaylistIds.contains(local.id)) {
          await localLib.removePlaylist(local.id, syncToCloud: false);
        }
      }
    });
  }

  void stopSync() {
    _isSyncing = false;
    _likesSubscription?.cancel();
    _likesSubscription = null;
    _playlistsSubscription?.cancel();
    _playlistsSubscription = null;
    _log.i("Firebase sync stopped");
  }

  Future<void> uploadLikedSong(TrackModel track) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('likes')
          .doc(track.id)
          .set({
        'id': track.youtubeVideoId ?? track.id,
        'title': track.title,
        'artist': track.artist,
        'thumb': track.albumArtUrl, // Using albumArtUrl for backwards compatibility
        'durationMs': track.durationMs,
        'syncedAt': FieldValue.serverTimestamp(),
      });
      _log.i("Synced liked song: ${track.title}");
    } catch (e) {
      _log.e("Failed to sync liked song: $e");
    }
  }

  Future<void> updateTrackYoutubeId(String trackId, String youtubeId) async {
    if (_auth.currentUser == null) return;
    try {
      // We primarily update the 'likes' collection since most synced tracks exist there.
      // If it exists in a playlist but not likes, a full playlist update would be required,
      // but caching in likes is sufficient for the snapshot to catch it for most users.
      final docRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('likes')
          .doc(trackId);
          
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        await docRef.update({'id': youtubeId});
        _log.i("Cached resolved YouTube ID for track: $trackId -> $youtubeId");
      }
    } catch (e) {
      _log.e("Failed to cache YouTube ID: $e");
    }
  }

  Future<void> removeLikedSong(String trackId) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('likes')
          .doc(trackId)
          .delete();
      _log.i("Removed synced liked song: $trackId");
    } catch (e) {
      _log.e("Failed to remove synced liked song: $e");
    }
  }

  Future<void> uploadPlaylist(PlaylistModel playlist, List<TrackModel> tracks) async {
    if (_auth.currentUser == null) return;
    try {
      final tracksData = tracks.map((track) => {
        'id': track.youtubeVideoId ?? track.id,
        'title': track.title,
        'artist': track.artist,
        'albumName': track.albumName,
        'thumb': track.albumArtUrl,
        'durationMs': track.durationMs,
      }).toList();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('playlists')
          .doc(playlist.id)
          .set({
        'name': playlist.name,
        'source': 'tunebridge',
        'coverUrl': playlist.imageUrl ?? '',
        'tracks': tracksData,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log.i("Synced playlist: ${playlist.name}");
    } catch (e) {
      _log.e("Failed to sync playlist: $e");
    }
  }

  Future<void> removeSyncedPlaylist(String playlistId) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('playlists')
          .doc(playlistId)
          .delete();
      _log.i("Removed synced playlist: $playlistId");
    } catch (e) {
      _log.e("Failed to remove synced playlist: $e");
    }
  }
}