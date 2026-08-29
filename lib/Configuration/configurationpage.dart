import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../UI/app_widgets.dart';
import '../actionloggerservice.dart';
import 'themecontroller.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: PageContainer(
        maxWidth: 760,
        child: ListView(
          children: [
            const SectionTitle(
              'Aparência',
              subtitle: 'Escolha como a aplicação deve ser apresentada.',
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ThemeOption(
                    icon: Icons.brightness_auto_rounded,
                    title: 'Usar tema do sistema',
                    value: ThemeMode.system,
                    current: controller.themeMode,
                    onChanged: controller.setTheme,
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    title: 'Tema claro',
                    value: ThemeMode.light,
                    current: controller.themeMode,
                    onChanged: controller.setTheme,
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    title: 'Tema escuro',
                    value: ThemeMode.dark,
                    current: controller.themeMode,
                    onChanged: controller.setTheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle(
              'Privacidade e manutenção',
              subtitle: 'Ferramentas locais; os dados continuam guardados no dispositivo.',
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.cleaning_services_rounded, color: scheme.onErrorContainer),
                ),
                title: const Text('Limpar atividades recentes'),
                subtitle: const Text('Não elimina listas, itens nem histórico de compras.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final confirmed = await confirmAction(
                    context,
                    title: 'Limpar atividades?',
                    message: 'As mensagens de atividade do dashboard serão removidas.',
                    confirmLabel: 'Limpar',
                    destructive: true,
                  );
                  if (!confirmed) return;
                  await const ActionLoggerService().clearActions();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Atividades recentes removidas.')),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle('Sobre'),
            const SizedBox(height: 12),
            SurfaceCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('images/shoplist.png', width: 62, height: 62, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ShopList', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Gestão local de listas e compras · versão 1.1.0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeMode value;
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.value,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: current,
      onChanged: (mode) {
        if (mode != null) onChanged(mode);
      },
      secondary: Icon(icon),
      title: Text(title),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
