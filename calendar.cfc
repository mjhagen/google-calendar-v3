component accessors=true {
  property boolean singleEvents;
  property date startDate;
  property string appName;
  property string calendarId;
  property string keyFile;
  property string serviceAccountId;
  property string timeZone;

  public component function init( ) {
    var root = getDirectoryFromPath( getCurrentTemplatePath( ) );

    variables.singleEvents = false;
    variables.timeZone = "Europe/Amsterdam";
    variables.jl = new javaloader.javaloader( directoryList( root & "/java", true, "path", "*.jar" ) );

    structAppend( variables, arguments, true );

    var calendarScope = jl.create( "com.google.api.services.calendar.CalendarScopes" ).CALENDAR;
    var driveScope = jl.create( "com.google.api.services.drive.DriveScopes" ).DRIVE;
    var collections = jl.create( "java.util.Collections" ).singletonList( calendarScope & " " & driveScope );
    var credentialsBuilder = jl.create( "com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder" );
    var FSkeyFile = jl.create( "java.io.File" ).init( root & "/credentials/" & keyFile );
    var httpTransport = jl.create( "com.google.api.client.http.javanet.NetHttpTransport" ).init( );
    var jsonFactory = jl.create( "com.google.api.client.json.gson.GsonFactory" ).init( );

    var credentials = credentialsBuilder.setTransport( httpTransport )
      .setJsonFactory( jsonFactory )
      .setServiceAccountId( serviceAccountId )
      .setServiceAccountScopes( collections )
      .setServiceAccountPrivateKeyFromP12File( FSkeyFile )
      .build( );

    variables.calendarService = jl.create( "com.google.api.services.calendar.Calendar$Builder" )
      .init( httpTransport, jsonFactory, credentials )
      .setApplicationName( appName )
      .build( );

    variables.driveService = jl.create( "com.google.api.services.drive.Drive$Builder" )
      .init( httpTransport, jsonFactory, credentials )
      .setApplicationName( appName )
      .build( );

    return this;
  }

  public function getEvents( ) {
    var result = calendarService.events( )
      .list( calendarId )
      .setSingleEvents( singleEvents );

    if ( !isNull( startDate ) ) {
      var tz = jl.create( "java.util.TimeZone" ).getTimeZone( timeZone );
      var timeMin = jl.create( 'com.google.api.client.util.DateTime' ).init( startDate, tz );

      result.setTimeMin( timeMin );
    }

    return result.execute( );
  }

  public function getEventById( string eventId ) {
    return calendarService.events()
      .get( calendarId, eventId )
      .execute();
  }

  public function getInstances( instanceID ) {
    return calendarService.events( )
      .instances( calendarId, instanceID )
      .execute( );
  }

  public function getFile( fileId ) {
    outputStream = createObject( "java", "java.io.ByteArrayOutputStream" ).init( );
    driveService.files( )
      .get( fileId )
      .executeMediaAndDownloadTo( outputStream );
    return outputStream;
  }

  /**
   * Convert a date in ISO 8601 format to an ODBC datetime.
   *
   * @param ISO8601dateString      The ISO8601 date string. (Required)
   * @param targetZoneOffset      The timezone offset. (Required)
   * @return Returns a datetime.
   * @author David Satz (david_satz@hyperion.com)
   * @version 1, September 28, 2004
   */
  public function dateConvertISO8601( ISO8601dateString ) {
    var rawDatetime = left( ISO8601dateString, 10 ) & " " & mid( ISO8601dateString, 12, 8 );

    if ( !compareNoCase( mid( ISO8601dateString, 24, 1 ), 'z' ) ) {
      return dateConvert( "utc2local", parseDateTime( rawDatetime ) );
    }

    return parseDateTime( rawDatetime );
  }
}