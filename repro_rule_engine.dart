// import 'package:flutter_test/flutter_test.dart';

void main() {
  final content = '''
1.安全链是一组串联的常开接线电路。
选项：
A 正确
B 错误
答案：B
解析：安全链应是常闭回路，确断开即触发停机。
''';

  final engine = RuleEngine();
  final questions = engine.parseContent(content, 1);

  if (questions.isEmpty) {
    print("No questions parsed!");
    return;
  }

  final q = questions.first.question;
  final opts = questions.first.options;

  print("Type: ${q.type}");
  print("Content: ${q.content}");
  print("Answer: ${q.answer}");
  print("Options count: ${opts.length}");
  for (var o in opts) {
    print("Option ${o.label}: '${o.content}'");
  }

  // Check detection logic manually
  if (opts.length == 2) {
    final opt1 = opts[0].content.trim();
    final opt2 = opts[1].content.trim();
    print("Opt1: '$opt1', Contains '正确': ${opt1.contains('正确')}");
    print("Opt2: '$opt2', Contains '错误': ${opt2.contains('错误')}");
  }
}

// Mock classes
enum QuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
  shortAnswer,
  fillInTheBlank,
}

class Option {
  final int questionId;
  final String label;
  final String content;
  Option({
    required this.questionId,
    required this.label,
    required this.content,
  });
}

class Question {
  final int? id;
  final int bankId;
  final QuestionType type;
  final String content;
  final String answer;
  final String? explanation;
  Question({
    this.id,
    required this.bankId,
    required this.type,
    required this.content,
    required this.answer,
    this.explanation,
  });
}

class ParsedQuestion {
  final Question question;
  final List<Option> options;
  ParsedQuestion(this.question, this.options);
}

class RuleEngine {
  static final RegExp _questionPattern = RegExp(
    r'^\s*(?:[-*]\s*)?(?:题目：|Question:)?\s*(?:[*]*((?:单选题|多选题|判断题|简答题|填空题))[*]*[:：])?\s*(\d+[\.:\．])?\s*(.*)',
  );
  static final RegExp _optionPattern = RegExp(
    r'^\s*(?:[-*]\s*)?\(?([A-Za-z])\)?[.．、:：]?\s+(.*)',
  );
  static final RegExp _answerPattern = RegExp(r'^\s*(?:[-*]\s*)?答案[:：]\s*(.*)');
  static final RegExp _explanationPattern = RegExp(
    r'^\s*(?:[-*]\s*)?解析[:：]\s*(.*)',
  );

  List<ParsedQuestion> parseContent(String content, int bankId) {
    List<ParsedQuestion> questions = [];
    List<String> lines = content.split('\n');

    String? currentQuestionContent;
    List<Option> currentOptions = [];
    String? currentAnswer;
    String? currentExplanation;
    QuestionType? currentExplicitType;

    StringBuffer contentBuffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      Match? questionMatch = _questionPattern.firstMatch(line);
      bool isQuestionStart = false;

      if (questionMatch != null) {
        final typeStr = questionMatch.group(1);
        final numStr = questionMatch.group(2);
        if (typeStr != null || numStr != null || line.startsWith('题目：')) {
          isQuestionStart = true;
        }
      }

      if (isQuestionStart) {
        if (currentQuestionContent != null && currentAnswer != null) {
          questions.add(
            _buildQuestion(
              bankId,
              currentQuestionContent,
              currentOptions,
              currentAnswer!,
              currentExplanation,
              currentExplicitType,
            ),
          );
        }
        final typeStr = questionMatch!.group(1);
        final numStr = questionMatch.group(2) ?? '';
        final contentStr = questionMatch.group(3) ?? '';
        currentExplicitType = _parseType(typeStr);
        contentBuffer.clear();
        contentBuffer.write('$numStr$contentStr');
        currentQuestionContent = contentBuffer.toString();
        currentOptions = [];
        currentAnswer = null;
        currentExplanation = null;
        continue;
      }

      Match? optionMatch = _optionPattern.firstMatch(line);
      if (optionMatch != null && currentAnswer == null) {
        if (contentBuffer.isNotEmpty && currentQuestionContent != null) {
          currentQuestionContent = contentBuffer.toString();
        }
        currentOptions.add(
          Option(
            questionId: 0,
            label: optionMatch.group(1)!,
            content: optionMatch.group(2)!,
          ),
        );
        continue;
      }

      Match? answerMatch = _answerPattern.firstMatch(line);
      if (answerMatch != null) {
        currentAnswer = answerMatch.group(1);
        continue;
      }

      Match? explanationMatch = _explanationPattern.firstMatch(line);
      if (explanationMatch != null) {
        currentExplanation = explanationMatch.group(1);
        continue;
      }

      if (currentOptions.isEmpty && currentAnswer == null) {
        contentBuffer.write('\n$line');
      } else if (currentExplanation != null) {
        currentExplanation = '$currentExplanation\n$line';
      } else if (currentAnswer != null) {
        currentAnswer = '$currentAnswer\n$line';
      }
    }

