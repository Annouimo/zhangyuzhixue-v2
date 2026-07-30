import 'package:flutter_app/domain/paper_folder_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy folder names are displayed as paper baskets', () {
    expect(normalizePaperBasketName('默认组卷夹'), '默认试题篮');
    expect(normalizePaperBasketName('函数组卷夹'), '函数试题篮');
    expect(normalizePaperBasketName('函数专项'), '函数专项');
  });
}
