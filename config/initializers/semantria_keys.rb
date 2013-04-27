# Bigdata::Application.config.semantria_key = '6c521695-1e3c-457b-87ba-69146c63f48c'
# Bigdata::Application.config.semantria_secret = 'd7430ea3-7412-4ac8-90c9-def48d69a47a'

Bigdata::Application.config.semantria_key = '4f755fe0-0968-4b0b-8ce4-9f95b5d2b47f'
Bigdata::Application.config.semantria_secret = '2a21a23b-ec7a-42b2-85b0-0b35dbd0dbb2'

# set up semantria session

$semantria_session = Session.new(Bigdata::Application.config.semantria_key, Bigdata::Application.config.semantria_secret, 'ForJusticeApp', true)
