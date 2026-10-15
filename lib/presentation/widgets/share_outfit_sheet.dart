import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/community_api_service.dart';
import '../../models/community_post.dart';
import '../../theme/app_theme.dart';
import 'ink_chip.dart';
import '../profile/style_profile_scope.dart';
import 'editorial_form.dart';
import 'photo_capture.dart';

/// Folha de papel para publicar um look no feed (RF14, AGENTS.md 7.5)
///
/// Foto do look vestido, legenda, ocasião, tags de estilo e visibilidade (RN05).
/// Aberta a partir de um look aprovado ([feedbackId]), o post leva as peças, a ocasião
/// e o IHE daquele look, conferidos pelo servidor.
class ShareOutfitSheet extends StatefulWidget {
  final CommunityApiService service;
  final String? feedbackId;
  final String initialCaption;
  final PhotoCapture? capturePhoto;

  const ShareOutfitSheet({
    super.key,
    required this.service,
    this.feedbackId,
    this.initialCaption = '',
    this.capturePhoto,
  });

  /// Devolve o post publicado, ou nulo se a folha foi fechada
  static Future<CommunityPost?> show(
    BuildContext context, {
    required CommunityApiService service,
    String? feedbackId,
    String initialCaption = '',
    PhotoCapture? capturePhoto,
  }) {
    return showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ShareOutfitSheet(
          service: service,
          feedbackId: feedbackId,
          initialCaption: initialCaption,
          capturePhoto: capturePhoto,
        ),
      ),
    );
  }

  @override
  State<ShareOutfitSheet> createState() => _ShareOutfitSheetState();
}

class _ShareOutfitSheetState extends State<ShareOutfitSheet> {
  /// Ocasiões oferecidas e a chave correspondente no motor do IHE
  static const occasions = [
    ('Casual', 'CASUAL'),
    ('Trabalho', 'TRABALHO'),
    ('Noite', 'NOITE'),
    ('Festa', 'FESTA'),
    ('Gala', 'GALA'),
  ];

  late final TextEditingController _caption = TextEditingController(text: widget.initialCaption);
  final TextEditingController _tags = TextEditingController();
  bool _isPublic = true;
  bool _profileIsPrivate = false;
  bool _visibilityTouched = false;
  String _occasion = 'CASUAL';
  CapturedPhoto? _photo;
  String? _error;
  bool _publishing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _followProfileVisibility();
  }

  /// O padrão segue a visibilidade do perfil (RN05), até a pessoa mexer no seletor
  Future<void> _followProfileVisibility() async {
    final repository = StyleProfileScope.maybeOf(context);
    if (repository == null) return;
    try {
      final profile = await repository.fetch();
      if (!mounted) return;
      setState(() {
        _profileIsPrivate = !profile.isPublic;
        if (!_visibilityTouched) _isPublic = profile.isPublic;
      });
    } catch (_) {
      // Sem o perfil, fica público por padrão; o servidor ainda esconde posts de perfis privados
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await (widget.capturePhoto ?? pickPhotoWithSystem)(source);
      if (photo != null && mounted) setState(() => _photo = photo);
    } on PlatformException {
      if (mounted) setState(() => _error = 'Não foi possível abrir a câmera. Verifique a permissão do app.');
    }
  }

  Future<void> _publish() async {
    final photo = _photo;
    final caption = _caption.text.trim();
    if (photo == null) {
      setState(() => _error = 'Escolha a foto do look.');
      return;
    }
    if (caption.isEmpty) {
      setState(() => _error = 'Escreva uma legenda para o look.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final post = await widget.service.publish(
        photo: photo.bytes,
        caption: caption,
        occasion: _occasion,
        styleTags: _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
        feedbackId: widget.feedbackId,
        isPublic: _isPublic,
      );
      if (mounted) Navigator.of(context).pop(post);
    } on CommunityException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromLook = widget.feedbackId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 16, AppSpacing.pageMargin, 24),
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.hairlineInk, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text('Compartilhar look', style: AppTypography.displayEditorial(color: AppColors.inkText).copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                fromLook
                    ? 'A publicação leva as peças e o IHE do look aprovado.'
                    : 'Uma foto do look vestido, para inspirar quem tem o seu estilo.',
                style: AppTypography.bodyReading(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 20),

              _PhotoPicker(photo: _photo, onPick: _publishing ? null : _pickPhoto),
              const SizedBox(height: 20),

              EditorialTextField(label: 'Legenda', controller: _caption, hint: 'Linho cru para uma tarde quente'),
              const SizedBox(height: 16),

              if (!fromLook) ...[
                Text('OCASIÃO', style: AppTypography.metadataBadge(color: AppColors.inkSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (label, key) in occasions)
                      InkChip(
                        label: label,
                        selected: _occasion == key,
                        onTap: () => setState(() => _occasion = key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              EditorialTextField(
                label: 'Tags de estilo',
                controller: _tags,
                hint: 'Minimal, Alfaiataria (até 5)',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // Visibilidade da publicação (RN05)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visível na comunidade', style: AppTypography.uiHeadline(color: AppColors.inkText)),
                        Text(
                          _isPublic ? 'Quem segue o feed vê este look' : 'Só você vê, em "Meus looks"',
                          style: AppTypography.bodySmall(color: AppColors.inkSecondary),
                        ),
                        if (_profileIsPrivate && _isPublic)
                          Text(
                            'Seu perfil está privado: ninguém vê seus looks até você torná-lo público no Perfil.',
                            style: AppTypography.bodySmall(color: AppColors.accentCinnabar),
                          ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isPublic,
                    activeThumbColor: AppColors.ivoryText,
                    activeTrackColor: AppColors.accentCinnabar,
                    onChanged: _publishing
                        ? null
                        : (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isPublic = value;
                              _visibilityTouched = true;
                            });
                          },
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                FormNotice(message: _error!),
              ],
              const SizedBox(height: 22),
              EditorialButton(label: 'Publicar look', onPressed: _publish, isLoading: _publishing),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto escolhida em destaque, ou os dois caminhos para escolher uma
class _PhotoPicker extends StatelessWidget {
  final CapturedPhoto? photo;
  final ValueChanged<ImageSource>? onPick;

  const _PhotoPicker({required this.photo, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final chosen = photo;
    final buttons = Row(
      children: [
        Expanded(
          child: EditorialButton(
            label: 'Câmera',
            tone: EditorialButtonTone.outline,
            onPressed: onPick == null ? null : () => onPick!(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EditorialButton(
            label: 'Galeria',
            tone: EditorialButtonTone.outline,
            onPressed: onPick == null ? null : () => onPick!(ImageSource.gallery),
          ),
        ),
      ],
    );
    if (chosen == null) return buttons;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.memory(chosen.bytes, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
          ),
        ),
        const SizedBox(height: 12),
        buttons,
      ],
    );
  }
}
