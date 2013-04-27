Bigdata::Application.config.semantria_key = '6c521695-1e3c-457b-87ba-69146c63f48c'
Bigdata::Application.config.semantria_secret = 'd7430ea3-7412-4ac8-90c9-def48d69a47a'

# set up semantria session

$semantria_session = Session.new(Bigdata::Application.config.semantria_key, Bigdata::Application.config.semantria_secret, 'TestApp', true)
