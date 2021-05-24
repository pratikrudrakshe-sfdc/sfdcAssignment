/*
    Mock test class to cover positive callouts logic as it is not allowed to call webservices from test methods.
*/
@isTest
global class OrderMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('request caught');
        response.setStatusCode(200);
        response.setStatus('OK');
        return response;
    }
}