    if (currentQuestionContent != null && currentAnswer != null) {
      if (contentBuffer.isNotEmpty) {
        currentQuestionContent = contentBuffer.toString();
      }
      questions.add(
        _buildQuestion(
          bankId,
          currentQuestionContent,
          currentOptions,
          currentAnswer!,
          currentExplanation,
          currentExplicitType,
        ),
      );
    }

    return questions;
  }

  QuestionType? _parseType(String? typeStr) {
    if (typeStr == null) return null;
    if (typeStr.contains('单选题')) return QuestionType.singleChoice;
    if (typeStr.contains('多选题')) return QuestionType.multipleChoice;
    if (typeStr.contains('判断题')) return QuestionType.trueFalse;
    if (typeStr.contains('简答题')) return QuestionType.shortAnswer;
    if (typeStr.contains('填空题')) return QuestionType.fillInTheBlank;
    return null;
  }

  ParsedQuestion _buildQuestion(
    int bankId,
    String content,
    List<Option> options,
    String answer,
    String? explanation,
    QuestionType? explicitType,
  ) {
    QuestionType type;

    if (explicitType != null) {
      type = explicitType;
    } else {
      if (options.isEmpty) {
        if (answer.contains('正确') ||
            answer.contains('错误') ||
            answer.contains('是') ||
            answer.contains('否') ||
            answer.trim().toUpperCase() == 'T' ||
            answer.trim().toUpperCase() == 'F' ||
            answer.contains('对') ||
            answer.contains('错')) {
          type = QuestionType.trueFalse;
        } else if (content.contains('()') ||
            content.contains('（）') ||
            answer.contains('空1')) {
          type = QuestionType.fillInTheBlank;
        } else {
          type = QuestionType.shortAnswer;
        }
      } else {
        bool isTFOptions = false;
        if (options.length == 2) {
          final opt1 = options[0].content.trim();
          final opt2 = options[1].content.trim();
          if ((opt1.contains('正确') && opt2.contains('错误')) ||
              (opt1.contains('对') && opt2.contains('错')) ||
              (opt1.contains('是') && opt2.contains('否'))) {
            isTFOptions = true;
          }
        }

        if (isTFOptions) {
          type = QuestionType.trueFalse;
          options.clear();
        } else {
          final cleanAnswer = answer.replaceAll(RegExp(r'[^A-Z]'), '');
          if (cleanAnswer.length > 1) {
            type = QuestionType.multipleChoice;
          } else {
            type = QuestionType.singleChoice;
          }
        }
      }
    }

    String finalAnswer = answer.trim();
    String finalContent = content;

    if (type == QuestionType.trueFalse) {
      finalContent = content
          .replaceAll(RegExp(r'\s*[（(][√×✓✗对错TFtf][）)]\s*'), '')
          .trim();
      if (finalAnswer.contains('A') ||
          finalAnswer.contains('正确') ||
          finalAnswer.contains('对') ||
          finalAnswer.contains('是')) {
        finalAnswer = 'A';
      } else {
        finalAnswer = 'B';
      }
    }

    Question question = Question(
      bankId: bankId,
      type: type,
      content: finalContent,
      answer: finalAnswer,
      explanation: explanation,
    );
    return ParsedQuestion(question, options);
  }
}
