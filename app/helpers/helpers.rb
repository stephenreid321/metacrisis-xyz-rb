ActivateApp::App.helpers do
  def mass_assigning(params, model)
    params ||= {}
    if model.respond_to?(:protected_attributes)
      intersection = model.protected_attributes & params.keys
      raise "attributes #{intersection} are protected" unless intersection.empty?
    end
    params
  end

  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end

  def sign_in_required!
    return if current_account

    flash[:notice] = 'You must sign in to access that page'
    session[:return_to] = request.url
    request.xhr? ? halt(403) : redirect('/sign_in')
  end

  def f(slug)
    (if fragment = Fragment.find_by(slug: slug) and fragment.body
       "\"#{fragment.body.to_s.gsub('"', '\"')}\""
     end).to_s
  end

  def timeago(x)
    %(<abbr class="timeago" title="#{x.iso8601}">#{x}</abbr>)
  end

  def random(relation, n)
    count = relation.count
    (0..count - 1).sort_by { rand }.slice(0, n).collect! { |i| relation.skip(i).first }
  end

  def md(slug, render: true)
    begin
      text = open("#{Padrino.root}/app/markdown/#{slug}.md").read.force_encoding('utf-8')
      text.gsub!(/\A---(.|\n)*?---/, '')
      text.gsub!(/==(.|\n)*?==/) { |m| "<mark>#{m[2..-3]}</mark>" }
      text
    rescue StandardError
      text = slug
    end
    if render
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, fenced_code_blocks: true)
      markdown.render(text)
    else
      text
    end
  end
end
