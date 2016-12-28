package de.japkit.el.juel

import javax.el.ELContext
import java.util.Map
import javax.el.ELResolver
import javax.el.FunctionMapper

/**
 * ELContext that uses JapkitELResolver and DynamicFunctionMapper.
 */
class JapkitELContext extends ELContext {
	
	val ELResolver elResolver;
	val FunctionMapper fnMapper;
	
	new(Map<String, ? extends Object> vs){
		elResolver = new JapkitELResolver(vs);
		fnMapper = new DynamicFunctionMapper(vs);
	}
	
	override getELResolver() {
		elResolver
	}
	
	override getFunctionMapper() {
		fnMapper
	}
	
	override getVariableMapper() {
		null
	}
	
}