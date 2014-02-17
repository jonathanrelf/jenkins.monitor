import 'dart:html';
import 'jenkins/jenkins.dart';
import 'dart:async';
import 'package:json_object/json_object.dart'; 

int renderObjectCount;

Element container;

List categories = [];

Map<String,List<Job>> categoriesMap;

const TIMEOUT = const Duration (seconds: 10);
const ms = const Duration (milliseconds: 1);

void main() {
  renderJobDetails();
  var computers = new Computers();
  var timer = startTimeout();
}

void renderJobDetails() {
  var url = "http://build.esendex.com/api/json?depth=2&tree=jobs[name,color,downstreamProjects[name],upstreamProjects[name],lastBuild[number,builtOn,duration,estimatedDuration,timestamp,result,actions[causes[shortDescription,upstreamProject,upstreamBuild],lastBuiltRevision[branch[name]]],changeSet[items[msg,author[fullName],date]]]]";
  var request = HttpRequest.request(url).then(onDataLoaded);
}

void onDataLoaded(HttpRequest req) {
  Teams teamsData = new Teams(req.responseText);
  Jobs jobsData = new Jobs(req.responseText);
  
  categoriesMap = new Map<String, List<Job>>();
  jobsData.jobsList.forEach(categorise);
  renderCategories(categoriesMap);
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

void renderCategories(Map<String,List<Job>> categories) {
  var failedJobs = 0;
  var buildingJobs = 0;
  bool failed = false;
  
  var wrapperDiv = new DivElement();
  wrapperDiv.id = "wrapper";
  
  for(var categoryKey in categories.keys) {
    buildingJobs = 0;
    failedJobs = 0;
    
    var categoryInfo = new DivElement();
    categoryInfo.className = "col-md-12";
    categoryInfo.id = "categoryInfo";
    
    var jobs = categories[categoryKey];
    var jobList = new DivElement();
    jobList.className = "btn-group-vertical";
        
    for(Job job in jobs) {
      //print(job.Colour);
      switch(job.Colour){
        case JobStatus.DISABLED:
          break;
        case JobStatus.BUILDING:
          buildingJobs += 1;
          var buildingJobInfo = new ButtonElement();
          buildingJobInfo.text = job.subname() + " ";
          buildingJobInfo.className = "btn btn-default";
          
          var buildJobDetails = BuildJobDetails(job);
                  
          if(buildJobDetails.children.length > 0) {buildingJobInfo.append(buildJobDetails);}
          jobList.append(buildingJobInfo);
          categoryInfo.classes.add("building");
          break;
        case JobStatus.FAILED:
          failedJobs += 1;
          failed = true;
          var failedJobInfo = new ButtonElement();
          failedJobInfo.className = "btn btn-default";
          failedJobInfo.text = job.subname();
  
          var buildJobDetails = BuildJobDetails(job);      
          if(buildJobDetails.children.length > 0) {failedJobInfo.append(buildJobDetails);}
          jobList.append(failedJobInfo);
          categoryInfo.classes.add("failed");
          break;
        default:
          categoryInfo.classes.add("success");
          break;
      }
    }
    
    if (buildingJobs > 0 || failedJobs > 0) {

      
      var categoryName = new HeadingElement.h2();
      categoryName.text = categoryKey + " ";
      
//      var categoryCountElement = new SpanElement();
//      categoryCountElement.className = "badge";
//      categoryCountElement.text = jobs.length.toString();
//      categoryName.append(categoryCountElement);
      categoryInfo.append(categoryName);
      
      if(jobList.children.length > 0){ categoryInfo.append(jobList);}
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

DivElement BuildJobDetails(JsonObject job) {
  var branchName = "";
  var buildJobDetails = new DivElement();
  buildJobDetails.className = "btn-group-vertical";
  
  var actions = job.lastBuild.actions;
  if (actions.any((v) => v.containsKey("lastBuiltRevision"))){
    var revision = actions.firstWhere((v) => v.containsKey("lastBuiltRevision"));
    branchName = revision.lastBuiltRevision.branch[0].name;
  }
  
  var buildJobBranch = CreateButton(job.lastBuild.number.toString(), "glyphicon-list", "btn-default");
  var durationTime = CreateButton(job.timePeriod, "glyphicon-time", "btn-default");
  
  buildJobDetails.append(buildJobBranch);
  buildJobDetails.append(durationTime);
  if(job.Colour == JobStatus.FAILED){
    var sinceTime = CreateButton(job.lastBuild.timeSince.inMinutes.toString(), "glyphicon-exclamation-sign", "btn-default");
    buildJobDetails.append(sinceTime);
  }
  
  var progressBar = CreateProgress(job.duration, job.estimatedDuration, job.Colour == JobStatus.BUILDING, "progress-bar-warning");
  buildJobDetails.append(progressBar);
  
  return buildJobDetails;
}

DivElement CreateProgress(Duration currentValue, Duration maxValue, bool isBuilding, String style) {
  var percentage = ((currentValue.inSeconds / maxValue.inSeconds) * 100).round();
  
  var progressDiv = new DivElement();
  progressDiv.classes.add("progress");
  progressDiv.classes.add("progress-striped");
  if (isBuilding) { progressDiv.classes.add("active"); }
  
  var progressBarDiv = new DivElement();
  progressBarDiv.classes.add("progress-bar");
  progressBarDiv.classes.add(style);
  progressBarDiv.style.width = percentage.toString() + "%"; 
  progressBarDiv.text = percentage.toString() + "%";
  
  progressDiv.append(progressBarDiv);
  return progressDiv;
}

ButtonElement CreateButton(String label, String glyphicon, String buttonType) {
  var button = new ButtonElement();
  button.classes.add("btn");
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

