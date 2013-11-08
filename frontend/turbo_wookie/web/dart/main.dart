import "package:polymer/polymer.dart";
import "dart:html";
//import "dart:web_audio";

void main() {
  initPolymer();
  print("\t\t\t__TURBO WOOKIE__");

  //loadData();
}

void loadData() {
  String url = "http://shtuff.kuntz.co/deepnote.ogg";

  HttpRequest.getString(url).then(onDataLoaded);
}

void requestComplete(HttpRequest request) {
  if(request.status == 200)
    print("request complete: ${request}");
  else
    print("Status Not 200: ${request.status}");
}

void onDataLoaded(String responseText) {
  print(responseText);
}