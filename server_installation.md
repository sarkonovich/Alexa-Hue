#### Alexa-Hue Server Installation ####



The server requires ruby 2.0 or above, and some Ruby Gems.

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

###### Troubleshooting ######

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