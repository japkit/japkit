package de.stefanocke.japkit.support

interface ICodeFragmentRule {
	def CharSequence code()
	
	def CharSequence surround(CharSequence surrounded)
}