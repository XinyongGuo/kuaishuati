void main() {
  test("A", "正确", true);
  test("A", "错误", false);
  test("B", "正确", false);
  test("B", "错误", true);

  test("正确", "正确", true);
  test("错误", "错误", true);

  test("(A) 正确", "正确", true);
  test("A. 正确", "正确", true);

  // Edge cases
  test(" A ", "正确", true);
  test("B.", "错误", true);
}

void test(String answer, String label, bool expected) {
  final result = _isTrueFalseCorrect(answer, label);
  if (result == expected) {
    print("PASS: answer='$answer', label='$label' -> $result");
  } else {
    print(
      "FAIL: answer='$answer', label='$label' -> $result (Expected $expected)",
    );
  }
}

bool _isTrueFalseCorrect(String answer, String label) {
  // 清理答案字符串,去除括号、空格等
  final cleanAnswer = answer
      .replaceAll(RegExp(r'[()（）\s.、。]'), '')
      .toUpperCase();

  // 检查是否包含A或B标签
  if (cleanAnswer.contains('A')) {
    return label == '正确';
  }
  if (cleanAnswer.contains('B')) {
    return label == '错误';
  }

  // 兼容旧格式:直接匹配内容
  // 支持答案格式: "正确"、"错误"、"A. 正确"、"(A) 正确"等
  return answer.contains(label);
}
