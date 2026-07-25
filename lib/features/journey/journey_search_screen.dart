import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'journey_search_data.dart';

class JourneySearchScreen extends StatefulWidget {
  const JourneySearchScreen({super.key, this.onResultSelected});

  final void Function(JourneySearchResult)? onResultSelected;

  @override
  State<JourneySearchScreen> createState() => _JourneySearchScreenState();
}

class _JourneySearchScreenState extends State<JourneySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<JourneySearchResult> _results = const [];
  bool _isSearching = false;
  static const _recentKey = 'mizan.journey.search.recent';
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    JourneySearchIndex.build();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recent = prefs.getStringList(_recentKey) ?? const [];
    });
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [query, ..._recent.where((r) => r != query).take(9)];
    _recent = updated;
    await prefs.setStringList(_recentKey, updated);
  }

  void _onQueryChanged(String value) {
    if (value.isEmpty) {
      setState(() { _results = const []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final results = JourneySearchIndex.search(_controller.text);
      setState(() { _results = results; _isSearching = false; });
    });
  }

  void _clear() {
    _controller.clear();
    setState(() { _results = const []; _isSearching = false; });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _results.isNotEmpty;
    final hasQuery = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE1),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF30241E)),
        ),
        titleSpacing: 0,
        title: _SearchField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          onClear: _clear,
        ),
      ),
      body: hasResults
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              physics: const BouncingScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final result = _results[index];
                return _SearchResultTile(
                  result: result,
                  query: _controller.text,
                  onTap: () {
                    widget.onResultSelected?.call(result);
                    Navigator.of(context).pop();
                  },
                );
              },
            )
          : hasQuery && _isSearching
              ? const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: Color(0xFF8B6842))))
              : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    if (_controller.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
          child: Column(children: [
            Icon(Icons.search_off_rounded, size: 64, color: const Color(0xFFE4D5C3)),
            const SizedBox(height: 20),
            Text('No results found', style: TextStyle(color: const Color(0xFF30241E), fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
            const SizedBox(height: 12),
            Text('Try a different spelling, search by category, or use an English translation or Arabic text.',
                textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF756457), fontSize: 14, height: 1.5)),
          ]),
        ),
      );
    }

    return Column(
      children: [
        if (_recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              Text('Recent', style: TextStyle(color: const Color(0xFF92704B), fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_recentKey);
                setState(() => _recent = const []);
              }, child: Text('Clear', style: TextStyle(color: const Color(0xFF8B6842), fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final query = _recent[index];
                return Material(
                  color: const Color(0xFFFFFBF6),
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.history_rounded, color: Color(0xFF8B6842), size: 20),
                    title: Text(query, style: const TextStyle(color: Color(0xFF30241E), fontSize: 15)),
                    onTap: () {
                      _controller.text = query;
                      _onQueryChanged(query);
                      _saveRecent(query);
                    },
                  ),
                );
              },
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
                child: Column(children: [
                  Icon(Icons.search_rounded, size: 64, color: const Color(0xFFE4D5C3)),
                  const SizedBox(height: 20),
                  Text('Search Journey', style: TextStyle(color: const Color(0xFF30241E), fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
                  const SizedBox(height: 12),
                  Text('Search across adhkar, reflections, and readings by Arabic, translation, or transliteration.',
                      textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF756457), fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                    _SuggestionChip(label: 'Ayat al-Kursi', onTap: () { _controller.text = 'Ayat al-Kursi'; _onQueryChanged('Ayat al-Kursi'); _saveRecent('Ayat al-Kursi'); }),
                    _SuggestionChip(label: 'Morning', onTap: () { _controller.text = 'Morning'; _onQueryChanged('Morning'); _saveRecent('Morning'); }),
                    _SuggestionChip(label: 'Protection', onTap: () { _controller.text = 'Protection'; _onQueryChanged('Protection'); _saveRecent('Protection'); }),
                    _SuggestionChip(label: 'SubhanAllah', onTap: () { _controller.text = 'SubhanAllah'; _onQueryChanged('SubhanAllah'); _saveRecent('SubhanAllah'); }),
                    _SuggestionChip(label: 'Travel', onTap: () { _controller.text = 'Travel'; _onQueryChanged('Travel'); _saveRecent('Travel'); }),
                  ]),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: hasText ? const Color(0xFFFFFBF6) : const Color(0xFFF0E3D4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: hasText ? const Color(0xFF8B6842) : Colors.transparent, width: 1.5),
      ),
      child: Row(children: [
        const Padding(padding: EdgeInsets.only(left: 14), child: Icon(Icons.search_rounded, color: Color(0xFF8B6842), size: 20)),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search adhkar, reflections...',
              hintStyle: const TextStyle(color: Color(0xFF8F7B6B), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(color: Color(0xFF30241E), fontSize: 15),
          ),
        ),
        if (hasText)
          IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, color: Color(0xFF8B6842), size: 18), tooltip: 'Clear', splashRadius: 18),
      ]),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.query, required this.onTap});
  final JourneySearchResult result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlightedTitle = _highlight(result.title, query);
    final highlightedSubtitle = _highlight(result.subtitle, query);

    return Material(
      color: const Color(0xFFFFFBF6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(99)),
                child: Text(result.category, style: const TextStyle(color: Color(0xFF8B6842), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              if (result.commonName != null && result.commonName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFDCE7D8), borderRadius: BorderRadius.circular(99)),
                  child: Text(result.commonName!, style: const TextStyle(color: Color(0xFF58705C), fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 10),
            if (result.arabic != null && result.arabic!.isNotEmpty)
              Text(result.arabic!, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF30241E), fontSize: 22, height: 1.6)),
            if (result.arabic != null && result.arabic!.isNotEmpty) const SizedBox(height: 8),
            Text(highlightedTitle, style: const TextStyle(color: Color(0xFF30241E), fontFamily: 'Georgia', fontSize: 17, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 4),
            Text(highlightedSubtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF756457), height: 1.5)),
            if (result.source != null && result.source!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(result.source!, style: const TextStyle(color: Color(0xFF8F7B6B), fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ]),
        ),
      ),
    );
  }

  String _highlight(String text, String query) {
    if (query.isEmpty) return text;
    final normalized = JourneySearchIndex.normalize(text);
    final normalizedQuery = JourneySearchIndex.normalize(query);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (normalizedQuery.isEmpty || !normalized.contains(normalizedQuery)) return text;

    final buffer = StringBuffer();
    int lastEnd = 0;
    final lowerNormalized = normalized;
    final start = lowerNormalized.indexOf(normalizedQuery);
    if (start == -1) return text;

    final originalStart = _originalIndex(text, start);
    buffer.write(lowerText.substring(lastEnd, originalStart));
    buffer.write('<b>');
    buffer.write(lowerText.substring(originalStart, originalStart + lowerQuery.length));
    buffer.write('</b>');
    lastEnd = originalStart + lowerQuery.length;

    buffer.write(lowerText.substring(lastEnd));
    return buffer.toString();
  }

  int _originalIndex(String original, int normalizedIndex) {
    int normCount = 0;
    for (int i = 0; i < original.length; i++) {
      final c = original[i];
      if ((c.codeUnitAt(0) >= 0x0600 && c.codeUnitAt(0) <= 0x06FF) ||
          (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) ||
          (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) ||
          c == ' ') {
        if (normCount == normalizedIndex) return i;
        normCount++;
      }
    }
    return original.length;
  }
}

class _SuggestionChip extends StatelessWidget { const _SuggestionChip({required this.label, required this.onTap}); final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(99), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF0E3D4), borderRadius: BorderRadius.circular(99)), child: Text(label, style: const TextStyle(color: Color(0xFF8B6842), fontSize: 13, fontWeight: FontWeight.w700)))); }
