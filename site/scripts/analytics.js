(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

ga('create', 'UA-41925840-1', 'webster.io');
ga('send', 'pageview');

window.addEventListener('message', function(event) {
  if (event.data.type == 'pageview') {
    ga('send', 'pageview', window.location.pathname);
  }
});