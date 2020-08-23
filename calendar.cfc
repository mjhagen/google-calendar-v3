component accessors=true {
  property boolean singleEvents;
  property date startDate;
  property string appName;
  property string calendarId;
  property string keyFile;
  property string serviceAccountId;
  property string timeZone;

  public component function init() {
    var root = getDirectoryFromPath( getCurrentTemplatePath() );

    variables.singleEvents = false;
    variables.timeZone = 'Europe/Amsterdam';

    structAppend( variables, arguments, true );

    var calendarScope = createObject( 'java', 'com.google.api.services.calendar.CalendarScopes' ).CALENDAR;
    var driveScope = createObject( 'java', 'com.google.api.services.drive.DriveScopes' ).DRIVE;
    var collections = createObject( 'java', 'java.util.Collections' ).singletonList( calendarScope & ' ' & driveScope );
    var credentialsBuilder = createObject( 'java', 'com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder' );
    var FSkeyFile = createObject( 'java', 'java.io.File' ).init( root & '/credentials/' & keyFile );
    var httpTransport = createObject( 'java', 'com.google.api.client.http.javanet.NetHttpTransport' ).init();
    var jsonFactory = createObject( 'java', 'com.google.api.client.json.gson.GsonFactory' ).init();

    var credentials = credentialsBuilder.setTransport( httpTransport )
      .setJsonFactory( jsonFactory )
      .setServiceAccountId( serviceAccountId )
      .setServiceAccountScopes( collections )
      .setServiceAccountPrivateKeyFromP12File( FSkeyFile )
      .build();

    variables.calendarService = createObject( 'java', 'com.google.api.services.calendar.Calendar$Builder' ).init( httpTransport, jsonFactory, credentials )
      .setApplicationName( variables.appName )
      .build();

    variables.driveService = createObject( 'java', 'com.google.api.services.drive.Drive$Builder' ).init( httpTransport, jsonFactory, credentials )
      .setApplicationName( variables.appName )
      .build();

    return this;
  }

  public function getEvents() {
    var result = variables.calendarService.events()
      .list( variables.calendarId )
      .setSingleEvents( variables.singleEvents )
      .setMaxResults( 500 );

    if ( !isNull( variables.startDate ) ) {
      var tz = createObject( 'java', 'java.util.TimeZone' ).getTimeZone( timeZone );
      var timeMin = createObject( 'java', 'com.google.api.client.util.DateTime' ).init( variables.startDate, tz );

      result.setTimeMin( timeMin );
    }

    return result.execute();
  }

  public function getEventById( string eventId ) {
    return variables.calendarService.events()
      .get( variables.calendarId, eventId )
      .execute();
  }

  public function getInstances( string instanceID ) {
    return variables.calendarService.events()
      .instances( variables.calendarId, instanceID )
      .execute();
  }

  public function getFile( string fileId ) {
    var outputStream = createObject( 'java', 'java.io.ByteArrayOutputStream' ).init();
    variables.driveService.files()
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
    var rawDatetime = left( ISO8601dateString, 10 ) & ' ' & mid( ISO8601dateString, 12, 8 );

    if ( !compareNoCase( mid( ISO8601dateString, 24, 1 ), 'z' ) ) {
      return dateConvert( 'utc2local', parseDateTime( rawDatetime ) );
    }

    return parseDateTime( rawDatetime );
  }
}