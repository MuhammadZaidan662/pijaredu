import 'package:supabase_flutter/supabase_flutter.dart';

/// Data shown on Home and Profile. Loaded once by AppShell and shared.
class HomeData {
  const HomeData({
    required this.name,
    required this.email,
    required this.materials,
  });

  final String name;
  final String email;
  final List<Map<String, dynamic>> materials;

  int get materialCount => materials.length;

  List<Map<String, dynamic>> get latestMaterials =>
      materials.take(3).toList();
}

Future<HomeData> loadHomeData() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  var email = user?.email ?? '';
  var name = '';

  if (user != null) {
    final profile = await client
        .from('profiles')
        .select('full_name, email')
        .eq('id', user.id)
        .maybeSingle();

    if (profile != null) {
      name = (profile['full_name'] as String?)?.trim() ?? '';
      final profileEmail = profile['email'] as String?;
      if (profileEmail != null && profileEmail.isNotEmpty) {
        email = profileEmail;
      }
    }
  }

  if (name.isEmpty) {
    name = email.contains('@') ? email.split('@').first : 'there';
  }

  // Students only receive published rows (enforced by RLS in Supabase).
  final data = await client
      .from('materials')
      .select('id, title, description, content, is_published, created_at')
      .order('created_at', ascending: false);

  return HomeData(
    name: name,
    email: email,
    materials: List<Map<String, dynamic>>.from(data),
  );
}