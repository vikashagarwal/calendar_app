class ExampleController < ApplicationController
  def redirect
    client = Signet::OAuth2::Client.new(client_options)

    redirect_to client.authorization_uri.to_s
  end

  def callback
    client = Signet::OAuth2::Client.new(client_options)
    client.code = params[:code]

    response = client.fetch_access_token!

    session[:authorization] = response

    redirect_to calendars_url
  end

  def calendars
    client = Signet::OAuth2::Client.new(client_options)
    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    @calendar_list = service.list_calendar_lists
    @calendar_list.items.each do |cal|
      c = Calendar.find_by(external_id: cal.id)
      c = Calendar.new if c.blank?
      c.summary = cal.summary
      c.external_id = cal.id
      c.save! 
    end
    @calendars = Calendar.all
  rescue Google::Apis::AuthorizationError
    response = client.refresh!
    session[:authorization] = session[:authorization].merge(response)

    retry
  end

  def events
    client = Signet::OAuth2::Client.new(client_options)
    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    @event_list = service.list_events(Calendar.find(params[:calendar_id]).external_id)
  rescue Google::Apis::AuthorizationError
    response = client.refresh!
    session[:authorization] = session[:authorization].merge(response)

    retry
  end

  def new_event
    client = Signet::OAuth2::Client.new(client_options)
    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    today = Date.today

    event = Google::Apis::CalendarV3::Event.new({
      start: Google::Apis::CalendarV3::EventDateTime.new(date: today),
      end: Google::Apis::CalendarV3::EventDateTime.new(date: today + 1),
      summary: 'New event!'
    })

    service.insert_event(params[:calendar_id], event)

    redirect_to events_url(calendar_id: params[:calendar_id])
  rescue Google::Apis::AuthorizationError
    response = client.refresh!
    session[:authorization] = session[:authorization].merge(response)

    retry
  end

  private

  def client_options
    config = YAML.load_file("#{Rails.root}/config/calendar.yml")[Rails.env]
    {
      client_id: config['google_client_id'],
      client_secret: config['google_client_secret'],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: callback_url
    }
  end
end