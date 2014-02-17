part of jenkins;

class Jobs extends JsonObject implements IJobs {
  List<Job> jobsList;
    
  Jobs(String jsonString) {
    jobsList = new List<Job>();
    if (jsonString != null && jsonString != "") {
      List jsonJobs = new JsonObject.fromJsonString(jsonString).jobs;
      for (var i=0; i < jsonJobs.length; i++) {
        var job = new Job(jsonJobs[i].toString());
        jobsList.add(job);
      }
    }
  }
}
