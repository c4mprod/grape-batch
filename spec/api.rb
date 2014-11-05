module Twitter
  class API < Grape::API
    version 'v1', using: :path
    format :json
    prefix 'api'

    resource :hello do
      get do
        'world'
      end

      post do
        'world'
      end
    end

    resource :failure do
      desc 'Failure'
      get do
        error!('Failed as expected', 503)
      end
    end

    resource :user do
      params do
        requires :id, type: Integer, desc: "User id."
      end
      route_param :id do
        get do
          "user #{params[:id]}"
        end
      end
    end

    resource :status do
      params do
        requires :id, type: Integer, desc: "User id."
      end
      get do
        "status #{params[:id]}"
      end

      params do
        requires :id, type: Integer, desc: "User id."
      end
      post do
        "status #{params[:id]}"
      end
    end

    # 404
    #
    route :any, '*path' do
      error!("#{@env['PATH_INFO']} not found", 404)
    end
  end
end
