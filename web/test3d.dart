import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:json_object/json_object.dart'; 
import 'jenkins.dart';

int renderObjectCount;

Element container;

PerspectiveCamera camera;
Scene scene;
CanvasRenderer renderer;

List cubes = [];
Mesh cube;
Mesh plane;

num targetRotation;
num targetRotationOnMouseDown;

num mouseX;
num mouseXOnMouseDown;

num windowHalfX;
num windowHalfY;

var evtSubscriptions = [];

List categories = [];

Map<String,List<Job>> categoriesMap;

void main() {
  init();
  animate(0);
}

void init() {
  targetRotation = 0;
  targetRotationOnMouseDown = 0;

  mouseX = 0;
  mouseXOnMouseDown = 0;

  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  container = new Element.tag('div');
  //document.body.appendChild( container );
  document.body.nodes.add( container );

  Element info = new Element.tag('div');
  info.style.position = 'absolute';
  info.style.top = '10px';
  info.style.width = '100%';
  info.style.textAlign = 'center';
  info.innerHtml = 'Drag to spin the cube';
  //container.appendChild( info );
  container.nodes.add( info );

  scene = new Scene();
 
  camera = new PerspectiveCamera( 70.0, window.innerWidth / window.innerHeight, 1.0, 1000.0 );
  camera.position.y = 400.0;
  camera.position.z = 500.0;
  scene.add( camera );

  //cubes.add(addCube(400.0,0.0,150.0));
  
  renderer = new CanvasRenderer();
  renderer.setSize( window.innerWidth, window.innerHeight );
  
  //container.appendChild( renderer.domElement );
  container.nodes.add( renderer.domElement );

  evtSubscriptions = [
    document.onMouseDown.listen(onDocumentMouseDown),
    document.onTouchStart.listen(onDocumentTouchStart),
    document.onTouchMove.listen(onDocumentTouchMove)
    ];
  var url = "http://build.esendex.com/api/json?pretty=true&depth=2&tree=jobs[name,lastBuild[number,duration,timestamp,result,changeSet[items[msg,author[fullName]]]]]";
  //http://build.esendex.com/api/json?pretty=true&depth=3&tree=jobs[name,color,downstreamProjects[name],upstreamProjects[name],lastBuild[number,builtOn,duration,timestamp,result,actions[lastBuiltRevision[branch[name]]],changeSet[items[msg,author[fullName],date]]]]
  var request = HttpRequest.request(url).then(onDataLoaded);
}

Mesh addCube(double cubeSize, double xOffset, double yOffset, int Colour) {
// Cube

  List materials = [];

  var rnd = new Math.Random();
  for ( int i = 0; i < 6; i ++ ) {
    materials.add( new MeshBasicMaterial( color: Colour ) );
  }

  cube = new Mesh( new CubeGeometry( cubeSize, cubeSize, cubeSize, 1, 1, 1, materials ), new MeshFaceMaterial(materials));// { 'overdraw' : true }) );
  cube.position.x = xOffset;
  cube.position.y = yOffset;
  //cube.overdraw = true; //TODO where is this prop?
  scene.add( cube );
  return cube;

  // Plane
  //plane = new Mesh( new PlaneGeometry( cubeSize, cubeSize), new MeshBasicMaterial( color: 0xe0e0e0, overdraw: true ) );
  //plane.position.x = xOffset;
  //plane.rotation.x = - 90.0 * ( Math.PI / 180.0 );
  //plane.overdraw = true; //TODO where is this prop?
  //scene.add( plane );
}

void onDocumentMouseDown( event ) {
  event.preventDefault();

  evtSubscriptions = [
    document.onMouseMove.listen(onDocumentMouseMove),
    document.onMouseUp.listen(onDocumentMouseUp),
    document.onMouseOut.listen(onDocumentMouseOut)
    ];

  mouseXOnMouseDown = event.client.x - windowHalfX;
  targetRotationOnMouseDown = targetRotation;

  print('onMouseDown mouseX = $mouseXOnMouseDown targRot = $targetRotationOnMouseDown');
}

void onDocumentMouseMove( event ) {
  mouseX = event.client.x - windowHalfX;

  targetRotation = targetRotationOnMouseDown + ( mouseX - mouseXOnMouseDown ) * 0.02;

  print('onMouseMove mouseX = $mouseX targRot = $targetRotation');
}

