part of jenkins;

class Teams extends JsonObject implements ITeams {
  
  Map<String,Jobs> teamsMap;
  
  Teams(String jsonString) {
    var jobs = new Jobs(jsonString);
    teamsMap = new Map<String, Jobs>();
    jobs.jobsList.forEach(categorise);
  }
  
  void categorise(Job job) {
    if(!teamsMap.containsKey(job.teamName)) {
      var newJobs = new Jobs(null);
      newJobs.jobsList.add(job);
      teamsMap[job.teamName] = newJobs;
    }
    else { 
      teamsMap[job.teamName].jobsList.add(job); 
    }
  }
}