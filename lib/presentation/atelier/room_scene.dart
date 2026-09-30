import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import 'atelier_room.dart';

/// Cenografia fixa atrás de uma tela, que troca de Sala conforme o scroll (AGENTS.md seção 4).
///
/// Coloque um [RoomMarker] como sliver no início de cada seção do [CustomScrollView]
/// descendente. Sem marcadores, a tela inteira fica na Sala [room], e trocar [room]
/// dissolve a cenografia em [AppMotion.roomDissolve].
class RoomScene extends StatefulWidget {
  final AtelierRoom room;
  final Widget child;

  const RoomScene({super.key, required this.room, required this.child});

  @override
  State<RoomScene> createState() => RoomSceneState();
}

class RoomSceneState extends State<RoomScene> with SingleTickerProviderStateMixin {
  final Map<_RenderRoomMarker, (double, AtelierRoom)> _markers = {};
  late final ValueNotifier<RoomBlend> _blend = ValueNotifier(RoomBlend.solid(widget.room));
  final ValueNotifier<double> _drift = ValueNotifier(0);

  late final AnimationController _dissolve = AnimationController(
    vsync: this,
    duration: AppMotion.roomDissolve,
  )
    ..addListener(_onDissolveTick)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _recompute(fromLayout: false);
    });
  AtelierRoom? _dissolveFrom;
  AtelierRoom? _dissolveTo;

  double _scrollOffset = 0;
  double _viewportExtent = 0;
  bool _layoutRecomputeScheduled = false;

  /// Estado atual da cenografia (exposto para testes e para componentes que tingem com a Sala)
  ValueListenable<RoomBlend> get blend => _blend;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didUpdateWidget(covariant RoomScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room != widget.room) _recompute(fromLayout: true);
  }

  @override
  void dispose() {
    _dissolve.dispose();
    _blend.dispose();
    _drift.dispose();
    super.dispose();
  }

  void _reportMarker(_RenderRoomMarker marker, double start, AtelierRoom room) {
    if (_markers[marker] == (start, room)) return;
    _markers[marker] = (start, room);
    _scheduleLayoutRecompute();
  }

  void _removeMarker(_RenderRoomMarker marker) {
    if (_markers.remove(marker) != null) _scheduleLayoutRecompute();
  }

  // Marcadores reportam durante o layout; a cenografia só é atualizada depois do frame.
  void _scheduleLayoutRecompute() {
    if (_layoutRecomputeScheduled) return;
    _layoutRecomputeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutRecomputeScheduled = false;
      if (mounted) _recompute(fromLayout: true);
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _scrollOffset = notification.metrics.pixels;
      _viewportExtent = notification.metrics.viewportDimension;
      _recompute(fromLayout: false);
    }
    return false;
  }

  void _recompute({required bool fromLayout}) {
    final target = resolveRoomBlend(
      _markers.values.toList(),
      scrollOffset: _scrollOffset,
      viewportExtent: _viewportExtent,
      fallback: widget.room,
      reduceMotion: _reduceMotion,
    );
    if (_viewportExtent > 0) _drift.value = _scrollOffset * 0.12 / _viewportExtent;

    final current = _blend.value;
    final isSwap = target.t == 0 && current.t == 0 && target.from != current.from;
    if (fromLayout && isSwap && !_reduceMotion) {
      // Troca de conteúdo (filtro, nova tela): dissolve em vez de cortar
      _dissolveFrom = current.from;
      _dissolveTo = target.from;
      _dissolve.forward(from: 0);
      return;
    }
    if (_dissolve.isAnimating) {
      if (fromLayout) return; // a dissolução termina e recalcula no fim
      _dissolve.stop();
    }
    _blend.value = target;
  }

  void _onDissolveTick() {
    final from = _dissolveFrom;
    final to = _dissolveTo;
    if (from == null || to == null) return;
    final t = roomDissolveCurve.transform(_dissolve.value);
    _blend.value = t >= 1 ? RoomBlend.solid(to) : RoomBlend(from, to, t);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Todas as Salas são escuras: ícones claros na status bar
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: const Color(0x00000000)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_viewportExtent == 0 && constraints.hasBoundedHeight) {
            _viewportExtent = constraints.maxHeight;
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(child: _RoomBackdrop(blend: _blend, drift: _drift)),
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: _RoomSceneScope(state: this, child: widget.child),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomSceneScope extends InheritedWidget {
  final RoomSceneState state;

  const _RoomSceneScope({required this.state, required super.child});

  static RoomSceneState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RoomSceneScope>()?.state;

  @override
  bool updateShouldNotify(_RoomSceneScope oldWidget) => oldWidget.state != state;
}

/// Sliver de altura zero que marca o início de uma seção e a sua Sala.
class RoomMarker extends LeafRenderObjectWidget {
  final AtelierRoom room;

  const RoomMarker({super.key, required this.room});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRoomMarker(room: room, scene: _RoomSceneScope.maybeOf(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRoomMarker)
      ..room = room
      ..scene = _RoomSceneScope.maybeOf(context);
  }
}

class _RenderRoomMarker extends RenderSliver {
  AtelierRoom _room;
  RoomSceneState? scene;

  _RenderRoomMarker({required AtelierRoom room, required this.scene}) : _room = room;

  set room(AtelierRoom value) {
    if (value == _room) return;
    _room = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    geometry = SliverGeometry.zero;
    // precedingScrollExtent = offset de scroll em que esta seção começa
    scene?._reportMarker(this, constraints.precedingScrollExtent, _room);
  }

  @override
  void detach() {
    scene?._removeMarker(this);
    super.detach();
  }
}

/// Carrega o shader das Salas uma única vez; null se a plataforma não suportar.
class _AtelierShader {
  static Future<ui.FragmentProgram?>? _program;

  static Future<ui.FragmentProgram?> load() {
    return _program ??= ui.FragmentProgram.fromAsset('shaders/atelier_room.frag')
        .then<ui.FragmentProgram?>((program) => program)
        .catchError((Object error) {
      debugPrint('[RoomScene] Shader indisponível, usando cenografia sem textura: $error');
      return null;
    });
  }
}

class _RoomBackdrop extends StatefulWidget {
  final ValueListenable<RoomBlend> blend;
  final ValueListenable<double> drift;

  const _RoomBackdrop({required this.blend, required this.drift});

  @override
  State<_RoomBackdrop> createState() => _RoomBackdropState();
}

class _RoomBackdropState extends State<_RoomBackdrop> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _AtelierShader.load().then((program) {
      if (!mounted || program == null) return;
      setState(() => _shader = program.fragmentShader());
    });
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoomPainter(shader: _shader, blend: widget.blend, drift: widget.drift),
    );
  }
}

class _RoomPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final ValueListenable<RoomBlend> blend;
  final ValueListenable<double> drift;

  _RoomPainter({required this.shader, required this.blend, required this.drift})
      : super(repaint: Listenable.merge([blend, drift]));

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final state = blend.value;
    final shader = this.shader;

    if (shader == null) {
      // Sem shader: cor da Sala com a mesma vinheta de palco
      canvas.drawRect(rect, Paint()..color = state.color);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.1,
            colors: [Color(0x00000000), Color(0x59000000)],
          ).createShader(rect),
      );
      return;
    }

    var i = 0;
    void setColor(Color c) {
      shader
        ..setFloat(i++, c.r)
        ..setFloat(i++, c.g)
        ..setFloat(i++, c.b)
        ..setFloat(i++, 1);
    }

    shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height);
    setColor(state.from.color);
    shader
      ..setFloat(i++, state.from.texture.index.toDouble())
      ..setFloat(i++, state.from.seed);
    setColor(state.to.color);
    shader
      ..setFloat(i++, state.to.texture.index.toDouble())
      ..setFloat(i++, state.to.seed)
      ..setFloat(i++, state.t)
      ..setFloat(i++, drift.value);

    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.blend != blend || oldDelegate.drift != drift;
}
