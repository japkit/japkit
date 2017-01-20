package de.japkit.rules

import java.util.regex.Pattern

class JavadocUtil {
	static val paramPattern = Pattern.compile('''@param\s*(\S+)\s*([^@]*)''')  //1st group is parameter name, second is doc
	
	static val returnPattern = Pattern.compile('''@return\s*([^@]*)''')
	
	//code within javadoc. 1st group is the name of the according AV. second group is the code
	//the patterns are sorted from the the most to the least specific ones. The first one that matches, will be applied.

	static val codePattern1 = Pattern.compile('''(?:@|<li>)japkit\.(\S+)\s*<pre>\s*\{@code\s*([\s\S]*?)\}\s*</pre>''')
	static val codePattern2 = Pattern.compile('''(?:@|<li>)japkit\.(\S+)\s*<pre>\s*<code>\s*([\s\S]*?)</code>\s*</pre>''')
	static val codePattern3 = Pattern.compile('''(?:@|<li>)japkit\.(\S+)\s*<code>\s*([\s\S]*?)</code>''')
	static val codePattern4 = Pattern.compile('''(?:@|<li>)japkit\.(\S+)\s*<pre>\s*([\s\S]*?)</pre>''')
	//single line code (everything on the same line till newline or end of string)
	static val codePattern5 = Pattern.compile('''(?:@|<li>)japkit\.(\S+)[\t\f ]*([\s\S]*?)(?:$|[\r\n])''')
	
	//empty ul-Tag. Remains after removing the li-Tags as above.
	static val emptyUL = Pattern.compile('''<ul>\s*</ul>''')
	
	static val leadingWhiteSpaceAfterLinebreak = Pattern.compile('''\n ''')
	
	def static getParams(CharSequence javadoc){
		getMapFromTwoGroups(javadoc, paramPattern)
	}
	
	def static getReturn(CharSequence javadoc){
		val pattern = returnPattern
		getFirstGroup(javadoc, pattern)
		
	}
	
	def static getFirstGroup(CharSequence javadoc, Pattern pattern) {
		if(javadoc==null){
			return ''
		}
		
		val matcher = pattern.matcher(javadoc)
		if(matcher.find){
			matcher.group(1)?.trim
		} else {
			''
		}
	}
	
	def static getCode(CharSequence javadoc){
		getMapFromTwoGroups(javadoc, codePattern1, codePattern2, codePattern3, codePattern4, codePattern5).mapValues[
			leadingWhiteSpaceAfterLinebreak.matcher(it).replaceAll('\n')
		]	
	}
	
	def static removeCode(CharSequence javadoc){
		remove(javadoc, codePattern1, codePattern2, codePattern3, codePattern4, codePattern5, emptyUL)	
	}
	
	
	def static getMapFromTwoGroups(CharSequence javadoc, Pattern ... patterns) {
		if(javadoc==null){
			emptyMap
		}
		else {
			val map = newHashMap
			patterns.forEach[
				val matcher = it.matcher(javadoc)		
				matcher => [while(find){
					if(!map.containsKey(group(1))) {
						//Only put into map, if there was no match for a more specific pattern
						map.put(group(1), group(2)?.trim)
					}
				}]				
			]
			map
		}
	}
	
	def static remove(CharSequence javadoc, Pattern ... patterns){
		if(javadoc==null){
			null
		} else {
			var result = javadoc
			for(p : patterns){
				result=p.matcher(result).replaceAll("")	
			}
			result.toString.trim
		}
	}
	
	def public static void main(String[] params){
		System.out.println(getCode("@japkit.code1 \n <code>testbar1</code> @japkit.code2 \n <pre><code>testbar2</code></pre>"))
	}
	
	
}