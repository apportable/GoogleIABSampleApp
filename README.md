IABSample
=========

###IMPORTANT NOTE 
This sample app requires access to Apportable software that is currently granted on an invite-only basis.  If you are using the Apportable SDK, please refer to the [docs site](http://docs.apportable.com/publishing#storekit-google-play) for information regarding implementing Google in-app billing and in-app products.

###Introduction
This is yet another In-App biling sample application. It has the same features as the Google official IAB-Sample, which you can find it [here](https://code.google.com/p/marketbilling/source/browse/v3/src/com/example/android/trivialdrivesample/?r=5f6b7abfd0534acd5bfc7c14436f4500c99e0358#trivialdrivesample%253Fstate%253Dclosed). The only difference is that the app in this repository is written in Objective-C. Amazing, isn't it?

The purpose of this sample is a proof of concept that objective-c developers can construct an android application using their favorite programming language. This applications demostrates:

  1. The structure of the android project written in objective-c.
  2. Project building configuration in XCode.
  3. How to invoke the android sdk using objective-c.
  4. How to use map R.java and use resources.
  5. How to stub .aidl and call method in objective-c.
  
###Prerequisite:

  1. Download apportable sdk
  2. Download and install apportable xcode plugin (IMPORTANT NOTE: this functionality is invite-only right now)
  3. Find an android phone or buy a new one on [newegg](http://www.newegg.com/Product/ProductList.aspx?Submit=ENE&DEPA=0&Order=BESTMATCH&Description=android&N=-1&isNodeId=1)
  
###Configure on Google Play:

  1. Create an application on the Developer Console.
  2. In that app, create MANAGED in-app items with these IDs: premium, gas.
     
     Set their prices to 0.99 dollar.
  3. In that app, create a SUBSCRIPTION items with this ID: infinite_gas
     
     Set the price to 0.99 dollar and the billing recurrence to monthly. 
  4. Make sure your test account (the one you will use to test purchases) is correctly listed in the "testing" section. 
  
     Your test account CANNOT BE THE SAME AS THE PUBLISHER ACCOUNT.
  5. Grab the application's public key (a base-64 string). You can find the application's public key in the "Services & API" page for your application.
  6. Finish the mandatory sections in the console so that you can publish the app.
     
     It is not necessary to push the application in production. Alpha, and beta should be fine but the app must be published instead of in draft mode.
  
###Build Project in Xcode:
  1. Replace the public key in IABSample.m, line 217. Replace the string with the public key you got from step 5 in the last section.
  2. Open the project using XCode with apportable plugin.
  3. Set the deploying device to your USB connected device and click run.

###Feedback:
  
  Please send email to sdk@apportable.com and sean@apportable.com. Pull request is also highly recommended.
