import 'package:flutter/material.dart';

import '../../mocks/mock_gap_analysis.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/gap_analysis_sheet.dart';

/// Lacunas do Acervo & Afiliação (RF11/RF12): cada lacuna em uma folha de papel sobre o verdete
class GapAnalysisScreen extends StatelessWidget {
  const GapAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gaps = MockGapAnalysis.gaps;
    const room = AtelierRoom.verdigris;

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: room,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            RoomHeader(
              eyebrow: 'Lacunas & afiliação • RF11/RF12',
              title: 'Otimização de Acervo',
              subtitle: 'Peças-chave que destravam novas combinações',
              room: room,
              onBack: () => Navigator.maybePop(context),
            ),
            for (final gap in gaps)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 0, AppSpacing.pageMargin, 20),
                child: AtelierSheet(child: GapAnalysisSheet(gap: gap)),
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
