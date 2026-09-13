import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/backend_api.dart';

class AdminCharitiesScreen extends StatefulWidget {
  const AdminCharitiesScreen({super.key});

  @override
  State<AdminCharitiesScreen> createState() => _AdminCharitiesScreenState();
}

class _AdminCharitiesScreenState extends State<AdminCharitiesScreen> {
  late Future<AdminCharityPage> _future = _load();
  final Set<int> _busy = {};

  Future<AdminCharityPage> _load() =>
      BackendApi.instance.getAdminCharities(limit: 100, offset: 0);
  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm({AdminCharityRecord? donation}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DonationEditorSheet(donation: donation),
    );
    if (saved == true && mounted) _refresh();
  }

  Future<void> _upload(
    AdminCharityRecord donation, {
    required bool evidence,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions:
          evidence
              ? const ['jpg', 'jpeg', 'png', 'pdf']
              : const ['jpg', 'jpeg', 'png'],
    );
    if (result == null) return;
    final files =
        result.files
            .where((file) => file.bytes != null)
            .map(
              (file) =>
                  PickedUploadFile(filename: file.name, bytes: file.bytes!),
            )
            .toList();
    if (files.isEmpty) return;
    setState(() => _busy.add(donation.id));
    try {
      if (evidence) {
        await BackendApi.instance.uploadAdminCharityEvidence(
          charityId: donation.id,
          files: files,
        );
      } else {
        await BackendApi.instance.uploadAdminCharityImages(
          charityId: donation.id,
          files: files,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(evidence ? 'Evidence uploaded.' : 'Images uploaded.'),
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: context.colors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy.remove(donation.id));
    }
  }

  Future<void> _clearMedia(
    AdminCharityRecord donation, {
    required bool evidence,
  }) async {
    final count =
        evidence ? donation.evidenceUrls.length : donation.imageUrls.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              evidence ? 'Remove evidence files?' : 'Remove images?',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              evidence
                  ? 'This removes $count evidence file${count == 1 ? '' : 's'} from this campaign.'
                  : 'This removes $count image${count == 1 ? '' : 's'} from this campaign.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    setState(() => _busy.add(donation.id));
    try {
      await BackendApi.instance.updateAdminCharity(
        charityId: donation.id,
        imageUrls: evidence ? null : const [],
        evidenceUrls: evidence ? const [] : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(evidence ? 'Evidence removed.' : 'Images removed.'),
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove files: $e'),
            backgroundColor: context.colors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy.remove(donation.id));
    }
  }

  Future<void> _confirmDelete(AdminCharityRecord donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Close donation?',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              donation.isPublished
                  ? 'This campaign is published. Closing it will remove it from the public donation list.'
                  : 'Close "${donation.displayTitle}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await BackendApi.instance.deleteAdminCharity(donation.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Donation closed.')));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'Donations',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<AdminCharityPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          if (snapshot.hasError)
            return _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load donations',
              body: 'Check your connection and try again.',
            );
          final donations = snapshot.data?.data ?? [];
          if (donations.isEmpty)
            return const _EmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No donations yet',
              body:
                  'Create a personal case or link to a verified external campaign.',
            );
          return LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 780;
              return GridView.builder(
                padding: const EdgeInsets.all(18),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoColumns ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 292,
                ),
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  final donation = donations[index];
                  return _DonationAdminCard(
                    donation: donation,
                    busy: _busy.contains(donation.id),
                    onEdit: () => _openForm(donation: donation),
                    onDelete: () => _confirmDelete(donation),
                    onImages: () => _upload(donation, evidence: false),
                    onEvidence: () => _upload(donation, evidence: true),
                    onClearImages: () => _clearMedia(donation, evidence: false),
                    onClearEvidence:
                        () => _clearMedia(donation, evidence: true),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Donation'),
      ),
    );
  }
}

class _DonationEditorSheet extends StatefulWidget {
  const _DonationEditorSheet({this.donation});

  final AdminCharityRecord? donation;

  @override
  State<_DonationEditorSheet> createState() => _DonationEditorSheetState();
}

