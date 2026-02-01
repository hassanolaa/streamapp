// lib/features/videos/presentation/managers/video_focus_manager.dart

import 'package:flutter/material.dart';

class VideoFocusManager extends ChangeNotifier {
  int _currentCatalogIndex = 0;
  int _currentVideoIndex = 0;
  int _totalCatalogs = 0;
  List<int> _catalogSizes = [];

  int get currentCatalogIndex => _currentCatalogIndex;
  int get currentVideoIndex => _currentVideoIndex;

  void initialize(List<int> catalogSizes) {
    _catalogSizes = catalogSizes;
    _totalCatalogs = catalogSizes.length;
    _currentCatalogIndex = 0;
    _currentVideoIndex = 0;
    notifyListeners();
  }

  void moveRight() {
    if (_currentCatalogIndex >= _catalogSizes.length || _catalogSizes.isEmpty) return;
    
    final maxIndex = _catalogSizes[_currentCatalogIndex] - 1;
    if (_currentVideoIndex < maxIndex) {
      _currentVideoIndex++;
      notifyListeners();
    }
  }

  void moveLeft() {
    if (_currentVideoIndex > 0) {
      _currentVideoIndex--;
      notifyListeners();
    }
  }

  void moveDown() {
    if (_currentCatalogIndex < _totalCatalogs - 1) {
      _currentCatalogIndex++;
      // Keep same horizontal position if possible, otherwise go to last item
      if (_currentCatalogIndex < _catalogSizes.length) {
        final newMaxIndex = _catalogSizes[_currentCatalogIndex] - 1;
        if (_currentVideoIndex > newMaxIndex) {
          _currentVideoIndex = newMaxIndex;
        }
      }
      notifyListeners();
    }
  }

  void moveUp() {
    if (_currentCatalogIndex > 0) {
      _currentCatalogIndex--;
      // Keep same horizontal position if possible, otherwise go to last item
      if (_currentCatalogIndex < _catalogSizes.length) {
        final newMaxIndex = _catalogSizes[_currentCatalogIndex] - 1;
        if (_currentVideoIndex > newMaxIndex) {
          _currentVideoIndex = newMaxIndex;
        }
      }
      notifyListeners();
    }
  }

  void selectVideo(int catalogIndex, int videoIndex) {
    if (catalogIndex >= 0 && catalogIndex < _totalCatalogs) {
      _currentCatalogIndex = catalogIndex;
      if (catalogIndex < _catalogSizes.length) {
        final maxIndex = _catalogSizes[catalogIndex] - 1;
        _currentVideoIndex = videoIndex.clamp(0, maxIndex);
      }
      notifyListeners();
    }
  }

  bool isFocused(int catalogIndex, int videoIndex) {
    return _currentCatalogIndex == catalogIndex && 
           _currentVideoIndex == videoIndex;
  }

  bool isCatalogFocused(int catalogIndex) {
    return _currentCatalogIndex == catalogIndex;
  }
}
