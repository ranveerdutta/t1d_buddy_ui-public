
enum LogType {
  BG, BOLUS, BASAL, PUMP_BASAL, FOOD, EXERCISE, ACCESSORY_CHANGE
}

extension LogTypeExtension on LogType {

  String get name {
    switch (this) {
      case LogType.BG:
        return 'BG';
      case LogType.BOLUS:
        return 'Bolus';
      case LogType.BASAL:
        return 'Basal';
      case LogType.FOOD:
        return 'Food';
      case LogType.EXERCISE:
        return 'Exercise';
      case LogType.ACCESSORY_CHANGE:
        return 'Accessory change';
      case LogType.PUMP_BASAL:
        return 'Pump basal';
      default:
        throw Exception('wrong log type');
    }
  }
}

enum ExerciseType {
  WALKING, CYCLING, RUNNING, YOGA, SPORTS, SWIMMING, GYM_WORKOUT, OTHERS
}

extension ExerciseTypeExtension on ExerciseType {

  String get name {
    switch (this) {
      case ExerciseType.WALKING:
        return 'Walking';
      case ExerciseType.CYCLING:
        return 'Cycling';
      case ExerciseType.RUNNING:
        return 'Running';
      case ExerciseType.YOGA:
        return 'Yoga';
      case ExerciseType.SPORTS:
        return 'Sports';
      case ExerciseType.SWIMMING:
        return 'Swimming';
      case ExerciseType.GYM_WORKOUT:
        return 'Gym workout';
      case ExerciseType.OTHERS:
        return 'Others';
      default:
        throw Exception('wrong exercise type');
    }
  }

  String get value {
    switch (this) {
      case ExerciseType.WALKING:
        return 'WALKING';
      case ExerciseType.CYCLING:
        return 'CYCLING';
      case ExerciseType.RUNNING:
        return 'RUNNING';
      case ExerciseType.YOGA:
        return 'YOGA';
      case ExerciseType.SPORTS:
        return 'SPORTS';
      case ExerciseType.SWIMMING:
        return 'SWIMMING';
      case ExerciseType.GYM_WORKOUT:
        return 'GYM_WORKOUT';
      case ExerciseType.OTHERS:
        return 'OTHERS';
      default:
        throw Exception('wrong exercise type');
    }
  }
}


enum AccessoryType {
  NEEDLE, SYRINGE, INFUSION_SET, RESERVOIR, CGM, LANCET
}

extension AccessoryTypeExtension on AccessoryType {

  String get name {
    switch (this) {
      case AccessoryType.NEEDLE:
        return 'Needle';
      case AccessoryType.SYRINGE:
        return 'Syringe';
      case AccessoryType.INFUSION_SET:
        return 'Infusion set';
      case AccessoryType.RESERVOIR:
        return 'Reservoir';
      case AccessoryType.CGM:
        return 'CGM';
      case AccessoryType.LANCET:
        return 'Lancet';
      default:
        throw Exception('wrong accessory type');
    }
  }

  String get value {
    switch (this) {
      case AccessoryType.NEEDLE:
        return 'NEEDLE';
      case AccessoryType.SYRINGE:
        return 'SYRINGE';
      case AccessoryType.INFUSION_SET:
        return 'INFUSION_SET';
      case AccessoryType.RESERVOIR:
        return 'RESERVOIR';
      case AccessoryType.CGM:
        return 'CGM';
      case AccessoryType.LANCET:
        return 'LANCET';
      default:
        throw Exception('wrong accessory type');
    }
  }
}
