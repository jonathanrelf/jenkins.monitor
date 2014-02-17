part of jenkins;

abstract class ILastBuild {
  Duration duration;
  int number;
  String result;
  int timestamp;
  JsonObject changeSet;
}