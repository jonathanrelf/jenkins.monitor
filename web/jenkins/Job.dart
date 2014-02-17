part of jenkins;

class Job extends JsonObject implements IJob {
  String teamName;
  String name;
  JobStatus Colour;
  LastBuild lastBuild;
  int timeSince;
  String timePeriod;
  Duration duration;
  Duration estimatedDuration;
  
  Job(String jsonString) {
    var jobDetails = new JsonObject.fromJsonString(jsonString);
    name = jobDetails.name;
    teamName = name.toLowerCase().split('.')[0];

    Colour = parseColor(jobDetails.color);
    duration = null;
    estimatedDuration = null;
    
    lastBuild = new LastBuild();
    var buildInfo = jobDetails.lastBuild;
    if (buildInfo != null) { 
      lastBuild = new LastBuild.fromJsonString(buildInfo.toString());
      estimatedDuration = lastBuild.estimatedDuration;
    
      switch(Colour) {
        case JobStatus.BUILDING:
      }
      if (Colour == JobStatus.BUILDING) {
        duration = DurationSince(lastBuild.timestamp);
      }
      else {
        duration = lastBuild.duration;
      }
    }
    timePeriod = DurationInMinutes(duration)+ " of " + DurationInMinutes(estimatedDuration);
  }
  
  String DurationInMinutes(Duration duration){
    if (duration == null) { 
      return "~"; 
    }
    return duration.inMinutes.toString();
  }
  Duration DurationSince(int timestamp) {
    var nowAsEpochMilliseconds = new DateTime.now().millisecondsSinceEpoch;
    var millisecondsSince = nowAsEpochMilliseconds - timestamp;
    var durationSince = new Duration(milliseconds: millisecondsSince);
    return durationSince;
  }
  
  JobStatus parseColor(String color) {
    switch(color) {
      case 'blue':
        return JobStatus.SUCCESS;
      case 'blue_anime':
      case 'red_anime':
      case 'yellow_anime':
      case 'grey_anime':
      case 'disabled_anime':
      case 'aborted_anime':
      case 'nobuilt_anime':
        return JobStatus.BUILDING;
      case 'red':
        return JobStatus.FAILED;
      case 'yellow':
        return JobStatus.UNSTABLE;
      case 'grey':
        return JobStatus.ABORTED;
      case 'disabled':
        return JobStatus.DISABLED;
      default:
        return JobStatus.UNKNOWN;
    }
  }
  
  String subname() {
    var jobNameParts = name.toLowerCase().split('.');
    jobNameParts.removeAt(0);
    //var bob = jobNameParts.removeLast();
    
    return jobNameParts.join('.');
  }
}