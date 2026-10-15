
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialsPage extends StatefulWidget {
  final String role;

  const MaterialsPage({
    super.key,
    required this.role,
  });

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('materials')
          .select(
        'id, title, description, content, is_published, created_at',
      )
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _materials = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openMaterial(Map<String, dynamic> material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialDetailPage(material: material),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        widget.role == 'lecturer' || widget.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi Database Systems'),
        actions: [
          IconButton(
            onPressed: _loadMaterials,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat materi dari Supabase.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMaterials,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      )
          : _materials.isEmpty
          ? const Center(
        child: Text('Belum ada materi untuk ditampilkan.'),
      )
          : RefreshIndicator(
        onRefresh: _loadMaterials,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _materials.length,
          itemBuilder: (context, index) {
            final material = _materials[index];
            final published =
                material['is_published'] == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  child: Icon(Icons.menu_book),
                ),
                title: Text(
                  material['title']?.toString() ??
                      'Tanpa judul',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        material['description']?.toString() ??
                            '',
                      ),
                      if (canManage) ...[
                        const SizedBox(height: 8),
                        Text(
                          published
                              ? 'Status: Diterbitkan'
                              : 'Status: Draf',
                          style: TextStyle(
                            color: published
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () => _openMaterial(material),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MaterialDetailPage extends StatelessWidget {
  final Map<String, dynamic> material;

  const MaterialDetailPage({
    super.key,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Materi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material['title']?.toString() ?? 'Tanpa judul',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              material['description']?.toString() ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 32),
            Text(
              material['content']?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
