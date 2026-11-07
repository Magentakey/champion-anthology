import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import '../../shared/widgets/boss_widgets.dart';
import '../../shared/widgets/hit_effect.dart';
import '../../shared/widgets/pixel_pattern.dart';
import '../../shared/widgets/pixel_ui.dart';
import 'genius_config.dart';
import 'genius_game.dart';
import 'genius_models.dart';

/// HUD Flutter bergaya piksel di atas arena Flame: info step/nyawa, kartu soal, 4 tombol jawaban.
class GeniusHud extends StatelessWidget {
  const GeniusHud({super.key, required this.game});

  final GeniusGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final u = PixelUi.unit(context);

    return HitEffect(
      trigger: game.wrongCount,
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          return ListenableBuilder(
            listenable: Listenable.merge(
              [
                game.session,
                game.question,
                game.feedback,
                game.progress,
                game.bossSay,
              ],
            ),
            builder: (context, _) {
              final q = game.question.value;
              final fb = game.feedback.value;
              final p = game.progress.value;
              final step = game.session.step;
              final canAnswer = q != null && fb == null && game.session.isPlaying;

              return Stack(
                children: [
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: _TopBar(step: step, progress: p, unit: u),
                  ),
                  Positioned(
                    top: h * ArenaLayout.bubbleTop,
                    left: c.maxWidth * ArenaLayout.bubbleLeft,
                    right: 12,
                    height: h * ArenaLayout.bubbleHeight,
                    child: BossSpeechBubble(text: game.bossSay.value),
                  ),
                  Positioned(
                    top: h * ArenaLayout.questionTop,
                    left: 16,
                    right: 16,
                    height: h * ArenaLayout.questionHeight,
                    child: q == null
                        ? StepBannerCard(
                            step: step,
                            label: stepLabels[(step - 1).clamp(0, stepLabels.length - 1).toInt()],
                          )
                        : _QuestionCard(category: q.category, text: q.text, unit: u),
                  ),
                  Positioned(
                    top: h * ArenaLayout.answersTop,
                    left: 16,
                    right: 16,
                    bottom: h * ArenaLayout.answersBottom,
                    child: _AnswerGrid(
                      question: q,
                      feedback: fb,
                      enabled: canAnswer,
                      onTap: game.answer,
                      unit: u,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.progress, required this.unit});

  final int step;
  final StepProgress progress;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Row(
      children: [
        Text('Step $step/${StarCalculator.totalSteps}', style: PixelUi.text(u)),
        SizedBox(width: 10 * u),
        for (var i = 0; i < progress.maxLives; i++) ...[
          if (i > 0) SizedBox(width: 2 * u),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: PixelHeart(
              key: ValueKey(i < progress.lives),
              filled: i < progress.lives,
              size: 8 * u,
            ),
          ),
        ],
        SizedBox(width: 10 * u),
        Text('${progress.correct}/${progress.target}', style: PixelUi.text(u)),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text, required this.unit, this.category});

  final String text;
  final String? category;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return SizedBox.expand(
      child: PixelFrame(
        unit: u,
        fill: PixelUi.paper,
        padding: EdgeInsets.all(6 * u),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category != null && category!.isNotEmpty) ...[
                Text(
                  category!.toUpperCase(),
                  style: PixelUi.text(u, color: const Color(0xFF6E5A96)),
                ),
                SizedBox(height: 5 * u),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: PixelUi.text(u, color: PixelUi.ink, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AnswerState { neutral, correct, wrong }

class _AnswerGrid extends StatelessWidget {
  const _AnswerGrid({
    required this.question,
    required this.feedback,
    required this.enabled,
    required this.onTap,
    required this.unit,
  });

  final Question? question;
  final AnswerFeedback? feedback;
  final bool enabled;
  final void Function(int index) onTap;
  final double unit;

  _AnswerState _stateFor(int i) {
    final fb = feedback;
    if (fb != null) {
      if (i == fb.correct) return _AnswerState.correct;
      if (i == fb.chosen) return _AnswerState.wrong;
    }
    return _AnswerState.neutral;
  }

  Widget _button(int i) {
    return _AnswerButton(
      label: question?.options[i] ?? '',
      state: _stateFor(i),
      unit: unit,
      onTap: enabled ? () => onTap(i) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = 6 * unit;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _button(0)),
              SizedBox(width: gap),
              Expanded(child: _button(1)),
            ],
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _button(2)),
              SizedBox(width: gap),
              Expanded(child: _button(3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatefulWidget {
  const _AnswerButton({
    required this.label,
    required this.state,
    required this.unit,
    required this.onTap,
  });

  final String label;
  final _AnswerState state;
  final double unit;
  final VoidCallback? onTap;

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v && widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final fill = switch (widget.state) {
      _AnswerState.correct => const Color(0xFF8FD48F),
      _AnswerState.wrong => const Color(0xFFF08A80),
      _AnswerState.neutral => PixelUi.paper,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: widget.onTap,
      child: Transform.translate(
        offset: Offset(0, _down ? 2 * u : 0),
        child: SizedBox.expand(
          child: PixelFrame(
            unit: u,
            fill: fill,
            padding: EdgeInsets.all(4 * u),
            child: Center(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: PixelUi.text(u, color: PixelUi.ink, height: 1.15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
