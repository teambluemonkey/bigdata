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

    render json: {action: "show", article: params[:id], article_data: json_data, article_body: sanitized_data}
  end

end