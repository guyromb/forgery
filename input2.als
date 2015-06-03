sig Thing {}
sig State {
	r1: set _ Thing,
	r2: set _ Thing,
	r3: set _ Thing,
}
fact factA {
	all s:State, |
	s.r1 in s.r2
}
fact factB {
	all s:State, |
	s.r2 in s.r3
}
pred insert(s, s': State, t: Thing) {
  t in s'.r1                                      
}           
pred delete(s, s': State, t: Thing) {
   t not in s'.r2
}
