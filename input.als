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
pred Drop (c, c' : Course, s: Student) {
	s not in c'.roster 
}
pred SubmitForPair (c, c' : Course, s1 : Student, s2 : Student, bNew : Submission) {
	c'.roster = c.roster + bNew and no c'.work [bNew]
}