part of jenkins;

class LastBuild extends JsonObject implements ILastBuild {
  Duration duration;
  int number;
  String result;
  int timestamp;
  JsonObject changeSet;
  List actions;
  Duration estimatedDuration;
  Duration timeSince;
  String branchName;

  LastBuild() {
    result = '';
    number = 0;
  }
  
  factory LastBuild.fromJsonString(String jsonString) {
    var lastBuildDetails = new JsonObject.fromJsonString(jsonString);
    var duration = new Duration(milliseconds: lastBuildDetails.duration);
    var estimatedDuration = new Duration(milliseconds: lastBuildDetails.estimatedDuration);
    var nowAsEpochMilliseconds = new DateTime.now().millisecondsSinceEpoch;
    var millisecondsSince = nowAsEpochMilliseconds - lastBuildDetails.timestamp;
    var durationSince = new Duration(milliseconds: millisecondsSince);
    
    
    
    var lastBuild = new LastBuild();
    lastBuild.duration = duration;
    lastBuild.number = lastBuildDetails.number;
    lastBuild.result = lastBuildDetails.result;
    lastBuild.timestamp = lastBuildDetails.timestamp;
    lastBuild.changeSet = lastBuildDetails.changeSet;
    lastBuild.actions = lastBuildDetails.actions;
    lastBuild.estimatedDuration = estimatedDuration;
    lastBuild.timeSince = durationSince;
    
    var actions = lastBuildDetails.actions;
    if (actions.any((v) => v.containsKey("lastBuiltRevision"))){
      var revision = actions.firstWhere((v) => v.containsKey("lastBuiltRevision"));
      lastBuild.branchName = revision.lastBuiltRevision.branch[0].name;
    }
    return lastBuild;
  }
}