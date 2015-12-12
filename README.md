Elvue
-----

Elvue is a single HTML page and JavaScript file that provides graphical and 
tabular reporting on top of an [ELMAH][elmah] log:

![Elvue screen shot][ipadshot]

Copy `elvue.html` and `elvue.js` to a location within a web application where 
ELMAH is deployed and configured (the handler registration is required). Next, 
add a JavaScript file named `elvuecfg.js` in the same directory with the 
following content:

    config = {
      // uncomment and set options below as needed
      // title: 'TITLE', // report title
      // limit: 250,     // limit report to these most recent errors
      src: 'elmah.axd/download'
    };

Update the value of the `src` property of the `config` object to reflect the 
location of the ELMAH log download URL for your deployment. You can obtain 
this URL from the **Download Log** link that appears in the navigation bar 
when viewing a page of logged errors in the browser using ELMAH's built-in 
web pages.

Launch a browser (currently tested in IE, Chrome and Safari) and enter the 
URL of where `elvue.html` can be reached. If all goes well, you should see a 
report building up dynamically as your error log is scanned.

**IMPORTANT!** Do not forget to secure access to `elvue.html` and 
`elvuecfg.js` to authorized users only!

For background on how Elvue works, see [Error Log Download 
Applications][errdlapps] wiki on the [ELMAH project site][elmah].

Got ideas on how to improve or enhance Elvue? Come [discuss][devgrp], 
clone and contribute!


  [elmah]: https://elmah.github.io/
  [ipadshot]: http://wiki.elmah.googlecode.com/hg/elvue.png
  [errdlapps]: https://bytebucket.org/project-elmah/gcwiki/raw/0a421a57ebe054ac7c2da66ff6d27ce8fde0c7fb/elvue.png
  [devgrp]: http://groups.google.com/group/elmah-dev