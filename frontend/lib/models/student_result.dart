class StudentResult {
  String name;
  String group;
  String moduleName;
  double mark;

  StudentResult({
    required this.name,
    required this.group,
    required this.moduleName,
    required this.mark,
  });

  factory StudentResult.fromJson(Map<String, dynamic> json) {
    return StudentResult(
      name: json['name'] ?? '',
      group: json['group'] ?? '',
      moduleName: json['module'] ?? '',
      mark: (json['mark'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'group': group,
      'module': moduleName,
      'mark': mark,
    };
  }
}
