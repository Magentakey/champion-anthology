import 'package:flutter/material.dart';

import '../../core/level/star_calculator.dart';
import 'genius_config.dart';
import 'genius_game.dart';
import 'genius_models.dart';

/// HUD Flutter di atas arena Flame: info step/nyawa, kartu soal, 4 tombol jawaban.
class GeniusHud extends StatelessWidget {
  const GeniusHud({super.key, required this.game});

  final GeniusGame game;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;
      return ListenableBuilder(
        listenable: Listenable.merge(
          [game.session, game.question, game.feedback, game.progress],
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
                child: _TopBar(step: step, progress: p),
              ),
              Positioned(
                top: h * ArenaLayout.questionTop,
                left: 16,
                right: 16,
                height: h * ArenaLayout.questionHeight,
                child: _QuestionCard(
                  text: q?.text ?? 'Step $step\nBersiap...',
                ),
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
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.progress});

  final int step;
  final StepProgress progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Step $step/${StarCalculator.totalSteps}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 12),
        for (var i = 0; i < progress.maxLives; i++)
          Icon(
            i < progress.lives ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
            size: 20,
          ),
        const SizedBox(width: 12),
        Text('${progress.correct}/${progress.target}'),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }
}

class _AnswerGrid extends StatelessWidget {
  const _AnswerGrid({
    required this.question,
    required this.feedback,
    required this.enabled,
    required this.onTap,
  });

  final Question? question;
  final AnswerFeedback? feedback;
  final bool enabled;
  final void Function(int index) onTap;

  Color _colorFor(int i) {
    final fb = feedback;
    if (fb != null) {
      if (i == fb.correct) return Colors.green.shade300;
      if (i == fb.chosen) return Colors.red.shade300;
    }
    return Colors.grey.shade300;
  }

  Widget _button(int i) {
    return _AnswerButton(
      label: question?.options[i] ?? '',
      color: _colorFor(i),
      onTap: enabled ? () => onTap(i) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _button(0)),
              const SizedBox(width: 12),
              Expanded(child: _button(1)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _button(2)),
              const SizedBox(width: 12),
              Expanded(child: _button(3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
