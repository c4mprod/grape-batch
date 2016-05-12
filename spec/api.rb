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
        requires :id, type: Integer, desc: 'User id.'
      end
      route_param :id do
        get do
          "user #{params[:id]}"
        end
      end
    end

    resource :complex do
      params do
        requires :a, type: Hash
      end
      get do
        "hash #{params[:a][:b][:c]}"
      end
    end

    resource :status do
      params do
        requires :id, type: Integer, desc: 'User id.'
      end
      get do
        "status #{params[:id]}"
      end

      params do
        requires :id, type: Integer, desc: 'User id.'
      end
      post do
        "status #{params[:id]}"
      end
    end

    resource :login do
      get do
        request.env['HTTP_X_API_TOKEN'] = 'user_token'

        'login successful'
      end

      post do
        if env['HTTP_X_API_TOKEN'] == 'user_token'
          'token valid'
        else
          'token invalid'
        end
      end
    end

    resource :session do
      get do
        request.env['api.session'] = OpenStruct.new(nick: 'Bob')

        'session reloaded'
      end

      post do
        if env['api.session'] && env['api.session'].nick == 'Bob'
          'session valid'
        else
          'session invalid'
        end
      end
    end

    # 404
    #
    route :any, '*path' do
      error!("#{@env['PATH_INFO']} not found", 404)
    end
  end
end
