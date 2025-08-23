import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_experiment/amplitude_experiment.dart';
import 'package:amplitude_experiment/amplitude_experiment_platform_interface.dart';
import 'package:amplitude_experiment/amplitude_experiment_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAmplitudeExperimentPlatform
    with MockPlatformInterfaceMixin
    implements AmplitudeExperimentPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AmplitudeExperimentPlatform initialPlatform = AmplitudeExperimentPlatform.instance;

  test('$MethodChannelAmplitudeExperiment is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAmplitudeExperiment>());
  });

  test('getPlatformVersion', () async {
    AmplitudeExperiment amplitudeExperimentPlugin = AmplitudeExperiment();
    MockAmplitudeExperimentPlatform fakePlatform = MockAmplitudeExperimentPlatform();
    AmplitudeExperimentPlatform.instance = fakePlatform;

    expect(await amplitudeExperimentPlugin.getPlatformVersion(), '42');
  });
}