class _DonationEditorSheetState extends State<_DonationEditorSheet> {
  late final _name = TextEditingController(text: widget.donation?.name ?? '');
  late final _title = TextEditingController(text: widget.donation?.title ?? '');
  late final _caseName = TextEditingController(
    text: widget.donation?.caseName ?? '',
  );
  late final _description = TextEditingController(
    text: widget.donation?.description ?? '',
  );
  late final _url = TextEditingController(
    text:
        widget.donation?.externalUrl?.isNotEmpty == true
            ? widget.donation!.externalUrl!
            : widget.donation?.websiteUrl ?? '',
  );
  late final _category = TextEditingController(
    text: widget.donation?.category ?? '',
  );
  late final _target = TextEditingController(
    text: widget.donation?.targetAmount?.toStringAsFixed(0) ?? '',
  );
  late final _raised = TextEditingController(
    text: widget.donation?.amountRaised?.toStringAsFixed(0) ?? '',
  );
  late final _currency = TextEditingController(
    text: widget.donation?.currency ?? 'NGN',
  );
  late final _evidence = TextEditingController(
    text: widget.donation?.evidence ?? '',
  );
  late final _contact = TextEditingController(
    text: widget.donation?.contactInfo ?? '',
  );
  late final _deadline = TextEditingController(
    text: widget.donation?.deadline ?? '',
  );
  late String _type = widget.donation?.donationType ?? 'external';
  late String _status = widget.donation?.status ?? 'active';
  late bool _published = widget.donation?.isPublished ?? true;
  late bool _verified = widget.donation?.isVerified ?? true;
  late bool _featured = widget.donation?.isFeatured ?? false;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _title,
      _caseName,
      _description,
      _url,
      _category,
      _target,
      _raised,
      _currency,
      _evidence,
      _contact,
      _deadline,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final title = _title.text.trim();
    final url = _url.text.trim();
    if (name.isEmpty || title.isEmpty || (_type == 'external' && url.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Name, title, and external URL where needed are required.',
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.donation == null) {
        await BackendApi.instance.createAdminCharity(
          name: name,
          title: title,
          donationType: _type,
          websiteUrl: url.isEmpty ? null : url,
          caseName:
              _caseName.text.trim().isEmpty ? null : _caseName.text.trim(),
          description:
              _description.text.trim().isEmpty
                  ? null
                  : _description.text.trim(),
          category:
              _category.text.trim().isEmpty ? null : _category.text.trim(),
          targetAmount: double.tryParse(_target.text.trim()),
          amountRaised: double.tryParse(_raised.text.trim()),
          currency:
              _currency.text.trim().isEmpty ? 'NGN' : _currency.text.trim(),
          evidence:
              _evidence.text.trim().isEmpty ? null : _evidence.text.trim(),
          contactInfo:
              _contact.text.trim().isEmpty ? null : _contact.text.trim(),
          status: _status,
          deadline:
              _deadline.text.trim().isEmpty ? null : _deadline.text.trim(),
          isPublished: _published,
          isFeatured: _featured,
        );
      } else {
        await BackendApi.instance.updateAdminCharity(
          charityId: widget.donation!.id,
          name: name,
          title: title,
          donationType: _type,
          websiteUrl: url.isEmpty ? null : url,
          caseName: _caseName.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          targetAmount: double.tryParse(_target.text.trim()),
          amountRaised: double.tryParse(_raised.text.trim()),
          currency:
              _currency.text.trim().isEmpty ? 'NGN' : _currency.text.trim(),
          evidence: _evidence.text.trim(),
          contactInfo: _contact.text.trim(),
          status: _status,
          deadline:
              _deadline.text.trim().isEmpty ? null : _deadline.text.trim(),
          isPublished: _published,
          isVerified: _verified,
          isActive: true,
          isFeatured: _featured,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save donation: $e'),
            backgroundColor: context.colors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.65,
      maxChildSize: 0.98,
      builder:
          (context, controller) => Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.donation == null ? 'New Donation' : 'Edit Donation',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'external',
                      label: Text('External'),
                      icon: Icon(Icons.open_in_new_rounded),
                    ),
                    ButtonSegment(
                      value: 'personal',
                      label: Text('Personal'),
                      icon: Icon(Icons.favorite_border_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged:
                      (value) => setState(() => _type = value.first),
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _title,
                  label: 'Donation title',
                  icon: Icons.campaign_outlined,
                ),
                _Field(
                  controller: _name,
                  label:
                      _type == 'personal'
                          ? 'Person or case name'
                          : 'Organization or campaign name',
                  icon: Icons.badge_outlined,
                ),
                if (_type == 'personal')
                  _Field(
                    controller: _caseName,
                    label: 'Case name',
                    icon: Icons.person_outline_rounded,
                  ),
                if (_type == 'external')
                  _Field(
                    controller: _url,
                    label: 'External donation URL',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                  ),
                _Field(
                  controller: _category,
                  label: 'Category',
                  icon: Icons.category_outlined,
                ),
                _Field(
                  controller: _description,
                  label: 'Description or story',
                  icon: Icons.notes_rounded,
                  maxLines: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _target,
                        label: 'Target amount',
                        icon: Icons.flag_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        controller: _raised,
                        label: 'Amount raised',
                        icon: Icons.savings_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _currency,
                        label: 'Currency',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        controller: _deadline,
                        label: 'Deadline YYYY-MM-DD',
                        icon: Icons.event_outlined,
                      ),
                    ),
                  ],
                ),
                _Field(
                  controller: _evidence,
                  label: 'Evidence or supporting info',
                  icon: Icons.verified_outlined,
                  maxLines: 3,
                ),
                _Field(
                  controller: _contact,
                  label: 'Contact or relevant info',
                  icon: Icons.contact_mail_outlined,
                  maxLines: 3,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.tune_rounded, color: colors.primary),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'goal_reached',
                      child: Text('Goal reached'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged:
                      (value) => setState(() => _status = value ?? 'active'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _published,
                  onChanged: (value) => setState(() => _published = value),
                  title: const Text('Published'),
                  subtitle: const Text('Visible on the user donation page'),
                ),
                SwitchListTile(
                  value: _verified,
                  onChanged: (value) => setState(() => _verified = value),
                  title: const Text('Verified'),
                  subtitle: const Text(
                    'Trusted and allowed to appear when published',
                  ),
                ),
                SwitchListTile(
                  value: _featured,
                  onChanged: (value) => setState(() => _featured = value),
                  title: const Text('Featured'),
                  subtitle: const Text('Give it visual priority'),
                ),
                const SizedBox(height: 12),
                if (_saving) LinearProgressIndicator(color: colors.primary),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save donation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _DonationAdminCard extends StatelessWidget {
  const _DonationAdminCard({
    required this.donation,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onImages,
    required this.onEvidence,
    required this.onClearImages,
    required this.onClearEvidence,
  });

  final AdminCharityRecord donation;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onImages;
  final VoidCallback onEvidence;
  final VoidCallback onClearImages;
  final VoidCallback onClearEvidence;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 58,
                  height: 58,
                  color: colors.primaryContainer,
                  child:
                      donation.imageUrls.isEmpty
                          ? Icon(
                            Icons.volunteer_activism_outlined,
                            color: colors.primary,
                          )
                          : Image.network(
                            donation.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Icon(
                                  Icons.volunteer_activism_outlined,
                                  color: colors.primary,
                                ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      donation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(donation.donationType, colors.primary),
                        _Chip(
                          donation.statusLabel,
                          _statusColor(colors, donation.status),
                        ),
                        _Chip(
                          donation.isPublished ? 'Published' : 'Draft',
                          donation.isPublished ? colors.success : colors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (donation.targetAmount != null) ...[
            const SizedBox(height: 12),
            _Progress(donation: donation),
          ],
          if (busy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(color: colors.primary),
          ],
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onImages,
                icon: Icon(Icons.photo_library_outlined, color: colors.success),
                tooltip: 'Add images',
              ),
              if (donation.imageUrls.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClearImages,
                  icon: Icon(Icons.hide_image_outlined, color: colors.error),
                  tooltip: 'Remove images',
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEvidence,
                icon: Icon(Icons.verified_outlined, color: colors.primary),
                tooltip: 'Add evidence',
              ),
              if (donation.evidenceUrls.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClearEvidence,
                  icon: Icon(Icons.remove_done_outlined, color: colors.error),
                  tooltip: 'Remove evidence',
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: colors.error),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on AdminCharityRecord {
  String get displayTitle =>
      (title?.trim().isNotEmpty == true ? title!.trim() : name);
  String get statusLabel => status.replaceAll('_', ' ');
}

Color _statusColor(MizanColors colors, String status) {
  return switch (status) {
    'active' => colors.success,
    'goal_reached' => colors.primary,
    'completed' => colors.accent,
    _ => colors.error,
  };
}

class _Progress extends StatelessWidget {
  const _Progress({required this.donation});

  final AdminCharityRecord donation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final target = donation.targetAmount ?? 0;
    final raised = donation.amountRaised ?? 0;
    final pct = target <= 0 ? 0.0 : (raised / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            color: colors.primary,
            backgroundColor: colors.primaryContainer,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${donation.currencySymbol}${raised.toStringAsFixed(0)} / ${donation.currencySymbol}${target.toStringAsFixed(0)}',
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        if (target > raised) ...[
          const SizedBox(height: 3),
          Text(
            '${donation.currencySymbol}${(target - raised).toStringAsFixed(0)} remaining',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

extension _Currency on AdminCharityRecord {
  String get currencySymbol =>
      currency.toUpperCase() == 'NGN' ? '₦' : '$currency ';
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Georgia',
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
