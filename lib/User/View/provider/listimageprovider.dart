import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ImageProviderService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
  List<DocumentSnapshot> _documents = [];
  bool _isLoading = false;
  bool _hasMore = true;

  List<DocumentSnapshot> get documents => _documents;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchImages({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (refresh) {
        _documents.clear();
        _lastDocument = null;
        _hasMore = true;
      }

      Query query = _firestore
          .collectionGroup('images')
          .orderBy('timestamp', descending: true)
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      final newDocs = snapshot.docs;

      _documents.addAll(newDocs);
      _lastDocument = newDocs.isNotEmpty ? newDocs.last : null;
      _hasMore = newDocs.length == _limit;
    } catch (e) {
      print('Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}