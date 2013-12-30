library jenkins;

import 'package:json_object/json_object.dart'; 

abstract class IJobs {
  List<Job> jobs;
}

abstract class IJob {
  String name;
  String color;
  LastBuild jobList;
}

abstract class ILastBuild {
  int duration;
  int number;
  String result;
  int timestamp;
  List changeSet;
}

class Jobs extends JsonObject implements IJobs {
  Jobs(String jsonString) {
    jobs = new List<Job>();
    List jsonJobs = new JsonObject.fromJsonString(jsonString).jobs;
    for (var i=0; i < jsonJobs.length; i++) {
      var job = new Job(jsonJobs[i].toString());
      jobs.add(job);
    }
  }
}

class Job extends JsonObject implements IJob {
  Job(String jsonString) {
    var jobDetails = new JsonObject.fromJsonString(jsonString);
    name = jobDetails.name;
    color = jobDetails.color;
    lastBuild = new LastBuild();
    var buildInfo = jobDetails.lastBuild;
    if (buildInfo != null) { 
      lastBuild = new LastBuild.fromJsonString(buildInfo.toString());
    }
  }
 
}

class LastBuild extends JsonObject implements ILastBuild {
  LastBuild() {
    result = '';
    number = 0;
  }
  
  factory LastBuild.fromJsonString(string) {
    return new JsonObject.fromJsonString(string, new LastBuild());
  }
}