import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb/core/models/models.dart';
import 'package:xsmb/core/services/soi_cau_service.dart';

void main() {
  group('SoiCauService Local Computation Tests', () {
    late SoiCauService service;
    late List<LotteryResult> sampleHistory;

    setUp(() {
      service = SoiCauService();

      // Create a predictable history where draw D1 has vt 55='0', vt 95='0',
      // and draw D0 hits '00' in its numbers.
      sampleHistory = [
        LotteryResult(
          drawDate: '2026-10-04',
          db: '82951',
          g1: '28235',
          g2: ['82614', '47824'],
          g3: ['33386', '23385', '09503', '43582', '60243', '04348'],
          g4: ['2251', '1053', '3431', '9308'],
          g5: ['3969', '7927', '5509', '2889', '4781', '1038'],
          g6: ['237', '580', '604'],
          g7: ['90', '89', '26', '59'],
          createdAt: '',
        ),
        LotteryResult(
          drawDate: '2026-10-03',
          db: '77961',
          g1: '59714',
          g2: ['70056', '79568'],
          g3: ['20816', '60874', '21577', '85793', '36546', '43188'],
          g4: ['6288', '2348', '1063', '5874'],
          g5: ['6110', '2976', '0273', '0068', '4429', '2952'],
          g6: ['087', '641', '821'],
          g7: ['38', '43', '37', '27'],
          createdAt: '',
        ),
        LotteryResult(
          drawDate: '2026-10-02',
          db: '24483',
          g1: '48799',
          g2: ['63906', '22370'],
          g3: ['92151', '85709', '96557', '45967', '17050', '35145'],
          g4: ['2719', '2206', '1575', '1644'],
          g5: ['8754', '3913', '4102', '5685', '9938', '3837'],
          g6: ['294', '075', '609'],
          g7: ['84', '65', '87', '63'],
          createdAt: '',
        ),
        LotteryResult(
          drawDate: '2026-10-01',
          db: '40208',
          g1: '92635',
          g2: ['24807', '62639'],
          g3: ['16892', '82700', '92965', '40504', '68709', '38492'],
          g4: ['6537', '7453', '7691', '9434'],
          g5: ['3349', '1896', '5752', '6691', '6935', '4650'],
          g6: ['390', '655', '395'],
          g7: ['50', '15', '07', '04'],
          createdAt: '',
        ),
        LotteryResult(
          drawDate: '2026-09-30',
          db: '95242',
          g1: '82585',
          g2: ['24297', '13691'],
          g3: ['09006', '92188', '16348', '26272', '60098', '01271'],
          g4: ['9323', '6991', '2485', '0001'],
          g5: ['6672', '3984', '2140', '5302', '3225', '6175'],
          g6: ['730', '611', '160'],
          g7: ['17', '63', '60', '90'],
          createdAt: '',
        ),
        LotteryResult(
          drawDate: '2026-09-29',
          db: '05651',
          g1: '08389',
          g2: ['72814', '46429'],
          g3: ['61403', '53225', '12186', '68865', '70733', '05305'],
          g4: ['0985', '7902', '1519', '9746'],
          g5: ['2966', '2437', '6169', '6077', '5155', '7323'],
          g6: ['873', '010', '575'],
          g7: ['63', '19', '26', '67'],
          createdAt: '',
        ),
        LotteryResult(
          drawDate: '2026-09-28',
          db: '11111',
          g1: '22222',
          g2: ['33333', '44444'],
          g3: ['55555', '66666', '77777', '88888', '99999', '00000'],
          g4: ['1234', '5678', '9012', '3456'],
          g5: ['1111', '2222', '3333', '4444', '5555', '6666'],
          g6: ['111', '222', '333'],
          g7: ['11', '22', '33', '44'],
          createdAt: '',
        ),
      ];
    });

    test('computeFromLocal computes valid bridges', () {
      final res = service.computeFromLocal(
        history: sampleHistory,
        date: DateTime(2026, 10, 5),
        limitDays: 3,
        exactLimit: 0,
        isLon: true,
      );

      expect(res.totalBridges, greaterThan(0));
      expect(res.matrixDigits.length, equals(107));
      expect(res.cauList.isNotEmpty, isTrue);
    });

    test('computeCauDetailOffline creates valid history road', () {
      final detail = service.computeCauDetailOffline(
        history: sampleHistory,
        position: '55x95',
        date: DateTime(2026, 10, 5),
        limitDays: 3,
      );

      expect(detail.position, equals('55x95'));
      expect(detail.predictedNumbers.isNotEmpty, isTrue);
      expect(detail.historyDays.length, equals(3));
    });
  });
}
