/*
Mock test class to cover negative callouts logic as it is not allowed to call webservices from test methods.
*/
@isTest
global class ErrorMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('request failed');
        response.setStatusCode(400);
        return response;
    }
}