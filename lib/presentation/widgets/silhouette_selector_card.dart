import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';

/// Componente Visual Refinado de Seleção de Biótipo Corporal (RF02)
/// Conforme AGENTS.md:
/// - Linhas capilares (borderSubtle)
/// - Ilustrações lineares vetoriais minimalistas para cada biótipo
/// - Resposta háptica refinada com HapticFeedback.selectionClick()
/// - Animação de seleção suave com AppMotion.editorialDecel
class SilhouetteSelectorCard extends StatelessWidget {
  final BodySilhouetteType silhouette;
  final bool isSelected;
  final VoidCallback onTap;

  const SilhouetteSelectorCard({
    super.key,
    required this.silhouette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.editorialDecel,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceRaised : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.accentTerracotta : AppColors.borderSubtle,
            width: isSelected ? 1.4 : 0.6,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentTerracotta.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppColors.editorialShadow,
        ),
        child: Row(
          children: [
            // Ilustração Vetorial Vetorial Linear do Biótipo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.accentTerracotta.withValues(alpha: 0.1)
                    : AppColors.surfaceRaised,
                border: Border.all(
                  color: isSelected ? AppColors.accentTerracotta : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(28, 28),
                  painter: _SilhouetteLinearPainter(
                    type: silhouette,
                    color: isSelected ? AppColors.accentTerracotta : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Textos Descritivos & Nome do Biótipo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        silhouette.displayName,
                        style: AppTypography.displayEditorial().copyWith(
                          fontSize: 17,
                          height: 1.2,
                          color: isSelected ? AppColors.accentTerracotta : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.accentTerracotta,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    silhouette.description,
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 11.5, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// CustomPainter para Desenho Vetorial Minimalista dos Biótipos Corporais
class _SilhouetteLinearPainter extends CustomPainter {
  final BodySilhouetteType type;
  final Color color;

  _SilhouetteLinearPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();

    switch (type) {
      case BodySilhouetteType.ampulheta:
        // Ombros largos, cintura fina, quadris largos
        path.moveTo(w * 0.15, h * 0.15);
        path.lineTo(w * 0.85, h * 0.15);
        path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.85, h * 0.85);
        path.lineTo(w * 0.15, h * 0.85);
        path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.15, h * 0.15);
        break;

      case BodySilhouetteType.retangulo:
        // Linhas verticais retas
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.25, h * 0.15, w * 0.5, h * 0.7),
          const Radius.circular(4),
        ));
        break;

      case BodySilhouetteType.triangulo:
        // Ombros estreitos, quadris largos
        path.moveTo(w * 0.35, h * 0.15);
        path.lineTo(w * 0.65, h * 0.15);
        path.lineTo(w * 0.85, h * 0.85);
        path.lineTo(w * 0.15, h * 0.85);
        path.close();
        break;

      case BodySilhouetteType.trianguloInvertido:
        // Ombros largos, quadris estreitos
        path.moveTo(w * 0.15, h * 0.15);
        path.lineTo(w * 0.85, h * 0.15);
        path.lineTo(w * 0.65, h * 0.85);
        path.lineTo(w * 0.35, h * 0.85);
        path.close();
        break;

      case BodySilhouetteType.oval:
        // Circunferência suave no centro
        path.addOval(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7));
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SilhouetteLinearPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
