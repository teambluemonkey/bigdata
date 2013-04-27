class SessionCallbackHandler < CallbackHandler
  def onRequest(sender, args)
    # puts "Put in a request: #{args}"
  end

  def onResponse(sender, args)
    # puts "Got a resposne: #{args}"
    $data_done = true
  end

  def onError(sender, args)
    print 'Error: ', args, "\n"
  end

  def onDocsAutoResponse(sender, args)
    #print "DocsAutoResponse: ", args.length, args, "\n"
  end

  def onCollsAutoResponse(sender, args)
    #print "CollsAutoResponse: ", args.length, args, "\n"
  end
end


class GuardianController < ApplicationController

  def index
    render json: {action: "index"}
  end

  def show
    # use guardian to get data out

    url = params[:id].gsub("http://www.guardian.co.uk", "")

    data = RestClient.get "http://content.guardianapis.com#{url}", {:params => {"api-key" => Bigdata::Application.config.guardian_api_key, 'show-fields' => 'all', 'show-tags' => 'all'}}

    json_data = JSON.parse(data)

    # json_data["response"]["content"]["fields"]["body"] = ActionView::Base.full_sanitizer.sanitize(json_data["response"]["content"]["fields"]["body"])

    sanitized_data = ActionView::Base.full_sanitizer.sanitize(json_data["response"]["content"]["fields"]["body"])

    doc = {'id' => rand(10 ** 10).to_s.rjust(10, '0'), 'text' => sanitized_data}

    semantria_session = Session.new(Bigdata::Application.config.semantria_key, Bigdata::Application.config.semantria_secret, 'ForJusticeApp', true)

    callback = SessionCallbackHandler.new

    semantria_session.setCallbackHandler(callback)

    # Queues document for processing on Semantria service
    status = semantria_session.queueDocument(doc)

    $data_done = false

    wait_for_semantria = false

    # puts "Status: #{status}"
    puts "Status: #{status.inspect}"
  
    if status == 202
      puts "Document '#{doc['id']}' queued successfully."
      wait_for_semantria = true
    end

    semantria_result = semantria_session.getProcessedDocuments()

    begin
      puts "Waiting..."
      # ARG
      sleep 0.1
    end while (wait_for_semantria && !$data_done)

    render json: {action: "show", article: params[:id], article_data: json_data, article_body: sanitized_data, semantria_data: semantria_result}
  end

end