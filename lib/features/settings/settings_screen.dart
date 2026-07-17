import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/section_header.dart';
import '../../core/settings.dart';
import 'package:universal_io/io.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUpdatingEngine = false;
  final TextEditingController _podcasterController = TextEditingController();
  
  @override
  void dispose() {
    _podcasterController.dispose();
    super.dispose();
  }

  Future<void> _updateYtDlp() async {
    setState(() { _isUpdatingEngine = true; });
    try {
      final dir = await getApplicationSupportDirectory();
      final exe = File('${dir.path}/yt-dlp.exe');
      if (await exe.exists()) {
        final res = await Process.run(exe.path, ['-U']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.stdout.toString().split('\n').where((l) => l.trim().isNotEmpty).last)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Engine binary not found. Play a track first to download it.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUpdatingEngine = false; });
      }
    }
  }

  Widget _buildSettingsGroup({required String title, required String subtitle, required Widget child}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55), fontSize: 13)),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Preferences",
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Customize your PULSE experience — themes, audio engine, downloads, and more.",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsGroup(
                  title: "Visual Theme Profile",
                  subtitle: "Select the aesthetic that defines your experience.",
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _ThemeCard(
                          label: "Light Mode",
                          primary: Colors.white,
                          isSelected: appSettings.themeMode == 'white',
                          onTap: () => ref.read(settingsProvider.notifier).setThemeMode('white'),
                        ),
                        const SizedBox(width: 16),
                        _ThemeCard(
                          label: "Slate Mode",
                          primary: const Color(0xFF26263A),
                          isSelected: appSettings.themeMode == 'black',
                          onTap: () => ref.read(settingsProvider.notifier).setThemeMode('black'),
                        ),
                        const SizedBox(width: 16),
                        _ThemeCard(
                          label: "Midnight Mode",
                          primary: const Color(0xFF0F0F0F),
                          isSelected: appSettings.themeMode == 'midnight',
                          onTap: () => ref.read(settingsProvider.notifier).setThemeMode('midnight'),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildSettingsGroup(
                  title: "Downloads Directory",
                  subtitle: "Current path: ${appSettings.downloadPath ?? 'Default (OS Downloads Folder)'}",
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.folder_rounded, color: theme.primaryColor),
                    ),
                    title: const Text("Change Download Folder", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("Select where your offline music is stored", style: TextStyle(color: onSurface.withOpacity(0.5))),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: "Select Download Folder for PULSE",
                      );
                      if (selectedDirectory != null) {
                        ref.read(settingsProvider.notifier).setDownloadPath(selectedDirectory);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Download folder updated to $selectedDirectory')),
                        );
                      }
                    },
                  ),
                ),

                _buildSettingsGroup(
                  title: "Audio Infrastructure / Source Engine",
                  subtitle: "Choose the engine that powers your audio streams. Extractor is highly recommended for best quality.",
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Text("Extractor", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: theme.primaryColor.withOpacity(0.4)),
                              ),
                              child: Text("Recommended", style: TextStyle(color: theme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("yt-dlp + YouTube Music (mirrors extractor package)", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                        ),
                        value: 'extractor',
                        groupValue: appSettings.musicSource,
                        activeColor: theme.primaryColor,
                        onChanged: (val) => ref.read(settingsProvider.notifier).setMusicSource(val!),
                      ),
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      RadioListTile<String>(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text("YouTube / yt-dlp Native Binary", style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("Direct YouTube Music search + yt-dlp stream extraction", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                        ),
                        value: 'youtube',
                        groupValue: appSettings.musicSource,
                        activeColor: theme.primaryColor,
                        onChanged: (val) => ref.read(settingsProvider.notifier).setMusicSource(val!),
                      ),
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      RadioListTile<String>(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text("JioSaavn (Official API)", style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("High-speed streams powered by KRTirtho/jiosaavn open-source backend", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                        ),
                        value: 'jiosaavn',
                        groupValue: appSettings.musicSource,
                        activeColor: theme.primaryColor,
                        onChanged: (val) => ref.read(settingsProvider.notifier).setMusicSource(val!),
                      ),
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: _isUpdatingEngine
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.update_rounded, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        title: Text(_isUpdatingEngine ? "Updating Engine..." : "Check for Engine Updates", style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("Ensure your yt-dlp binary is up to date", style: TextStyle(color: onSurface.withOpacity(0.5))),
                        onTap: _isUpdatingEngine ? null : _updateYtDlp,
                      ),
                    ],
                  ),
                ),

                _buildSettingsGroup(
                  title: "Discover Interface Layout",
                  subtitle: "Customize the modules explicitly showcased natively upon your Home viewport.",
                  child: Column(
                    children: ['Popular Artists', 'Recommendations', 'Trending Playlists', 'Desi Hot Hits', 'Ghazal & Sufi Classics', 'Geetmala Legends'].asMap().entries.map((entry) {
                      final isLast = entry.key == 5;
                      final section = entry.value;
                      return Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(section, style: const TextStyle(fontWeight: FontWeight.w500)),
                            activeColor: theme.primaryColor,
                            value: appSettings.activeHomeSections.contains(section),
                            onChanged: (val) {
                              ref.read(settingsProvider.notifier).toggleHomeSection(section, val);
                            },
                          ),
                          if (!isLast) Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 40),
                _buildSettingsGroup(
                  title: "Podcast Preferences",
                  subtitle: "Customize your podcast experience.",
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: const Text("Language Filter", style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: const Text("Only show podcasts in this language"),
                        trailing: DropdownButton<String>(
                          value: appSettings.podcastLanguage,
                          underline: const SizedBox.shrink(),
                          items: ['Any', 'English', 'Hindi', 'Punjabi', 'Tamil', 'Telugu']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) ref.read(settingsProvider.notifier).setPodcastLanguage(val);
                          },
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Favorite Podcasters", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text("These creators will get their own dedicated section on the Podcast page.", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _podcasterController,
                                    decoration: InputDecoration(
                                      hintText: "e.g., Jay Shetty",
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        ref.read(settingsProvider.notifier).addCustomPodcaster(val.trim());
                                        _podcasterController.clear();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () {
                                    if (_podcasterController.text.trim().isNotEmpty) {
                                      ref.read(settingsProvider.notifier).addCustomPodcaster(_podcasterController.text.trim());
                                      _podcasterController.clear();
                                    }
                                  },
                                  child: const Text("Add"),
                                )
                              ],
                            ),
                            if (appSettings.customPodcasters.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: appSettings.customPodcasters.map((p) {
                                  return Chip(
                                    label: Text(p),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () => ref.read(settingsProvider.notifier).removeCustomPodcaster(p),
                                  );
                                }).toList(),
                              )
                            ]
                          ],
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      ...['Recommended for You', 'Top Trending Global', 'Psychology', 'Philosophy', 'Ghost stories'].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final section = entry.value;
                        final isLast = idx == 4;
                        return Column(
                          children: [
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              title: Text(section, style: const TextStyle(fontWeight: FontWeight.w500)),
                              activeColor: theme.primaryColor,
                              value: appSettings.podcastActiveSections.contains(section),
                              onChanged: (val) {
                                ref.read(settingsProvider.notifier).togglePodcastSection(section, val);
                              },
                            ),
                            if (!isLast) Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "PULSE V2 • Built using Flutter • 2026",
                    style: TextStyle(color: onSurface.withOpacity(0.3), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final Color primary;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({required this.label, required this.primary, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withOpacity(0.12) : theme.colorScheme.onSurface.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.primaryColor : theme.dividerColor.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? theme.primaryColor.withOpacity(0.15) : Colors.transparent,
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: isSelected ? Icon(Icons.check_rounded, size: 20, color: primary.computeLuminance() > 0.5 ? Colors.black87 : Colors.white) : null,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.primaryColor : onSurface.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
