class SandboxTestCase {
  final String input;
  final String expectedContains;
  final String label;
  const SandboxTestCase(this.input, this.expectedContains, this.label);

  String get expected => expectedContains;
}

class SandboxMission {
  final String id;
  final String title;
  final String description;
  final String starterCode;
  final int xpReward;
  final List<SandboxTestCase> tests;
  const SandboxMission({
    required this.id,
    required this.title,
    required this.description,
    required this.starterCode,
    required this.xpReward,
    required this.tests,
  });
}
