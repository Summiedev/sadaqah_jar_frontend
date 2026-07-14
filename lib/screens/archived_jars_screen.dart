import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class ArchivedJarsScreen extends StatefulWidget {
  const ArchivedJarsScreen({super.key});

  @override
  State<ArchivedJarsScreen> createState() => _ArchivedJarsScreenState();
}

class _ArchivedJarsScreenState extends State<ArchivedJarsScreen> {
  static const int _pageSize = 12;

  final ScrollController _scrollController = ScrollController();
  final List<CompletedJarItem> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (_loadingMore) {
      return;
    }
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final page = await BackendApi.instance.getCompletedJars(limit: _pageSize, offset: _offset);
      if (!mounted) {
        return;
      }
      setState(() {
        _total = page.total;
        _offset = page.offset + page.data.length;
        _items.addAll(page.data);
        _hasMore = _items.length < page.total && page.data.isNotEmpty;
        _initialLoading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _hasMore = false;
        _initialLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !_hasMore || _loadingMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _loadPage();
    }
  }

  void _retry() {
    setState(() {
      _items.clear();
      _offset = 0;
      _total = 0;
      _hasMore = true;
      _error = null;
      _initialLoading = true;
    });
    _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFEDECE6),
      appBar: AppBar(
        title: const Text('Archived Jars'),
        backgroundColor: const Color(0xFFEDECE6),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s(18)),
          child: _initialLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _items.isEmpty
                  ? _StateMessage(message: 'Failed to load archived jars.', detail: _error!, onRetry: _retry)
                  : _items.isEmpty
                      ? const _StateMessage(message: 'No completed jars yet.', detail: 'When you finish a jar, it will appear here.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completed: $_total',
                              style: TextStyle(fontSize: s(13), color: const Color(0xFF6A5E52)),
                            ),
                            SizedBox(height: s(12)),
                            Expanded(
                              child: ListView.separated(
                                controller: _scrollController,
                                itemCount: _items.length + (_hasMore && _error == null ? 1 : 0),
                                separatorBuilder: (_, __) => SizedBox(height: s(10)),
                                itemBuilder: (context, index) {
                                  if (index >= _items.length) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: s(10)),
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final jar = _items[index];
                                  final sequence = _total - index;
                                  final badge = _badgeForSequence(sequence);
                                  return _JarCard(
                                    scale: scale,
                                    jar: jar,
                                    badgeLabel: badge,
                                    sequence: sequence,
                                  );
                                },
                              ),
                            ),
                            if (_error != null) ...[
                              SizedBox(height: s(8)),
                              TextButton(onPressed: _retry, child: const Text('Retry loading more')),
                            ],
                          ],
                        ),
        ),
      ),
    );
  }

  String? _badgeForSequence(int sequence) {
    const badges = <int, String>{
      1: 'First Jar Completed',
      5: '5 Jars Completed',
      10: '10 Jars Completed',
    };
    return badges[sequence];
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({required this.scale, required this.jar, required this.sequence, this.badgeLabel});

  final double scale;
  final CompletedJarItem jar;
  final int sequence;
  final String? badgeLabel;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3D5C7),
        borderRadius: BorderRadius.circular(s(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Completed jar #$sequence',
                  style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28)),
                ),
              ),
              Text('${jar.currentStars}/${jar.capacity}', style: TextStyle(fontSize: s(13), color: const Color(0xFF5A4D43))),
            ],
          ),
          SizedBox(height: s(8)),
          Text(
            'Completed on ${_formatDate(jar.completedAt)}',
            style: TextStyle(fontSize: s(13), color: const Color(0xFF5A4D43)),
          ),
          if (jar.daysToComplete != null) ...[
            SizedBox(height: s(4)),
            Text('${jar.daysToComplete} days to complete', style: TextStyle(fontSize: s(12), color: const Color(0xFF6A5E52))),
          ],
          if (badgeLabel != null) ...[
            SizedBox(height: s(10)),
            _Badge(label: badgeLabel!, scale: scale),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'unknown date';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.scale});

  final String label;
  final double scale;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(5)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: s(11), color: const Color(0xFF6A5E52), fontWeight: FontWeight.w700)),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.detail, this.onRetry});

  final String message;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
