import 'dart:async';

import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import 'act_detail_screen.dart';

class ActsLibraryScreen extends StatefulWidget {
  const ActsLibraryScreen({super.key});

  @override
  State<ActsLibraryScreen> createState() => _ActsLibraryScreenState();
}

class _ActsLibraryScreenState extends State<ActsLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _selectedCategory = 'All';

  Future<SadaqahActPage> _future = BackendApi.instance.getActs(limit: 100);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = value.trim().toLowerCase();
      });
    });
  }

  void _retry() {
    setState(() {
      _future = BackendApi.instance.getActs(limit: 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.90, 1.08);
    double s(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFEDECE6),
      appBar: AppBar(
        title: const Text('Acts Library'),
        backgroundColor: const Color(0xFFEDECE6),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(18), s(12), s(18), s(16)),
          child: FutureBuilder<SadaqahActPage>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorState(message: snapshot.error.toString(), onRetry: _retry);
              }

              final page = snapshot.data;
              final acts = page?.data ?? const <SadaqahActItem>[];
              if (page == null) {
                return _EmptyState(message: 'No acts available right now.', onRetry: _retry);
              }

              final categories = <String>{'All', ...acts.map((act) => act.category)};
              final filtered = acts.where((act) {
                final matchesCategory = _selectedCategory == 'All' || act.category == _selectedCategory;
                final matchesQuery = _query.isEmpty ||
                    act.title.toLowerCase().contains(_query) ||
                    act.category.toLowerCase().contains(_query);
                return matchesCategory && matchesQuery;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search acts',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF7F3ED),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(s(14)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: s(12)),
                  SizedBox(
                    height: s(42),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: s(8)),
                      itemBuilder: (context, index) {
                        final category = categories.elementAt(index);
                        final selected = category == _selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: s(10)),
                  Text(
                    page.total > acts.length ? 'Showing ${acts.length} acts from the catalog.' : 'Browse the current act catalog.',
                    style: TextStyle(color: const Color(0xFF6A5E52), fontSize: s(12)),
                  ),
                  SizedBox(height: s(10)),
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyState(
                            message: _query.isNotEmpty || _selectedCategory != 'All'
                                ? 'No acts match your filters.'
                                : 'No acts available yet.',
                            onRetry: _retry,
                            showRetry: false,
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => SizedBox(height: s(10)),
                            itemBuilder: (context, index) {
                              final act = filtered[index];
                              return _ActCard(
                                scale: scale,
                                act: act,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ActDetailScreen(actId: act.id)),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActCard extends StatelessWidget {
  const _ActCard({required this.scale, required this.act, required this.onTap});

  final double scale;
  final SadaqahActItem act;
  final VoidCallback onTap;

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3D5C7),
      borderRadius: BorderRadius.circular(s(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(14)),
        child: Padding(
          padding: EdgeInsets.all(s(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      act.title,
                      style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w700, color: const Color(0xFF2F2A28)),
                    ),
                  ),
                  _Badge(label: 'D${act.difficulty}', scale: scale),
                ],
              ),
              SizedBox(height: s(6)),
              Wrap(
                spacing: s(8),
                runSpacing: s(8),
                children: [
                  _Badge(label: act.category, scale: scale),
                  _Badge(label: 'Difficulty ${act.difficulty}', scale: scale),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      child: Text(label, style: TextStyle(fontSize: s(11), color: const Color(0xFF6A5E52), fontWeight: FontWeight.w600)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load acts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry, this.showRetry = true});

  final String message;
  final VoidCallback onRetry;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (showRetry) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

