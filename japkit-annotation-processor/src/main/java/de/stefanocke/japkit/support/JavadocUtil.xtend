package de.stefanocke.japkit.support

import java.util.regex.Pattern

class JavadocUtil {
	static val paramPattern = Pattern.compile('''@param\s*(\S+)\s*([^@]*)''')  //1st group is parameter name, second is doc
	
	static val returnPattern = Pattern.compile('''@return\s*([^@]*)''')
	
	def static getParams(CharSequence javadoc){
		if(javadoc==null){
			emptyMap
		} else {
			val matcher = paramPattern.matcher(javadoc)
			val map = newHashMap
			matcher => [while(find){map.put(group(1), group(2)?.trim)}]
			map	
		}
	}
	
	def static getReturn(CharSequence javadoc){
		if(javadoc==null){
			return ''
		}
		val matcher = returnPattern.matcher(javadoc)
		if(matcher.find){
			matcher.group(1)?.trim
		} else {
			''
		}
		
	}
}