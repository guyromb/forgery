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
	// pre-condition
	s1 in c.roster and
	s2 in c.roster and
	// update
	c'.work = c.work + (s1 -> bNew) + (s2 -> bNew) and
	// frame condition
	c'.gradebook = c.gradebook 
}
pred AssignGrade (c, c' : Course, s : Student, b : Submission, g : Grade) {
	c'.gradebook = c.gradebook + (s -> b -> g) and
	c'.roster = c.roster 
}
fact SameGradeForPair {
	all c : Course, s1 : Student , s2 : Student, b : Submission, |
	b in (c.work [s1] & c.work [s2]) implies
	c.gradebook [s1][b] = c.gradebook [s2][b]
}