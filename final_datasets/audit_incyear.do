global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
log using incyear.log, replace
foreach state in $statelist{
u `state'.dta, clear
di "This is `state'"
tab incyear if incyear < 1988
}
log close


This is IL
no observations
This is KY
no observations
This is LA //fixed
no observations
This is NC // not in raw
no observations
