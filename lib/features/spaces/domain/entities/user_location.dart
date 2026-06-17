import 'package:equatable/equatable.dart';

/// A geographic coordinate captured from the device GPS.
class UserLocation extends Equatable {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}
