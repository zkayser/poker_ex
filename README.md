# PokerEx

[Visit the App now](https://ancient-forest-15148.herokuapp.com/)

PokerEx is a basic Texas Hold 'Em system implemented in Elixir that takes
advantage of the Phoenix Framework and Phoenix Channel module to deliver
real-time features. 

The system has a dependency on the Elixir Registry module which requires 
Elixir 1.4.0 or later, as well as a dependency on Erlang's :gen_statem 
module which will require Erlang 19.1 or later to work properly.

If you are cloning this repo, note that the app relies on the Bamboo
library for sending emails through Sendgrid. If you want to use the same
setup, you will need to get an API key from Sendgrid and setup
a SENDGRID_API_KEY environment variable or the system will not start. The
configuration can be found in the /config/config.exs file. Feel free to
remove the dependency or use another service as well.