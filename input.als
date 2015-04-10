sig Submission {}
sig Grade {}
sig Student {}
sig Course {
	roster: set _ Student,
	work: roster -> lone _ Submission,
	gradebook: work -> lone _ Grade,
}
pred Enroll (c, c' : Course, sNew : Student) {
	c'.roster = c.roster + sNew and no c'.work [sNew]
}