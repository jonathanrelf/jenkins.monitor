import 'dart:html';
import 'dart:async'; 
import 'jenkins/jenkins.dart';

int renderObjectCount;

Element container;

List categories = [];

Map<String,List<Job>> categoriesMap;

const TIMEOUT = const Duration (seconds: 10);
const ms = const Duration (milliseconds: 1);

void main() {
  renderJobDetails();
  //var computers = new Computers();
  var timer = startTimeout();

}

void renderJobDetails() {
  var url = "http://build.esendex.com/api/json?depth=2&tree=jobs[name,color,downstreamProjects[name],upstreamProjects[name],lastBuild[number,builtOn,duration,estimatedDuration,timestamp,result,actions[causes[shortDescription,upstreamProject,upstreamBuild],lastBuiltRevision[branch[name]]],changeSet[items[msg,author[fullName],date]]]]";
  var request = HttpRequest.request(url).then(onDataLoaded);
}

void onDataLoaded(HttpRequest req) {
  Teams teamsData = new Teams(req.responseText);
  Jobs jobsData = new Jobs(req.responseText);
  
  var teams = teamNames();
  
  categoriesMap = new Map<String, List<Job>>();
  jobsData.jobsList.forEach(categorise);
  renderCategories(categoriesMap, teams);
  
}

List<String> teamNames() {
  var map = {};
  List<String> teams;
  String querystring = window.location.search.replaceFirst("?", "");
  for (String param in querystring.split("&")) {
    List<String> keyValue = param.split("=");
    if (keyValue.length == 1) {
      map[keyValue[0]] == "";
    }
    else if (keyValue.length == 2) {
      map[keyValue[0]] = Uri.decodeQueryComponent(keyValue[1]);
      teams = Uri.decodeQueryComponent(keyValue[1]).split(",");
    }
  }
  return teams;
}

void categorise(Job job) {
  var jobNameParts = job.name.toLowerCase().split('.');
  if(!categoriesMap.containsKey(jobNameParts[0])) {
    var newList = new List<Job>();
    newList.add(job);
    categoriesMap[jobNameParts[0]] = newList;
  }
  else { 
    categoriesMap[jobNameParts[0]].add(job); 
  }
}

void renderCategories(Map<String,List<Job>> categories, List<String> teams) {
  var failedJobs = 0;
  var buildingJobs = 0;
  bool failed = false;
  bool building = false;
  
  var wrapperDiv = new DivElement();
  wrapperDiv.id = "wrapper";
  wrapperDiv.className = "row";
  
  for(var categoryKey in categories.keys) {
    if (teams != null && teams.length > 0) {
      if (!teams.contains(categoryKey)) {
        continue;
      }
    }
    
    buildingJobs = 0;
    failedJobs = 0;
    
    var categoryInfo = new DivElement();
    categoryInfo.classes.add("col-md-12");
    categoryInfo.classes.add("category");
    
    categoryInfo.id = "categoryInfo";
    
    var jobs = categories[categoryKey];
    var jobListRow = new DivElement();
    jobListRow.classes.add("row");
    
    var jobList = new DivElement();
    jobList.className = "col-md-12";
    
    for(Job job in jobs) {
      var jobSpan = new ParagraphElement();
      
      switch(job.Colour){
        case JobStatus.DISABLED:
          break;
        case JobStatus.BUILDING:
          buildingJobs += 1;
          building = true;
          var buildJobDetails = BuildJobDetails(job);
          if(buildJobDetails.children.length > 0) {jobList.append(buildJobDetails);}
          jobList.append(jobSpan);
          break;
        case JobStatus.FAILED:
          failedJobs += 1;
          failed = true;
          var buildJobDetails = BuildJobDetails(job);
          if(buildJobDetails.children.length > 0) {jobList.append(buildJobDetails);}
          jobList.append(jobSpan);
          break;
        default:
          break;
      }
    }
    
    if (buildingJobs > 0 || failedJobs > 0) {
      var categoryName = new HeadingElement.h2();
      categoryName.text = categoryKey + " ";
      categoryInfo.append(categoryName);
      jobListRow.append(jobList);
      categoryInfo.append(jobListRow);
      
      if (failed) {
        categoryInfo.classes.add("failed");
      }
      else if (building) {
        categoryInfo.classes.add("building");
      }
      else {
        categoryInfo.classes.add("success");
      }
      wrapperDiv.append(categoryInfo);
    }
  }
  if(failed) { 
    querySelector("body").className="failed"; 
  }

  else {
    querySelector("body").className="";
  }

  querySelector("#wrapper").replaceWith(wrapperDiv);
}

