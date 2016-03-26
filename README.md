##Alexa Hue##

###Control Hue Lights with Alexa###

Well, you already can turn them on and off and dim them with Alexa. But this Alexa program gives you much more control: change colors, recall scenes, save scenes, set timers, turn on dynamic effects (color loops and alerts) and, of course, turn them on and off and dim them.

Demo here: https://youtu.be/JBZlaAQtOXQ


Since Amazon does not give 3rd party developers a way to access your local network, we need a bit of a workaround. This skill has two components:

1. An Amazon Alexa Lambda function -- thanks to [Matt Kruse](https://forums.developer.amazon.com/forums/profile.jspa?userID=13686) -- on AWS that just passes the Alexa request onto...
2. A server on your local network that does have access your Hue Bridge.

To deploy the Lambda function, you'll need to set up a developer account at the [developer portal.](https://developer.amazon.com/home.html)

For information on how to set up the Lambda function, look at the instructions [here.](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/developing-an-alexa-skill-as-a-lambda-function)

(In particular, follow the steps under "Creating a Lambda Function for an Alexa Skill")

When you get to the step that says, "When you are ready to add your own code, edit the function and select the Code tab," you'll be copying and pasting in the text from lambda_passthrough.js. Add your code as Node.js. Just copy and paste lambda_passthrough.js in the code editor.

Then in the Amazon [developer portal](https://developer.amazon.com/edw/home.html#/skills), you'll need to create a new skill.

1. For "Name" pick anything you want.
2. For "Invocation Name" pick anything you want. This is the name you'll use to open the skill (e.g., "Alexa, tell house lighting to....")
3. For "Version Number"...anything. How about 0.0.1?
4. For "Endpoint" select 'Lambda ARN' and point it to your Lambda function by filling in the field with the proper resource name. Just go to your Lambda Function in the AWS Console. The ARN will look something like this:  arn:aws:lambda:us-east-1:123456789805:function:my_function
5. On the next page fill in the interaction model, custom slot values, and utterance samples by copying and pasting the info from intent_schema.txt, sample_utterances.txt and custom_slots.txt onto the appropriate form fields. 
6. Create custom slots first. In the "custom slot type" section, you'll see a button "Add Slot Type." Click on that. Add the slot name in the "Enter Type" box.  The name will be one of the all caps names from the custom_slots.txt, e.g., LIGHTS or ATTRIBUTE. Then paste in the values (they appear just below that all caps name in the custom_slots.txt), one value per line, in the "Enter Values" box. Then click  "OK."  In the end you're going to create 7 different custom slots. 
7. Copy/paste the contents of intent_schema.txt into the "Intent Schema" box.
8. Copy/paste the contents of utterance_samples.txt into the "Sample Utterances" box.

Now, for the custom slot values "LIGHTS" and "SCENES" substitute in the appropriate values for your lights and scenes. For lights, single bulbs should be indicated by 'light' (e.g, "kitchen light") and groups with 'lights' (e.g., "living room lights.) 



The program requires ruby 2.0 or above, and some Ruby Gems.

First, check that you've got a proper version of Ruby installed. In a terminal window just type
````ruby --version````

Make sure that you've got 2.0.0 or above.

If you don't have Ruby installed, you'll need to install it.

For Windows, just use [RubyInstaller](http://rubyinstaller.org/downloads/)

For OSX or Linux, I suggest using RVM. Instructions are [here.](https://rvm.io/rvm/install)

Once RVM is installed (again, only install RVM if you're not using Windows+RubyInstaller), install a recent version of ruby
````rvm install 2.2.0 --disable-binary````

Double-check that you've got Ruby installed.

````ruby --version````


Now that you've gotten Ruby installed, create a directory that's convenient to get to (maybe on your desktop...)  Call it whatever you want. Copy all of the files from this repository into that directory. Open up a terminal window in that directory and type

````bundle install````

to install the needed gems. If you don't already have bundler installed (and you get errors on the last step) you might need to

````gem install bundler````

and the repeat the last step. If you get the message ````(Errno::EACCESS) Permission Denied```` error, look below. DON'T USE sudo
to avoid it! Finally, 


````ruby app.rb````

to start the server on port 4567.

######Troubleshooting######

Here are some possible errors you might get at this point

1. *Syntax Errors in alexa_objects.rb.* 
You dont' have ruby 2.0 or above installed, or are not using it to run the program Make sure you're actually *using* the version you installed with rvm. Type ````rvm use 2.0```` (or whatever version you installed) in the terminal window and start up the server (````ruby app.rb````) again.

2. *You get an RVM is not a function error*. You didn't install rvm correctly, maybe you used sudo to do the install. Type
````/bin/bash --login```` in the terminal window and then try to startup the server again.

3. *You get a message that required gems are missing.* If ````bundle install```` completed successfully and you're getting this message, the gems are not installed in the directory the program  is looking at. You can type ````gem list```` to see the available gems. The solution here is probably the same as in step one. ````rvm use 2.0```` (or whatever version you installed) and try again to start the server. That should work.

4. *You can a (Errno::EACCESS) Permission Denied error. The same solution as in 1. 
Type ````rvm use 2.0```` (or whatever version you installed) in the terminal

If you now get a message like error 2, just use the solution that's in 2.

Whew! Almost done!

#####NGROK#####

You need some way to expose the server to the internets. I like to use an [ngrok](https://ngrok.com/) tunnel.
Download the appropriate version of the program, open up a **new** terminal window, and start it up like this:

````./ngrok http 4567````

Andd you can add a bit of security by requiring basic auth credentials

````./ngrok http -auth="username:password" 4567````

(For a bit more security, uncomment the application id check on line 16 of lights.rb and plug in the application id of your skill from the developer's portal.)

If using ngrok, you'll end up looking at something like this, which is the public IP address of the tunnel to your local server.
                                                                                    
````Forwarding  http://bb1bde4a.ngrok.io -> localhost:4567````                                                                  
   
Finally, head back to the lambda function on aws and replace the application_id and url with the application_id of your skill (found in the developer portal) and the ip address of your server (e.g., the ip address of your ngrok tunnel.) So, line 9 (or so) of the Lambda function might look something like this:

```` 'amzn1.echo-sdk-ams.app.3be28e92-xxxx-xxxx-xxxx-xxxxxxxxxxxx':'http://username:password@bb1bde4a.ngrok.io/lights' ````

(If you end up using this alot, it would probably make sense to pay ngrok $5 and get a reserved address for you tunnel. That way you won't have to change the lambda function everytime you restart the ngrok tunnel.)


If you've added some basic auth to the tunnel, use the following format to specify the route to your local server in the lambda function:

    http://username:password@bb1bde4a.ngrok.io/lights

Before you can use the skill, you'll need to give it access to your Hue bridge. Press the link button on your bridge and launch the skill (within, I think, 30 seconds or so.)

If you don't do this step, Alexa will remind you.

At this point the skill should be available to you. You can say things like:

*"Alexa, tell [whatever invocation name you chose] to turn the kitchen lights blue."*

*"Alexa, ask [whatever invocation name you chose] for blue kitchen lights."*

*"Alexa, ask [whatever invocation name you chose] for a dark red bedside light."*

*"Alexa, ask [whatever invocation name you chose] to set romantic scene."*

*"Alexa, ask [whatever invocation name you chose] for romantic scene."*

*"Alexa, ask [whatever invocation name you chose] for a green bedside light."*

*"Alexa, tell [whatever invocation name you chose] to turn the bedroom lights dark red."*

*"Alexa, tell...set the floor light to saturation ten and brightness five"*

*"Alexa, tell...schedule dinner scene at 8:30 pm"*

*"Alexa, tell...change the table light to the color relax"*

*"Alexa, tell...turn off the bedroom lights in 5 minutes"*

*"Alexa, tell...turn on the lights at eight forty five p.m."*

*"Alexa, tell...set dinner scene in one hour"*

*"Alexa, tell...start color loop on the bedside light"*

*"Alexa, tell...stop color loop on the bedside light"*

*"Alexa, tell...start long alert on the kitchen lights in forty five seconds"*

Preprogrammed colors include pink, orange, green, red, turqoise, blue, purple, and violet. All these colors accept the modifiers "dark" and "light" (e.g., "dark blue", "light pink."). You can also specify the following mired colors: candle, relax, reading, neutral, concentrate, and energize. You can add your own colors, or adjust the values of the existing ones, by editing lines 254 and 255 of hue.switch.rb

####Groups and Scenes####

Alexa Hue gets information about groups and scenes from your Hue Bridge. You can get information about what groups, scenes, and lights you have on the bridge just by asking. The relevant information will be sent to a card in your Alexa app:

*"Alexa, ask....what groups do I have?"*

*"Alexa, ask....what lights do I have?"*

*"Alexa, launch....what are my scenes?"*

There are a few things to keep in mind. First, the Alexa app stores groups locally, in the app, not on the bridge. So any scenes you created in the Alexa app will have to be recreated on the bridge. Second, you'll only be able to recall groups and scenes that are stored on the bridge with pronounceable names. Even when an application stores the scenes on the bridge, it may append alphanumeric strings to your scene and groups names --  "living room" becomes "living room on 45hdjsldfk4", for example -- so you wouldn't be able to recall that just by asking.

There are two solutions.

The first is to find an app that a) stores the scene on the bridge and b) doesn't mess with the name. I recommend "All 4 Hue" available for [Android.](https://play.google.com/store/apps/details?id=de.renewahl.all4hue&hl=en), but I assume many others will work as well. (Note: the official hue app is **not** one of the them.)

Create a scene in an app that meets requirements a) and b) and then add the scene name as a value in the SCENES custom slot.
(You can tell if the application stored the scene correctly on the bridge by asking the skill for your scenes, and making sure that the scene shows up with the name you expect.)

The second solution is to save scenes from within the skill. Just set up the lights the way you'd like. Then you can say, for example:

*"Alexa, tell....to save scene as dinner"*

Or, to save the scene for just a group:

*"Alexa, tell....to save scene as romantic on the kitchen lights."*

This method is probably not as reliable as the first, but it works. It will work a lot better if you add the name of the scene you are creating to the SCENES custom slot values *before* you save the scene.

**Why do I have to keep adding the names of the scenes/groups in the developer's portal?** I have not included lots and lots of sample utterances or custom slot values. Because of this, the voice recognition for arbitrary words will not be very good. However, the recognition for the supplied values will be very, very good. (It's a trade off.) Since you you using this to control just your lights, there's no need for the program to recognize just anything you say. *Remember*, even if you add scenes with an app, recognition will be much better if you add the scene (and group, and light) names as values in the relevant custom slot.

**Alexa keeps saying she can't find a group (light, or scene) named "Marks Room" even though I know there it exists?**  This is likely a voice recognitions problem. Look in the settings tab of the Alexa app, under history. There you can see exactly what Alexa heard for everthing you say. Perhaps she heard "Marcs room"? This shouldn't happen if you've added the name of the light/group/scene as a value in the relevant custom slot, but who knows? Alexa is not constrained to recognize only those values

**Alexa keeps asking me to specify a light or lights, but I did.** Again, this is likely a recognition problem. Check that she heard what you correctly. For example, she might be hearing "recipe like" instead of "recipe light." I've taken care of a couple common mistakes in the app (you can say "turn on the bedroom like" and it will still work), but there might be others. In the history section of the app you can give feedback and tell Alexa that she misheard. If you do this a few times, she usually corrects the error.