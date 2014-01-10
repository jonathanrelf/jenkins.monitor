import 'dart:html';
import 'jenkins.dart';
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
  var timer = startTimeout();
}

startTimeout([int milliseconds]) {
  var duration = milliseconds == null ? TIMEOUT : ms * milliseconds;
  return new Timer.periodic(duration, (_) { renderJobDetails(); });
}

void renderJobDetails() {
  var url = "http://build.esendex.com/api/json?pretty=true&depth=2&tree=jobs[name,color,downstreamProjects[name],upstreamProjects[name],lastBuild[number,builtOn,duration,timestamp,result,actions[causes[shortDescription,upstreamProject,upstreamBuild],lastBuiltRevision[branch[name]]],changeSet[items[msg,author[fullName],date]]]]";
  var request = HttpRequest.request(url).then(onDataLoaded);
}

void onDataLoaded(HttpRequest req) {
  Jobs jobsData = new Jobs(req.responseText);
  
  categoriesMap = new Map<String, List<Job>>();
  jobsData.jobs.forEach(categorise);
  handleCategories(categoriesMap);
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

void handleCategories(Map<String,List<Job>> categories) {
  var categoryKeys = categories.keys;
  var categoriesInfo = new DivElement();
  
  for(var categoryKey in categoryKeys) {
    var categoryInfo = new DivElement();
    categoryInfo.className = "categoryInfo";
    var categoryName = new HeadingElement.h2();
       
    var jobs = categories[categoryKey];
    var jobList = new UListElement();
    
    var categoryCount = 0;
    for(var job in jobs) {
      if (job.color.contains("_anime")) { 
        var buildingJobInfo = new LIElement();
        buildingJobInfo.text = job.name;
        buildingJobInfo.className = "building";
        
        var buildJobDetails = BuildJobDetails(job);
                
        if(buildJobDetails.children.length > 0) {buildingJobInfo.append(buildJobDetails);}
        jobList.append(buildingJobInfo);
        if (categoryInfo.className != "categoryWithFailure") { categoryInfo.className = "categoryBuilding"; }
      }
      if (job.lastBuild.result == "FAILURE" && job.color != "disabled") {
        querySelector("body").className="failed";
        var failedJobInfo = new LIElement();
        failedJobInfo.className = "failed";
        failedJobInfo.text = job.name;

        var buildJobDetails = BuildJobDetails(job);      
        if(buildJobDetails.children.length > 0) {failedJobInfo.append(buildJobDetails);}
        jobList.append(failedJobInfo);
        categoryInfo.className = "categoryWithFailure";
      }
      categoryCount++;
    }
    categoryName.text = categoryKey + " (" + categoryCount.toString() + ")";
    
    categoryInfo.append(categoryName);
    if(jobList.children.length > 0){ categoryInfo.append(jobList);}
    categoriesInfo.append(categoryInfo);
  }
  var wrapperDiv = new DivElement();
  wrapperDiv.id = "wrapper";
  wrapperDiv.append(categoriesInfo);
  querySelector("#wrapper").replaceWith(wrapperDiv);
}

UListElement BuildJobDetails(JsonObject job) {
  var branchName = "";
  var buildJobDetails = new UListElement();
  
  var actions = job.lastBuild.actions;
  if (actions.any((v) => v.containsKey("lastBuiltRevision"))){
    var revision = actions.firstWhere((v) => v.containsKey("lastBuiltRevision"));
    branchName = revision.lastBuiltRevision.branch[0].name;
  }
  
  var buildJobBranch = new LIElement();
  
  var buildNumberElement = new SpanElement();
  buildNumberElement.className = "buildNumber label";
  var buildNumberGlyphElement = new SpanElement();
  buildNumberGlyphElement.className = "glyphicon glyphicon-list";
  var buildNumberTextElement = new SpanElement();
  buildNumberTextElement.text = " " + job.lastBuild.number.toString();
  buildNumberElement.append(buildNumberGlyphElement);
  buildNumberElement.append(buildNumberTextElement);
  buildJobBranch.append(buildNumberElement);
  
  if (branchName.length > 0){
    var branchNameElement = new SpanElement();
    branchNameElement.className = "branch label";
    var branchNameGlyphElement = new SpanElement();
    branchNameGlyphElement.className = "glyphicon glyphicon-random";
    var branchNameTextElement = new SpanElement();
    branchNameTextElement.text = " " + branchName;
    branchNameElement.append(branchNameGlyphElement);
    branchNameElement.append(branchNameTextElement);
    buildJobBranch.append(branchNameElement);
  }
  
  var nowAsEpochMilliseconds = new DateTime.now().millisecondsSinceEpoch;
  var duration = new Duration(milliseconds: (nowAsEpochMilliseconds - job.lastBuild.timestamp)).inMinutes;
  var durationElement = new SpanElement();
  durationElement.className = "duration label";
  var clockElement = new SpanElement();
  clockElement.className = "glyphicon glyphicon-time";
  var durationTimeElement = new SpanElement();
  durationTimeElement.text = " " + duration.toString();
  durationElement.append(clockElement);
  durationElement.append(durationTimeElement);
  buildJobBranch.append(durationElement);
  
  buildJobDetails.append(buildJobBranch);
  return buildJobDetails;
}
