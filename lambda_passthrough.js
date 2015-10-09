var http = require('http');
var URLParser = require('url');
 
exports.handler = function (json, context) {
    try {
        // A list of URL's to call for each applicationId
        var handlers = {
            'appId':'url',
            'amzn1.echo-sdk-ams.app.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx':' http://xxxxxxxx.ngrok.io/lights'
        };
        
        // Look up the url to call based on the appId
        var url = handlers[json.session.application.applicationId];
        if (!url) { context.fail("No url found for application id"); }
        var parts = URLParser.parse(url);
        
        var post_data = JSON.stringify(json);
        
        // An object of options to indicate where to post to
        var post_options = {
            host: parts.hostname,
            auth: parts.auth,
            port: (parts.port || 80),
            path: parts.path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': post_data.length
            }
        };
        // Initiate the request to the HTTP endpoint
        var req = http.request(post_options,function(res) {
            var body = "";
            // Data may be chunked
            res.on('data', function(chunk) {
                body += chunk;
            });
            res.on('end', function() {
                // When data is done, finish the request
                context.succeed(JSON.parse(body));
            });
        });
        req.on('error', function(e) {
            context.fail('problem with request: ' + e.message);
        });
        // Send the JSON data
        req.write(post_data);
        req.end();        
    } catch (e) {
        context.fail("Exception: " + e);
    }
};