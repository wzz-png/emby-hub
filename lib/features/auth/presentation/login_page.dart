import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../core/theme/colors.dart';
import '../providers.dart';

/// 登录页面
///
/// 两步流程: 先连接服务器 -> 再用户登录。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _serverConnected = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _connectServer() async {
    final url = _serverController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('请输入服务器地址');
      return;
    }

    final success =
        await ref.read(authProvider.notifier).connectServer(url);
    if (success) {
      setState(() => _serverConnected = true);
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showSnackBar('请输入用户名');
      return;
    }

    final success =
        await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) {
      context.go('/home');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 监听错误
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _showSnackBar(next.error!);
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: FadeTransition(
              opacity: _fadeIn,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 24),
                    Text(
                      'Emby Hub',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '连接你的媒体世界',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // 服务器连接状态
                    if (authState.serverInfo != null && _serverConnected)
                      _buildServerInfo(authState),

                    // 表单卡片
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 服务器地址
                          _buildLabel('服务器地址'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _serverController,
                            hintText: 'https://your-emby-server.com',
                            enabled: !_serverConnected,
                            prefixIcon: Icons.dns_rounded,
                            suffixIcon: _serverConnected
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 20)
                                : null,
                          ),

                          // 已连接后显示用户名和密码
                          if (_serverConnected) ...[
                            const SizedBox(height: 20),
                            _buildLabel('用户名'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _usernameController,
                              hintText: '输入用户名',
                              prefixIcon: Icons.person_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            _buildLabel('密码'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: '输入密码（可选）',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_rounded,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.onSurfaceMuted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 操作按钮
                    SizedBox(
                      width: double.infinity,
                      child: _serverConnected
                          ? GlassButton(
                              isPrimary: true,
                              icon: Icons.login_rounded,
                              onPressed: isLoading ? null : () => _login(),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('登录'),
                            )
                          : GlassButton(
                              isPrimary: true,
                              icon: Icons.link_rounded,
                              onPressed: isLoading ? null : () => _connectServer(),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('连接服务器'),
                            ),
                    ),

                    // 重新连接
                    if (_serverConnected) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _serverConnected = false);
                          ref.read(authProvider.notifier).logout();
                        },
                        child: const Text(
                          '切换服务器',
                          style: TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildServerInfo(AuthState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.serverInfo!.serverName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Emby ${state.serverInfo!.version} · ${state.serverInfo!.operatingSystem}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.onSurfaceMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    bool enabled = true,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.glassStroke,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceMuted,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          icon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: AppColors.onSurfaceMuted)
              : null,
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
        ),
      ),
    );
  }
}
