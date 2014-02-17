part of jenkins;

class Computers {
  Computers() {
    var url = "http://build.esendex.com/computer/api/json?depth=2&tree=busyExecutors,computer[displayName,idle,numExecutors,executors[currentExecutable[building,fullDisplayName,timestamp,number,url],number]]";
    var request = HttpRequest.request(url).then(onDataLoaded);
  }
  
  void onDataLoaded(HttpRequest req) {
    print (req.responseText);
  }
}