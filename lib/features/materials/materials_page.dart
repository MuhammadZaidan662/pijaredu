import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../tests/tests_repository.dart' show friendlyError;
import 'material_detail_page.dart';
import 'material_editor_page.dart';
import 'materials_repository.dart';

/// "Materials" tab (students) and "Content" tab (lecturers/admins).
class MaterialsPage extends StatefulWidget {
  const MaterialsPage({
    super.key,
    required this.role,
    this.embedded = false,
  });

  final String role;

  /// True when shown as a bottom-bar tab (no back button).
  final bool embedded;

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final _repo = MaterialsRepository.instance;

  List<MaterialItem> _materials = [];
  Set<int> _completed = {};
  bool _loading = true;
  String? _error;

  bool get _canManage => widget.role == 'lecturer' || widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repo.loadMaterials();
      var done = <int>{};
      if (!_canManage) {
        try {
          done = await _repo.loadCompletedIds();
        } catch (_) {
          // Progress is a bonus: the list still works without it.
        }
      }
      if (!mounted) return;
      setState(() {
        _materials = items;
        _completed = done;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _open(MaterialItem material) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialDetailPage(material: material, role: widget.role),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _add() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MaterialEditorPage()),
    );
    if (changed == true && mounted) _load();
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.textGrey),
              const SizedBox(height: 12),
              const Text(
                'Could not load materials.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _load,
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_materials.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.menu_book_outlined,
                size: 48, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _canManage
                    ? 'No materials yet. Tap "Add material".'
                    : 'No materials yet.',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, _canManage ? 96 : 24),
            itemCount: _materials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final material = _materials[index];
              return _MaterialCard(
                material: material,
                showStatus: _canManage,
                completed: _completed.contains(material.id),
                onTap: () => _open(material),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(_canManage ? 'Content' : 'Materials'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add material'),
      )
          : null,
      body: _body(),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.showStatus,
    required this.completed,
    required this.onTap,
  });

  final MaterialItem material;
  final bool showStatus;
  final bool completed;
  final VoidCallback onTap;

  Widget _chip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (material.category != null)
        _chip(material.category!, AppColors.tilePurple, AppColors.primary),
      if (showStatus)
        material.isPublished
            ? _chip('Published', AppColors.tileGreen, const Color(0xFF15803D))
            : _chip('Draft', AppColors.tileYellow, const Color(0xFFA16207)),
      if (completed)
        _chip('Completed', AppColors.tileGreen, const Color(0xFF15803D)),
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: material.hasFile
                      ? AppColors.tilePink
                      : AppColors.tilePurple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  material.hasFile
                      ? Icons.picture_as_pdf_rounded
                      : Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (material.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        material.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: chips),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}