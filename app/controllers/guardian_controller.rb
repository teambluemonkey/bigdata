class GuardianController < ApplicationController

  def index
    render json: {action: "index"}
  end

  def show
    # use guardian to get data out

    url = params[:id].gsub("http://www.guardian.co.uk", "")

    data = RestClient.get "http://content.guardianapis.com#{url}", {:params => {"api-key" => Bigdata::Application.config.guardian_api_key, 'show-fields' => 'all', 'show-tags' => 'all'}}

    render json: {action: "show", article: params[:id], article_data: JSON.parse(data)}
  end

end