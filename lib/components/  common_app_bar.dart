import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login_page.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showLogout = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Text('🍜'),
          const SizedBox(width: 6),
          Text(title),
        ],
      ),
      actions: [
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠어요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (result == true) {
                final authProvider = context.read<AuthProvider>();
                authProvider.logout(); // 🔥 await 제거 (void 함수라 필요 없음)

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
      ],
    );
  }

  // 🔥 여기 고쳐야 함 (핵심)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
