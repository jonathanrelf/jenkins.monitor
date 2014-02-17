part of jenkins;

class JobStatus {
  final _value;
  const JobStatus._internal(this._value);
  toString() => 'JobStatus.$_value';
  
  static const BUILDING = const JobStatus._internal('BUILDING');
  static const FAILED = const JobStatus._internal('FAILED');
  static const SUCCESS = const JobStatus._internal('SUCCESS');
  static const UNSTABLE = const JobStatus._internal('UNSTABLE');
  static const ABORTED = const JobStatus._internal('ABORTED');
  static const UNKNOWN = const JobStatus._internal('UNKNOWN');
  static const DISABLED = const JobStatus._internal('DISABLED');
}