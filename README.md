##Alexa Hue##

###Control Hue Lights with Alexa###

Well, you already can turn them on and off and dim them with Alexa. But this Alexa program gives you much more control: change colors, recall scenes, save scenes, set timers, turn on dynamic effects (color loops and alerts) and, of course, turn them on and off and dim them.


Since Amazon does not give 3rd party developers a way to access your local network, we need a bit of a workaround. This skill has two components:

1. An Amazon Alexa Lambda function -- thanks to [Matt Kruse](https://forums.developer.amazon.com/forums/profile.jspa?userID=13686) -- on AWS that just passes the Alexa request onto...
2. A server on your local network that does have access your Hue Bridge.

To deploy the Lambda function, you'll need to set up a developer account at the [developer portal.](developer.amazon.com/home.html)

For information on how to set up the Lambda function, look at the instructions [here.](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/developing-an-alexa-skill-as-a-lambda-function)

(In particular, follow the steps under "Creating a Lambda Function for an Alexa Skill")

Add your code as Node.js. Just copy and paste lambda_passthrough.js in the code editor.

Then in the Amazon [developer portal](developer.amazon.com/home.html), you'll need to create a new skill, and point it to your Lambda function by selecting 'Lambda ARN' and filling in the field with the proper resource name.  After that, fill in the interaction model, custom slot values, and utterance samples. You'll also get to choose an invocation name (e.g., "hue lights", or "custom lighting", etc.) 

When creating the custom slot values, substitute in your scenes, light, and group names. Single bulbs should be indicated by 'light' (e.g, "kitchen light") and groups with 'lights' (e.g., "living-room lights.) 

######A couple of caveats:
1. The Lights slot will hyphenate some two word names. (This is a bug on Amazon's end....they say they're working on it.) So, if things aren't working, you might need to change the light/group name on your bridge (e.g., from "living room" to "living-room".)
2. You can only recall scene names you can speak. Many apps store scenes on the bridge with alphanumeric codes, and then provide user friendly names in the app. Unfortunately, Alexa can't get at those scenes. However, you can create scenes with Alexa friendly names within the skill. Just set up the lights how you like and say, "Alexa, tell [invocation name] to save scene as [name]. Then, add 'name' as a SCENE custom slot value.

You need to set up the local Sinatra server. Place ````app.rb````, ````lights.rb````, ````alexa_objects.rb````, and ````fix_schedule_syntax.rb```` in the same directory. Open up a terminal in that directory and type

````gem install hue_switch````

to install a ruby gem. Then,

````ruby app.rb````

to start the server on port 4567.

Almost done!

You need some way to expose the server to the internets. I like to use an [ngrok](https://ngrok.com/) tunnel.
Download the appropriate version of the program and start it up like this:

````./ngrok http 4567````

Andd you can add a bit of security by requiring basic auth credentials

````./ngrok http -auth="username:password" 4567````

(For a bit more security, uncomment the application id check on line 15 of lights.rb and plug in the application id of your skill from the developer's portal.)

If using ngrok, you'll end up looking at something like this, which is the public IP address of the tunnel to your local server.
                                                                                    
````Forwarding  http://bb1bde4a.ngrok.io -> localhost:4567````                                                                  
   
Finally, head back to the lambda function on aws and replace the application_id and url with the application_id of your skill (found in the developer portal) and the ip address of your server (e.g., the ip address of your ngrok tunnel.) So, line 9 (or so) of the Lambda function might look something like this:

```` 'amzn1.echo-sdk-ams.app.3be28e92-xxxx-xxxx-xxxx-xxxxxxxxxxxx':'http://username:password@bb1bde4a.ngrok.io/lights' ````

(If you end up using this alot, it would probably make sense to pay ngrok $5 and get a reserved address for you tunnel. That way you won't have to change the lambda function everytime you restart the ngrok tunnel.)


If you've added some basic auth to the tunnel, use the following format to specify the route to your local server in the lambda function:

````http://username:password@bb1bde4a.ngrok.io/lights````

At this point the skill should be available to you. You can say things like:

*"Alexa, tell [whatever invocation name you chose] to turn the kitchen lights blue."*
*"Alexa, tell...set the floor light to saturation ten and brightness five"*
*"Alexa, tell...change the table light to the color relax"*
*"Alexa, tell...turn off the bedroom lights in 5 minutes"*
*"Alexa, tell...turn on the lights at eight forty five p.m."*
*"Alexa, tell...set dinner scene in one hour"*
*"Alexa, tell...start color loop on the bedside light"*
*"Alexa, tell...start long alert on the kitchen lights in forty five seconds"*
*"Alexa, tell...stop alert"*


You can use the "flash" command instead of "long alert." (It's just easier to say.) It's also helpful for using your lights as a timer:

*"Alexa, tell...to flash the lights in five minutes."*

