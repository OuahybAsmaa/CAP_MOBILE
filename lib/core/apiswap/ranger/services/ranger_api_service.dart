import '../data/ranger_test_data.dart';
import '../mappers/ranger_mapper.dart';

class RangerApiService {
  int get initialTokenCount => RangerMockData.initialTokenCount;
  List<String> get suggestedAddresses => RangerMockData.sampleAddresses;

  Future<RangerSubmitResult> submit({
    required String address,
    required int tokensBefore,
  }) async {
    final result = await RangerMockData.submitMock(
      address: address,
      tokensBefore: tokensBefore,
    );
    return RangerMapper.result(result);
  }
}
