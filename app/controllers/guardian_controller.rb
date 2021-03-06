class SessionCallbackHandler < CallbackHandler

  def initialize(thing = false)
    @thing = thing
  end

  def onRequest(sender, args)
    # puts "Put in a request: #{args}"
  end

  def onResponse(sender, args)
    # puts "Got a resposne: #{args}"

    # sleep 0.1

    $data_done = true

    if (@thing)
      # sleep 0.1

      $data_comments_done = true
    end

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
    comment_url = params[:comment_url]

    # look for doc in mongodb
    existing_doc = Document.where(guardian_url: url).first

    if existing_doc.nil?

      #nasty
      json_data = nil
      semantria_data = nil
      sanitized_data = nil
      sanitized_result = nil
      semantria_result = nil
      $data_done = false
      $data_comments_done = false
      wait_for_semantria = false
      comment_data = []
      article_tags = []
      wait_for_semantria_comments = false
      c_semantria_result = nil

      hydra = Typhoeus::Hydra.hydra

      guardian_request = Typhoeus::Request.new(
        "http://content.guardianapis.com#{url}",
        method: :get,
        params: {
          "api-key" => Bigdata::Application.config.guardian_api_key,
          "show-fields" => "all",
          "show-tags" => "all",
        }
      )

      guardian_request.on_complete do |response|
        # response.body

        # puts response.body
        # puts response
        # puts response.inspect

        json_data = JSON.parse(response.body)

        # json_data["response"]["content"]["fields"]["body"] = ActionView::Base.full_sanitizer.sanitize(json_data["response"]["content"]["fields"]["body"])

        sanitized_data = ActionView::Base.full_sanitizer.sanitize(json_data["response"]["content"]["fields"]["body"]).strip

        doc_md5 = Digest::MD5.hexdigest(sanitized_data)

        doc = {'id' => doc_md5, 'text' => sanitized_data}

        semantria_session = Session.new(Bigdata::Application.config.semantria_key, Bigdata::Application.config.semantria_secret, 'ForJusticeApp', true)

        callback = SessionCallbackHandler.new

        semantria_session.setCallbackHandler(callback)

        #tags
        raw_article_tags = json_data["response"]["content"]["tags"]
        
        semantria_entities = []
        raw_article_tags.each do |tag|
          entity = {}
          entity["name"] = tag["webTitle"]
          entity["type"] = tag["type"]
          if !article_tags.include?(tag["webTitle"])
            semantria_entities.push(entity)
            article_tags.push(tag["webTitle"])
          end
        end

        puts "setting tags as entities"
        semantria_session.addEntities(semantria_entities)
        puts "finished setting tags as entities"

        # Queues document for processing on Semantria service
        status = semantria_session.queueDocument(doc)

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


      end

      hydra.queue guardian_request

      if !comment_url.nil?
        # do comment as well

        puts "COMMENTS GETTING YES"

        comment_request = Typhoeus::Request.new(comment_url)

        comment_request.on_complete do |response|

          doc = Nokogiri::HTML(response.body)

          doc.css('.d2-body').each do |node|
            comment = node.inner_html
            comment_data << ActionView::Base.full_sanitizer.sanitize(comment).strip
          end

          c_semantria_session = Session.new(Bigdata::Application.config.semantria_key, Bigdata::Application.config.semantria_secret, 'ForJusticeApp', true)

          c_callback = SessionCallbackHandler.new(true)

          c_semantria_session.setCallbackHandler(c_callback)

          comment_md5 = Digest::MD5.hexdigest(comment_data.join(","))

          c_doc = {'id' => comment_md5, 'documents' => comment_data}

          # Queues document for processing on Semantria service
          c_status = c_semantria_session.queueCollection(c_doc)

          puts "Status: #{c_status}"

          if c_status == 202
            puts "COMMENTS Document '#{c_doc['id']}' queued successfully."
            wait_for_semantria_comments = true
          end

          c_semantria_result = c_semantria_session.getProcessedCollections()

          begin
            puts "Waiting comments..."
            # ARG
            sleep 0.1
          end while (wait_for_semantria_comments && !$data_comments_done)

        end

        hydra.queue comment_request
      else

        puts "COMMENTS NO"

      end

      hydra.run

      # we has docs
      puts "OK CREATING NEW DOC"

      # make a new one
      new_doc = Document.new
      new_doc.guardian_url = url.to_s
      new_doc.guardian_comment_url = comment_url
      new_doc.guardian_data = json_data.to_json
      new_doc.guardian_sanitized_data = sanitized_data
      new_doc.semantria_data = semantria_result.to_json
      new_doc.semantria_comments_data = c_semantria_result.to_json
      new_doc.comment_data = comment_data
      new_doc.tags = article_tags
      if new_doc.save
        puts "DOC SAVED"
      else 
        puts "DOC NOT SAVED"
	puts new_doc.errors.inspect
      end

      displayed_doc = new_doc

    else # existing
      displayed_doc = existing_doc
    end

    # Processing
    # semantria_topics = semantria_result.first["topics"]
    # puts "Semantria Result #{semantria_result}"
    # sanitized_semantria = {"topics" => []}
    

    # semantria_topics.each do |topic|
    #   if (topic['strength_score'] > 0.6)
    #     sanitized_semantria["topics"].push( { "title" => "#{topic["title"]}" , "sentiment" => "#{topic["sentiment_polarity"]}"})
    #   end
    # end

    render json: {
      id: displayed_doc.id,
      action: "show",
      article: displayed_doc.guardian_url,
      article_data: JSON.parse(displayed_doc.guardian_data),
      article_body: displayed_doc.guardian_sanitized_data,
      semantria_data: displayed_doc.semantria_data                  != "null" ? JSON.parse(displayed_doc.semantria_data)          : nil,
      semantria_comment_data: displayed_doc.semantria_comments_data != "null" ? JSON.parse(displayed_doc.semantria_comments_data) : nil, 
      display_data: displayed_doc.display_data,
      comment_data: displayed_doc.comment_data,
      tags: displayed_doc.tags
    }
  end

end
