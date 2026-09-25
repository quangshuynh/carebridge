import 'package:flutter/services.dart';

import '../services/tactile_feedback.dart';

class PlatformTactileFeedback implements TactileFeedback {
  const PlatformTactileFeedback();

  /// A single light tap. The platform decides whether it is felt, following
  /// the device's own vibration and touch-feedback settings.
  @override
  Future<void> acknowledge() => HapticFeedback.lightImpact();
}