void cancelEvtSubscriptions() {
  evtSubscriptions.forEach((s) => s.cancel());
  evtSubscriptions = [];
}

void onDocumentMouseUp( event ){
  cancelEvtSubscriptions();
}

void onDocumentMouseOut( event ) {
  cancelEvtSubscriptions();
}

void onDocumentTouchStart( event ) {
  if ( event.touches.length == 1 ) {
    event.preventDefault();

    mouseXOnMouseDown = event.touches[ 0 ].page.x - windowHalfX;
    targetRotationOnMouseDown = targetRotation;
  }
}

void onDocumentTouchMove( event ) {
  if ( event.touches.length == 1 ) {
    event.preventDefault();

    mouseX = event.touches[ 0 ].page.x - windowHalfX;
    targetRotation = targetRotationOnMouseDown + ( mouseX - mouseXOnMouseDown ) * 0.05;
  }
}

animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

var radius = 600;
var theta = 0;

void render() {
  //plane.rotation.z = cube.rotation.y += ( targetRotation - cube.rotation.y ) * 0.05;
  theta += 0.1;

  //camera.position.x = radius * Math.sin( Math.degToRad( theta ) );
  //camera.position.y = radius * Math.sin( Math.degToRad( theta ) );
  //camera.position.z = radius * Math.cos( Math.degToRad( theta ) );
  //camera.lookAt( scene.position );

  renderer.render( scene, camera );
  //renderer.render( scene, camera );
}

void onDataLoaded(HttpRequest req) {
  // decode the JSON response text using JsonObject
  //JsonObject data = new JsonObject.fromJsonString(req.responseText);
  Jobs jobsData = new Jobs(req.responseText);
  
  renderObjectCount = 0;
  var cubesPerSide = Math.sqrt(jobsData.jobs.length).ceil();
  print(cubesPerSide);
  jobsData.jobs.sort((x,y) => x.compareTo(y));
  handleJobs(jobsData.jobs, cubesPerSide);
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

void handleJobs(List<Job> currentJobs, int cubesPerSide)
{
  var cubeSize = 500 / cubesPerSide;
  var objectCount = 0;
  var xOffset = -450;
  var yOffset = 100;
    
  for(var x=0; x < cubesPerSide; x++) {
    for (var y=0; y < cubesPerSide; y++) {
      if (objectCount++ < currentJobs.length) {
        Job currentJob = currentJobs[x * cubesPerSide + y];
        int colour = 0x42145f;
        if (currentJob.lastBuild != null) 
        {
          if (currentJob.lastBuild.result != null) 
          { 
            if (currentJob.lastBuild.result == "FAILURE") 
            { 
              print("failure");
              colour = 0xff0000; 
            }
          }
        }
        addCube(cubeSize, xOffset + x*cubeSize, yOffset + y*cubeSize, colour);
      }
    }
  }
  currentJobs.forEach((currentJob) => handleJob(currentJob));
}

void handleCategories(Map<String,List<Job>> categories) {
  var categoryCount = categories.length;
  for (var category in categories) {
    
  }
    for (var y=0; y < categories[x].length; y++) {
      List<Job> jobList = categories[x];
      print(jobList[y].name);
      Job currentJob = jobList[y];
      if (currentJob.lastBuild.result == "FAILURE") { print('oops!'); }      
    }
  }
}

void handleCategory()

void handleJob(Job currentJob)
{
  if (currentJob.lastBuild != null) {
    var lastBuildNumber = currentJob.lastBuild.number;
    
    if (currentJob.lastBuild.result == null) { 
      // BUILDING NOW
      var nowAsEpochMilliseconds = new DateTime.now().millisecondsSinceEpoch;
      var duration = new Duration(milliseconds: (nowAsEpochMilliseconds - currentJob.lastBuild.timestamp)).inSeconds;
      
    }
    else {
      // not building - switch on status?
      //addCube(50.0, -50.0 * renderObjectCount, 150.0);
      renderObjectCount++;
      if (currentJob.lastBuild.result == "FAILURE") {
      
      
      }
  }
}
}

