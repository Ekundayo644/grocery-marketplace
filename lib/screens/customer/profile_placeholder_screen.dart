import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          const Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFF0A3D7C),
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              p?['username'] ?? 'User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          Center(
            child: Text(
              auth.user?.email ?? '',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          _tile(Icons.person_outline, 'Full name', p?['full_name'] ?? '—'),
          _tile(Icons.phone_outlined, 'Phone', p?['phone'] ?? '—'),
          _tile(Icons.badge_outlined, 'Role', p?['role'] ?? 'customer'),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A3D7C)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}