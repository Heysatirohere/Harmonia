import 'package:flutter/material.dart';

/// Design Tokens oficiais do HarmonIA conforme AGENTS.md
class AppColors {
  AppColors._();

  // ── Renascença do Ateliê (AGENTS.md seção 3) ─────────────────────────────
  // Salas Cromáticas: cenografia de fundo, sempre com textura (ver AtelierRoom)
  static const Color velvetBordeaux = Color(0xFF3B1829);
  static const Color silkEmerald = Color(0xFF1C3120);
  static const Color frescoBlue = Color(0xFF2A5261);
  static const Color verdigris = Color(0xFF1B4543);
  static const Color gildedOchre = Color(0xFF634524);
  static const Color tapestryNoir = Color(0xFF0E0C0A);

  // Superfícies e texto
  static const Color paperBone = Color(0xFFE9E4D6);       // Cartões e folhas de leitura
  static const Color paperBoneRaised = Color(0xFFF4EFE3);
  static const Color ivoryText = Color(0xFFF4EEE1);       // Texto sobre qualquer Sala
  static const Color ivoryMuted = Color(0xD9F4EEE1);      // Legendas sobre Sala (85%)
  static const Color inkText = Color(0xFF15110E);         // Texto sobre paperBone
  static const Color inkSecondary = Color(0xFF5E554B);
  static const Color hairlineIvory = Color(0x33F4EEE1);
  static const Color hairlineInk = Color(0x1F15110E);

  // Acentos
  static const Color accentCinnabar = Color(0xFFB8361E);  // CTA, rótulo sempre ivoryText
  static const Color gildedLeaf = Color(0xFFD4AE5C);      // Realces e IHE >= 75%, só sobre Sala (ver AtelierRoom.allowsSmallGoldText)
  static const Color verdigrisLight = Color(0xFF6FA59A);  // ESG sobre Sala
  static const Color hairlineGold = Color(0x73D4AE5C);    // Contorno joalheria sobre Sala (HUD, selos)
  static const Color ivoryVeil = Color(0x14F4EEE1);       // Véu marfim: agrupa conteúdo sobre Sala sem virar cartão
  static const Color gildedVeil = Color(0x1FD4AE5C);      // Fundo de selo IHE sobre Sala

  // Acentos sobre paperBone (o dourado e o verdete de Sala não têm contraste no papel)
  static const Color gildedInk = Color(0xFF7A5A1E);       // Ouro-tinta: 5,0:1 sobre paperBone
  static const Color gildedWash = Color(0x1F7A5A1E);      // Fundo de selo IHE sobre papel
  static const Color verdigrisInk = Color(0xFF2E6B5E);    // ESG sobre papel: 4,9:1

  // Sombra de folha sobre Sala (nunca em peça recortada)
  static const List<BoxShadow> paperShadow = [
    BoxShadow(color: Color(0x59000000), blurRadius: 32, offset: Offset(0, 16)),
  ];
}
