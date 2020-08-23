<cfset gCal = new calendar(
  AppName           = "my-first-calendar",
  KeyFile           = "{{PATH-TO-P12-KEY}}",
  ServiceAccountID  = "{{SERVICE-ACCOUNT-ADDRESS}}",
  CalendarID        = "{{CALENDAR-ADDRESS}}",
  startDate         = "#createDate( year( now()), 1, 1 )#"
) />

<cfdump var="#gCal.getEvents().getItems()#" />