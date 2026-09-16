import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backend_api.dart';

/// Persistent, app-private storage for books the user has already opened or
/// explicitly saved for offline reading. Files are written through a `.part`
/// path and renamed only after the complete response is present.
class BookOfflineStore {
  BookOfflineStore._();

  static final instance = BookOfflineStore._();

  Future<Directory> _booksDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'mizan_books'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _bookDirectory(int bookId) async {
    final root = await _booksDirectory();
    final directory = Directory(p.join(root.path, '$bookId'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<void> saveCatalog(List<BookRead> books) async {
    final root = await _booksDirectory();
    final temporary = File(p.join(root.path, 'catalog.json.part'));
    final target = File(p.join(root.path, 'catalog.json'));
    await temporary.writeAsString(
      jsonEncode(books.map((book) => book.toJson()).toList()),
      flush: true,
    );
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
  }

  Future<List<BookRead>?> loadCatalog() async {
    final root = await _booksDirectory();
    final file = File(p.join(root.path, 'catalog.json'));
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => BookRead.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDetail(BookDetail book) async {
    final directory = await _bookDirectory(book.id);
    final temporary = File(p.join(directory.path, 'detail.json.part'));
    final target = File(p.join(directory.path, 'detail.json'));
    await temporary.writeAsString(jsonEncode(book.toJson()), flush: true);
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
  }

  Future<BookDetail?> loadDetail(int bookId) async {
    final directory = await _bookDirectory(bookId);
    final file = File(p.join(directory.path, 'detail.json'));
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      return BookDetail.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<File?> existingContent(int bookId, String format) async {
    final extension = _extensionFor(format);
    if (extension == null) return null;
    final directory = await _bookDirectory(bookId);
    final file = File(p.join(directory.path, 'content.$extension'));
    return await _isValidFile(file, extension) ? file : null;
  }

  Future<File> downloadContent({
    required int bookId,
    required String url,
    required String format,
  }) async {
    final extension = _extensionFor(format);
    if (extension == null) {
      throw StateError('This book format cannot be stored for offline reading.');
    }
    final cached = await existingContent(bookId, format);
    if (cached != null) return cached;

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(minutes: 3));
    if (response.statusCode >= 400 || response.bodyBytes.isEmpty) {
      throw StateError('Could not download this book for offline reading.');
    }

    final directory = await _bookDirectory(bookId);
    final temporary = File(p.join(directory.path, 'content.$extension.part'));
    final target = File(p.join(directory.path, 'content.$extension'));
    await temporary.writeAsBytes(response.bodyBytes, flush: true);
    if (!await _isValidFile(temporary, extension)) {
      await temporary.delete().catchError((_) => temporary);
      throw StateError('The downloaded book appears incomplete.');
    }
    if (await target.exists()) await target.delete();
    return temporary.rename(target.path);
  }

  Future<File> cachePage({
    required BookPageRead page,
    required String url,
  }) async {
    final extension =
        page.imageType?.toLowerCase().contains('png') == true ? 'png' : 'jpg';
    final directory = await _bookDirectory(page.bookId);
    final target = File(p.join(directory.path, 'page_${page.pageNumber}.$extension'));
    if (await _isValidFile(target, extension)) return target;

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 45));
    if (response.statusCode >= 400 || response.bodyBytes.isEmpty) {
      throw StateError('This page is not available offline yet.');
    }
    final temporary = File('${target.path}.part');
    await temporary.writeAsBytes(response.bodyBytes, flush: true);
    if (!await _isValidFile(temporary, extension)) {
      await temporary.delete().catchError((_) => temporary);
      throw StateError('This page download appears incomplete.');
    }
    if (await target.exists()) await target.delete();
    return temporary.rename(target.path);
  }

  Future<File?> existingPage(BookPageRead page) async {
    final directory = await _bookDirectory(page.bookId);
    final extension =
        page.imageType?.toLowerCase().contains('png') == true ? 'png' : 'jpg';
    final file = File(p.join(directory.path, 'page_${page.pageNumber}.$extension'));
    return await _isValidFile(file, extension) ? file : null;
  }

  Future<void> removeBook(int bookId) async {
    final root = await _booksDirectory();
    final directory = Directory(p.join(root.path, '$bookId'));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  String? _extensionFor(String format) {
    switch (format.toLowerCase().replaceFirst('.', '')) {
      case 'pdf':
        return 'pdf';
      case 'epub':
        return 'epub';
      default:
        return null;
    }
  }

  Future<bool> _isValidFile(File file, String extension) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 4) return false;
    try {
      final prefix = await file.openRead(0, 4).fold<List<int>>(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      );
      if (extension == 'pdf') {
        return prefix.length >= 4 &&
            prefix[0] == 0x25 &&
            prefix[1] == 0x50 &&
            prefix[2] == 0x44 &&
            prefix[3] == 0x46;
      }
      if (extension == 'epub') {
        return prefix.length >= 2 && prefix[0] == 0x50 && prefix[1] == 0x4b;
      }
      return prefix.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
