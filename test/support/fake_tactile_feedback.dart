import 'package:carebridge/services/tactile_feedback.dart';

class FakeTactileFeedback implements TactileFeedback {
  int acknowledgements = 0;
  Object? error;
  bool throwSynchronously = false;

  @override
  Future<void> acknowledge() {
    acknowledgements++;
    if (error != null && throwSynchronously) throw error!;
    if (error != null) return Future.error(error!);
    return Future.value();
  }
}
