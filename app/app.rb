module ActivateApp
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers

    register Padrino::Cache
    enable :caching unless Padrino.env == :development

    require 'sass/plugin/rack'
    Sass::Plugin.options[:template_location] = Padrino.root('app', 'assets', 'stylesheets')
    Sass::Plugin.options[:css_location] = Padrino.root('app', 'assets', 'stylesheets')
    use Sass::Plugin::Rack

    use Rack::Session::Cookie, expire_after: 1.year.to_i, secret: ENV['SESSION_SECRET']
    use Rack::UTF8Sanitizer
    use Rack::CrawlerDetect
    use RackSessionAccess::Middleware if Padrino.env == :test
    use Dragonfly::Middleware
    use OmniAuth::Builder do
      provider :account
    end
    use Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get]
      end
    end
    OmniAuth.config.on_failure = proc { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }

    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'
    set :protection, except: :frame_options

    before do
      redirect "#{ENV['BASE_URI']}#{request.path}#{"?#{request.query_string}" unless request.query_string.blank?}" if ENV['REDIRECT_BASE'] && ENV['BASE_URI'] && (ENV['BASE_URI'] != "#{request.scheme}://#{request.env['HTTP_HOST']}")
      if params[:r]
        StephenReid::App.cache.clear
        redirect request.path
      end
      Time.zone = current_account && current_account.time_zone ? current_account.time_zone : 'London'
      fix_params!
      @og_image = "https://api.apiflash.com/v1/urltoimage?access_key=#{ENV['APIFLASH_KEY']}&url=#{ENV['BASE_URI']}#{request.path}&width=1280&height=672&ttl=2592000" unless Padrino.env == :development
    end

    error do
      Airbrake.notify(env['sinatra.error'], session: session)
      erb :error, layout: :application
    end

    not_found do
      erb :not_found, layout: :application
    end

    get '/', cache: true do
      @og_desc = 'A collective of technology experts exploring wise responses to the metacrisis'

      @posts = Post.all(filter: "AND(
        IS_AFTER({Created at}, '#{3.months.ago.to_s(:db)}'),
        {metacrisis.xyz} = 1,
        FIND('\"url\": ', {Iframely}) > 0
      )", sort: { 'Created at' => 'desc' }, paginate: false)

      erb :home
    end

    get '/:slug' do
      if @fragment = Fragment.find_by(slug: params[:slug], page: true)
        erb :page
      else
        pass
      end
    end
  end
end
