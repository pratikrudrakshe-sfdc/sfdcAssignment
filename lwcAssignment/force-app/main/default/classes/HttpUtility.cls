/*
 * Utility class for callouts to external systems.
*/
public with sharing class HttpUtility {
    public static Map<String, Object> makeCallout(String method, String pathUrl, String body) {
        HttpResponse response;
        Map<String,Object> resultMap = new Map<String,Object>();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(pathUrl);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        response = http.send(request);
        //range of 200 - 299 are success else error
        if(response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            resultMap.put('success', true);
        }
        else {
            resultMap.put('success', false);
            resultMap.put('message', response.getBody());
        }
        
        return resultMap;
    }
}