DivElement BuildJobDetails(Job job) {
  var buildJob = new DivElement();
  buildJob.className = "buildJob";
    
  switch(job.Colour) {
    case JobStatus.BUILDING:
      buildJob.classes.add("building");
      break;
    case JobStatus.FAILED:
      buildJob.classes.add("failedJob");
      break;
  }
  
  var jobDetails = new DivElement();
  jobDetails.className = "jobDetails";
  
  var jobInfo = new SpanElement();
  jobInfo.classes.add("jobInfo");
  jobInfo.text = job.subname() + " ";
    
  var buildJobDetails = new DivElement();
  buildJobDetails.className = "btn-group";
  buildJobDetails.id = "buildJobDetails";
  
  var buildJobNumber = CreateButton(job.lastBuild.number.toString(), "glyphicon-list", "btn-primary");
  buildJobDetails.append(buildJobNumber);
  
  var durationTime = CreateButton(job.timePeriod + " min(s)", "glyphicon-time", "btn-primary");
  buildJobDetails.append(durationTime);
  
  if(job.Colour == JobStatus.FAILED){
    var sinceTime = CreateButton(job.lastBuild.timeSince.inMinutes.toString() + " mins", "glyphicon-exclamation-sign", "btn-danger");
    buildJobDetails.append(sinceTime);
  }
  
  
  
//  if (job.lastBuild.branchName != null && job.lastBuild.branchName != "") {
//    var buildJobBranchHeading = new HeadingElement.h2();
//    buildJobBranchHeading.id = "buildJobBranchHeading";
//    
//    var buildJobBranchName = new SpanElement();
//    buildJobBranchName.text = job.lastBuild.branchName;
//    buildJobBranchName.className = "label label-default";
//    buildJobBranchHeading.append(buildJobBranchName);
//    jobInfo.append(buildJobBranchHeading);
//  }
  
  jobDetails.append(jobInfo);
  
  jobDetails.append(buildJobDetails);
  buildJob.append(jobDetails);
  
  var progressBar = CreateProgress(job.duration, job.estimatedDuration, job.Colour);
  buildJob.append(progressBar);
  
  return buildJob;
}

DivElement CreateProgress(Duration currentValue, Duration maxValue, JobStatus jobStatus) {
  var percentage = ((currentValue.inSeconds / maxValue.inSeconds) * 100).round();
  
  var progressDiv = new DivElement();
  progressDiv.classes.add("progress");
  progressDiv.classes.add("progress-striped");
 

  if (jobStatus == JobStatus.BUILDING) { progressDiv.classes.add("active"); }
  
  var progressBarDiv = new DivElement();
  progressBarDiv.classes.add("progress-bar");
  switch(jobStatus) {
    case JobStatus.FAILED:
      progressBarDiv.classes.add("progress-bar-danger");
      break;
    case JobStatus.BUILDING:
      progressBarDiv.classes.add("progress-bar-warning");
      break;
    default:
      break;
  }
  progressBarDiv.style.width = percentage.toString() + "%"; 
  //progressBarDiv.text = percentage.toString() + "%";
  
  progressDiv.append(progressBarDiv);
  return progressDiv;
}

ButtonElement CreateButton(String label, String glyphicon, String buttonType) {
  var button = new ButtonElement();
  button.classes.add("btn");
  button.classes.add("btn-lg");
  button.classes.add(buttonType);
  
  var glyphiconElement = new SpanElement();
  glyphiconElement.classes.add("glyphicon");
  glyphiconElement.classes.add(glyphicon);
  
  var textElement = new SpanElement();
  textElement.text = " " + label;
  
  button.append(glyphiconElement);
  button.append(textElement);
  
  return button;
}

startTimeout([int milliseconds]) {
  var duration = milliseconds == null ? TIMEOUT : ms * milliseconds;
  return new Timer.periodic(duration, (_) { renderJobDetails(); });
}

