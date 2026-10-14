# Input: `todo --porcelain list` JSON. Output: org headings, one top-level
# heading per DAV list. todoman's porcelain output gives epoch seconds and
# can't distinguish an all-day date from local midnight, so midnight is
# rendered date-only (a reminder due at exactly 00:00 is rare).
def stamp:
  localtime
  | if .[3] == 0 and .[4] == 0 then strftime("%Y-%m-%d %a")
    else strftime("%Y-%m-%d %a %H:%M") end
  | "<\(.)>";
# iCalendar PRIORITY: 1-4 high, 5 medium, 6-9 low, 0/absent undefined.
def prio:
  if . == null or . == 0 then ""
  elif . <= 4 then "[#A] "
  elif . == 5 then "[#B] "
  else "[#C] " end;
# Apple Reminders usually sets DTSTART == DUE; only show SCHEDULED when the
# start date actually differs, so the agenda doesn't list the item twice.
def planning:
  [ (if .due then "DEADLINE: \(.due | stamp)" else empty end),
    (if .start and .start != .due then "SCHEDULED: \(.start | stamp)" else empty end) ]
  | join(" ");
group_by(.list)[]
| "* \(.[0].list)",
  (.[]
   | "** TODO \(.priority | prio)\(.summary)\(if .recurring then " :recurring:" else "" end)",
     (planning | select(. != "")),
     (.description | select(. != "") | split("\n")[]))
