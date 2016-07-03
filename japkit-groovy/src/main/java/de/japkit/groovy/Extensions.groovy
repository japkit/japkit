package de.japkit.groovy

import de.japkit.el.ELMethodException;
import de.japkit.el.ELPropertyNotFoundException;
import de.japkit.el.ElExtensions;

class Extensions {

	def static methodMissing(Object base, String name, Object params){
		try{
			ElExtensions.invokeMethod(base instanceof Script ? null : base, name, params)
		} catch(ELMethodException e) {
			throw new MissingMethodException(name, base?.class, params)
		}
	}
	
	def static call(Object method, Object params){		
		ElExtensions.invoke(method, params)		
	}
	
}
