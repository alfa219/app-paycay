class SensorDataModel {
  final double voltage;
  final double current;
  final double power;
  final double energyKwh;
  final int updatedAt;

  const SensorDataModel({
    required this.voltage,
    required this.current,
    required this.power,
    required this.energyKwh,
    required this.updatedAt,
  });

  static const empty = SensorDataModel(
    voltage: 0,
    current: 0,
    power: 0,
    energyKwh: 0,
    updatedAt: 0,
  );

  factory SensorDataModel.fromMap(Map<dynamic, dynamic>? data) {
    if (data == null) return empty;
    double d(dynamic v) => v is num ? v.toDouble() : 0;
    int i(dynamic v) => v is num ? v.toInt() : 0;
    return SensorDataModel(
      voltage: d(data['voltage']),
      current: d(data['current']),
      power: d(data['power']),
      energyKwh: d(data['energyKwh']),
      updatedAt: i(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'voltage': voltage,
        'current': current,
        'power': power,
        'energyKwh': energyKwh,
        'updatedAt': updatedAt,
      };
}
