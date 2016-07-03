package de.japkit.rules

interface ICodeFragmentRule {
	def CharSequence code()
	
	def CharSequence surround(CharSequence surrounded)
}