component accessors=true
{
  property type="string" name="keyFile";
  property type="string" name="serviceAccountID";
  property type="string" name="calendarID";
  property type="string" name="appName";
  property type="date" name="startDate";
  property type="boolean" name="singleEvents" default=false;

  this.root = getDirectoryFromPath(getCurrentTemplatePath());
  this.jl = new javaloader.javaloader( directoryList( this.root & "\java", true, "path", "*.jar" ));

  public google function init()
  {
    for( arg in arguments )
    {
      variables[arg] = arguments[arg];
    }

    jl = this.jl;

    HTTP_Transport = jl.create( "com.google.api.client.http.javanet.NetHttpTransport" ).init();
    JSON_Factory = jl.create( "com.google.api.client.json.jackson2.JacksonFactory" ).init();
    HTTP_Request_Initializer = jl.create( "com.google.api.client.http.HttpRequestInitializer" );

    Credential_Builder = jl.create( "com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder" );
    Collections = jl.create( "java.util.Collections" );
    FSkeyFile = jl.create( "java.io.File" ).init( this.root & "\credentials\" & getKeyFile());

    Calendar_Scope = jl.create( "com.google.api.services.calendar.CalendarScopes" ).CALENDAR;

    credential = Credential_Builder
        .setTransport( HTTP_Transport )
        .setJsonFactory( JSON_Factory )
        .setServiceAccountId( getServiceAccountId())
        .setServiceAccountScopes( Collections.singleton( Calendar_Scope ))
        .setServiceAccountPrivateKeyFromP12File( FSkeyFile )
        .build();

		Calendar_Builder = jl.create( "com.google.api.services.calendar.Calendar$Builder" ).init( HTTP_Transport, JSON_Factory, credential );

    return this;
  }

  public function getEvents()
  {
    var service = Calendar_Builder.setApplicationName( getAppName()).build();

    if( not isNull( getStartDate()))
    {
      var tz = jl.create( "java.util.TimeZone" ).getTimeZone( "Europe/Amsterdam" );
      var timeMin = jl.create( 'com.google.api.client.util.DateTime' ).init( getStartDate(), tz );
      return service.events()
        .list( getCalendarID())
        .setTimeMin( timeMin )
        .setSingleEvents( getSingleEvents())
        .execute();
    }

    return service.events()
      .list( getCalendarID())
      .setSingleEvents( getSingleEvents())
      .execute();
  }

  public function getInstances( instanceID )
  {
    var service = Calendar_Builder.setApplicationName( getAppName()).build();
    return service.events().instances( getCalendarID(), instanceID ).execute();
  }
}