import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/models/finance_setup.dart';
import 'package:finfamily/models/financial_insight.dart';
import 'package:finfamily/services/recommendation_service.dart';

const _contoh = FinanceSetup(
  gaji: 8000000,
  kebutuhan: 4000000,
  cicilan: 1500000,
  tabungan: 1000000,
);

void main() {
  test('porsi Sekunder mengikuti kondisi keuangan', () {
    expect(sekunderShareFor(FinancialCondition.aman), 70);
    expect(sekunderShareFor(FinancialCondition.cukup), 75);
    expect(sekunderShareFor(FinancialCondition.kritis), 85);
    expect(sekunderShareFor(FinancialCondition.overleveraged), 90);
  });

  test('contoh 8 juta memakai pembagian kondisi cukup', () async {
    final result = await const DefaultRecommendationService().recommend(
      _contoh,
    );

    expect(result.insight?.condition, FinancialCondition.cukup);
    expect(result.sekunderPercent, 75);
    expect(result.tersierPercent, 25);
  });

  test('cicilan di atas 40 persen pemasukan dianggap overleveraged', () async {
    const setup = FinanceSetup(
      gaji: 8000000,
      kebutuhan: 3000000,
      cicilan: 4000000,
      tabungan: 500000,
    );

    final result = await const DefaultRecommendationService().recommend(setup);

    expect(result.insight?.condition, FinancialCondition.overleveraged);
    expect(result.sekunderPercent, 90);
    expect(result.tersierPercent, 10);
  });

  test('kondisi aman memakai pembagian bawaan 70/30', () async {
    const setup = FinanceSetup(
      gaji: 10000000,
      kebutuhan: 3000000,
      cicilan: 1000000,
      tabungan: 2000000,
    );

    final result = await const DefaultRecommendationService().recommend(setup);

    expect(result.insight?.condition, FinancialCondition.aman);
    expect(result.sekunderPercent, 70);
    expect(result.tersierPercent, 30);
  });
}
